#!/usr/bin/env python3
"""Separate repository/install/config actions. Python >=3.7, stdlib only.
No operation is applied unless --apply is explicitly supplied. No shell eval.
"""
import argparse
import configparser
import fcntl
import io
import json
import os
from pathlib import Path
import platform
import re
import stat
import subprocess
import sys
import tempfile
import urllib.request

ACTIONS = ('foreman-repo', 'openvox-repo', 'foreman-install', 'openvox-install',
           'foreman-config', 'openvox-config', 'agent-repo', 'agent-install', 'agent-config')
BASELINES = {'foreman': '5.0.1',
             'openvox-server': '9.2.0', 'openvox-agent': '9.4.0'}


def run(args, **kwargs):
    return subprocess.run(args, check=True, timeout=3600, **kwargs)


def atomic(path, content, mode):
    path = Path(path)
    if path.is_symlink():
        raise ValueError('Refusing symlink destination: ' + str(path))
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(dir=str(path.parent), prefix='.bootstrap-')
    try:
        os.fchmod(fd, mode)
        with os.fdopen(fd, 'wb') as handle:
            handle.write(content if isinstance(content, bytes) else content.encode())
        os.replace(temp, str(path))
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


class Plan:
    def __init__(self, cfg, action):
        self.cfg, self.action = cfg, action
        self.operations, self.errors = [], []

    def get(self, key, default=''):
        value = self.cfg
        for part in key.split('.'):
            if not isinstance(value, dict) or part not in value:
                return default
            value = value[part]
        return default if value is None else value

    def need(self, key, pattern=None):
        value = self.get(key)
        if not isinstance(value, str) or not value or (pattern and not re.fullmatch(pattern, value)):
            self.errors.append('Set valid ' + key)
            return '<unset:' + key + '>'
        return value

    def host(self, key):
        value = self.need(key, r'(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9-]+')
        if value.endswith(('.example.internal', '.example.com', '.invalid')):
            self.errors.append('Replace example hostname: ' + key)
        return value

    def file(self, path, content, mode=0o644):
        self.operations.append({'type': 'file', 'path': path, 'content': content, 'mode': mode})

    def command(self, *args):
        self.operations.append({'type': 'command', 'argv': list(args)})

    def platform(self):
        os_id, version = self.get('os.id'), self.get('os.version')
        allowed = {'ubuntu': ('22.04', '24.04', '26.04'), 'rocky': ('8', '9'), 'amzn': ('2', '2023')}
        if version not in allowed.get(os_id, ()):
            self.errors.append('Unsupported OS/version')
        if not self.action.startswith('agent-') and (os_id, version) != ('ubuntu', '24.04'):
            self.errors.append('Management server requires Ubuntu 24.04')
        arch = self.get('os.architecture')
        if arch not in ('x86_64', 'aarch64'):
            self.errors.append('Architecture must be x86_64 or aarch64')
        if not self.action.startswith('agent-') and arch != 'x86_64':
            self.errors.append('Management server requires x86_64')
        return os_id, version

    def repo(self, foreman=False):
        os_id, version = self.platform()
        product = 'foreman' if foreman else 'openvox'
        fingerprint = self.need('repository_keys.' + product, r'[A-F0-9]{40}')
        key_url = ('https://deb.theforeman.org/foreman.asc' if foreman else
                   'https://apt.voxpupuli.org/GPG-KEY-openvox.pub')
        series = '8' if (os_id, version) == ('amzn', '2') else '9'
        key_path = '/usr/share/keyrings/' + product + '-bootstrap.gpg'
        self.operations.append({'type': 'key', 'url': key_url, 'fingerprint': fingerprint,
                                'path': key_path, 'rpm': os_id != 'ubuntu'})
        if os_id == 'ubuntu':
            if foreman:
                content = ('deb [signed-by=' + key_path + '] https://deb.theforeman.org/ noble 5.0\n'
                           'deb [signed-by=' + key_path + '] https://deb.theforeman.org/ plugins 5.0\n')
            else:
                content = 'deb [signed-by=' + key_path + '] https://apt.voxpupuli.org ubuntu' + version + ' openvox' + series + '\n'
            self.file('/etc/apt/sources.list.d/' + product + '-bootstrap.list', content)
            self.command('apt-get', 'update')
        else:
            family = 'amazon' if os_id == 'amzn' else 'el'
            key_source = 'https://yum.voxpupuli.org/GPG-KEY-openvox.pub'
            # Download uses the RPM endpoint too; fingerprint remains explicit.
            self.operations[-1]['url'] = key_source
            self.file('/etc/yum.repos.d/openvox-bootstrap.repo',
                      '[openvox-bootstrap]\nname=OpenVox ' + series + '\nbaseurl=https://yum.voxpupuli.org/openvox' +
                      series + '/' + family + '/' + version + '/$basearch\nenabled=1\ngpgcheck=1\ngpgkey=file://' + key_path + '.asc\n')

    def install(self, packages):
        os_id, version = self.platform()
        pins = {}
        for package in packages:
            full = self.need('package_versions.' + package, r'[A-Za-z0-9.+:~_-]+')
            expected = '8.33.0' if package == 'openvox-agent' and (os_id, version) == ('amzn', '2') else BASELINES.get(package)
            if expected and not (full == expected or full.startswith(expected + '-')):
                self.errors.append('Pin ' + package + ' to upstream ' + expected + ' plus the distribution revision')
            pins[package] = full
        self.operations.append({'type': 'packages', 'os': os_id, 'version': version, 'pins': pins})

    def certificates(self):
        # Corporate PKI material is provisioned separately; never initialise a CA.
        for key in ('ca_cert', 'host_cert', 'host_key'):
            self.need('tls.' + key, r'/[A-Za-z0-9_./-]+')

    def installer(self, include_openvox):
        self.platform()
        self.host('host_fqdn')
        for package in ('foreman', 'foreman-installer', 'foreman-proxy', 'ruby-foreman-puppet', 'postgresql-16', 'openvox-agent', 'openvox-server'):
            self.need('package_versions.' + package, r'[A-Za-z0-9.+:~_-]+')
        self.host('foreman_fqdn')
        self.host('puppet_fqdn')
        self.certificates()
        groups = ['foreman'] + (['openvox'] if include_openvox else [])
        args = []
        for group in groups:
            items = self.get('installer.' + group + '_args', [])
            if not isinstance(items, list) or not items:
                self.errors.append('Provide reviewed installer.' + group + '_args')
                continue
            for item in items:
                if not isinstance(item, str) or not item.startswith('--') or '\n' in item:
                    self.errors.append('Invalid installer argument')
                    continue
                # Do not place passwords/tokens in public JSON or process arguments.
                if re.search(r'password|consumer-(?:key|secret)|initial-admin', item):
                    self.errors.append('Keep credentials in root-only installer answers, not argument lists')
                try:
                    values = dict(self.cfg)
                    values.update(self.get('tls', {}))
                    args.append(item.format_map(values))
                except (KeyError, ValueError, TypeError):
                    self.errors.append('Unresolved installer placeholder: ' + item.split('=')[0])
        if include_openvox:
            self.host('puppet_certname')
            required = ('--puppet-server=true', '--puppet-server-ca=false', '--puppet-client-package=openvox-agent',
                        '--puppet-server-package=openvox-server', '--puppet-server-foreman=true',
                        '--puppet-server-foreman-facts=true', '--puppet-server-reports=foreman')
        else:
            args += ['--no-enable-puppet', '--no-enable-foreman-proxy']
            required = ('--foreman-db-manage=true',)
        for value in required:
            if value not in args:
                self.errors.append('Required installer argument: ' + value)
        flags = [arg.split('=', 1)[0].replace('--no-enable-', '--enable-') for arg in args]
        if len(set(flags)) != len(flags):
            self.errors.append('Duplicate installer switches are not allowed')
        self.operations.append({'type': 'installer', 'argv': ['foreman-installer', '--scenario', 'foreman'] + args})

    def agent_config(self):
        self.platform()
        server = self.host('puppet_fqdn')
        ca_server = self.host('ca_fqdn')
        certname = self.host('certname')
        env = self.get('puppet_environment')
        deploy_env = self.get('deploy_env')
        if (env, deploy_env) not in (('development', 'dev'), ('production', 'prd')):
            self.errors.append('Environment must be development/dev or production/prd')
        self.certificates()
        facts = {'deploy_env': deploy_env}
        team = self.get('team')
        if team:
            if not isinstance(team, str) or not re.fullmatch(r'[a-z][a-z0-9_-]*', team):
                self.errors.append('Invalid team fact')
            facts['team'] = team
        settings = {'server': server, 'ca_server': ca_server, 'certname': certname,
                    'environment': env, 'localcacert': self.get('tls.ca_cert'),
                    'hostcert': self.get('tls.host_cert'), 'hostprivkey': self.get('tls.host_key')}
        settings.update({'runinterval': '30m', 'splay': 'true', 'splaylimit': '30m',
                         'usecacheonfailure': 'false', 'use_cached_catalog': 'false',
                         'report': 'true', 'show_diff': 'false', 'waitforcert': '0',
                         'http_connect_timeout': '30', 'http_read_timeout': '120'})
        self.operations.append({'type': 'puppetconf', 'settings': settings})
        self.file('/etc/puppetlabs/facter/facts.d/foreman_puppet.json', json.dumps(facts, indent=2) + '\n')
        # Deliberately no CSR/signing, first apply, service enable or service start.

    def build(self):
        if self.action == 'foreman-repo': self.repo(True)
        elif self.action in ('openvox-repo', 'agent-repo'): self.repo()
        elif self.action == 'foreman-install': self.install(['foreman', 'foreman-installer', 'foreman-proxy', 'ruby-foreman-puppet', 'postgresql-16'])
        elif self.action == 'openvox-install': self.install(['openvox-agent', 'openvox-server'])
        elif self.action == 'agent-install': self.install(['openvox-agent'])
        elif self.action == 'foreman-config': self.installer(False)
        elif self.action == 'openvox-config': self.installer(True)
        elif self.action == 'agent-config': self.agent_config()
        return self


def verify_target(cfg):
    release = {}
    for line in Path('/etc/os-release').read_text().splitlines():
        if '=' in line:
            key, value = line.split('=', 1)
            release[key] = value.strip('"')
    wanted = cfg['os']
    actual = release.get('VERSION_ID', '')
    if wanted['id'] == 'rocky': actual = actual.split('.')[0]
    if (release.get('ID'), actual, platform.machine()) != (wanted['id'], wanted['version'], wanted['architecture']):
        raise ValueError('Target OS/version/architecture does not match input')


def verify_tls(cfg):
    tls = cfg['tls']
    for name in ('ca_cert', 'host_cert', 'host_key'):
        if not Path(tls[name]).is_file(): raise ValueError('Missing TLS file: ' + name)
    key_stat = Path(tls['host_key']).stat()
    if key_stat.st_uid != 0 or stat.S_IMODE(key_stat.st_mode) & 0o007:
        raise ValueError('TLS private key must be root-owned and inaccessible to other users')
    cert_pub = run(['openssl', 'x509', '-in', tls['host_cert'], '-pubkey', '-noout'], stdout=subprocess.PIPE).stdout
    key_pub = run(['openssl', 'pkey', '-in', tls['host_key'], '-pubout'], stdout=subprocess.PIPE).stdout
    if cert_pub != key_pub: raise ValueError('Certificate/private key mismatch')
    run(['openssl', 'verify', '-CAfile', tls['ca_cert'], tls['host_cert']])
    name = cfg.get('certname', cfg.get('foreman_fqdn'))
    run(['openssl', 'x509', '-in', tls['host_cert'], '-noout', '-checkhost', name])


def apply(plan):
    if plan.errors: raise ValueError('; '.join(plan.errors))
    if os.geteuid() != 0: raise ValueError('--apply must run as root on the actual target')
    verify_target(plan.cfg)
    if plan.action.endswith('config'):
        verify_tls(plan.cfg)
        if not plan.action.startswith('agent-'):
            for package, expected in plan.cfg['package_versions'].items():
                actual = run(['dpkg-query', '-W', '-f=${Version}', package], stdout=subprocess.PIPE).stdout.decode().strip()
                if actual != expected:
                    raise ValueError('Install/verify pinned package before config: ' + package)
        if not plan.action.startswith('agent-'):
            import socket
            if socket.getfqdn() != plan.cfg['host_fqdn']:
                raise ValueError('Set the actual host FQDN and DNS before configuring services')
        if plan.action == 'openvox-config':
            if any(Path(p).exists() for p in ('/etc/puppetlabs/puppetserver/ca/ca_key.pem', '/etc/puppetlabs/puppet/ssl/ca/ca_key.pem')):
                raise ValueError('Existing Puppet CA found; external PKI conversion is not automatic')
            certname = plan.cfg['puppet_certname']
            ssl_dir = Path('/etc/puppetlabs/puppet/ssl')
            expected_cert = ssl_dir / 'certs' / (certname + '.pem')
            expected_key = ssl_dir / 'private_keys' / (certname + '.pem')
            for file in (expected_cert, expected_key, ssl_dir / 'certs/ca.pem', ssl_dir / 'crl.pem'):
                if not file.is_file():
                    raise ValueError('Provision corporate PKI material before server config: ' + str(file))
            run(['openssl', 'verify', '-CAfile', str(ssl_dir / 'certs/ca.pem'), str(expected_cert)])
            run(['openssl', 'x509', '-in', str(expected_cert), '-noout', '-checkhost', plan.cfg['puppet_fqdn']])
            cert_pub = run(['openssl', 'x509', '-in', str(expected_cert), '-pubkey', '-noout'], stdout=subprocess.PIPE).stdout
            key_pub = run(['openssl', 'pkey', '-in', str(expected_key), '-pubout'], stdout=subprocess.PIPE).stdout
            if cert_pub != key_pub:
                raise ValueError('Puppet server certificate/key mismatch')
    lock = open('/run/lock/foreman-openvox-bootstrap.lock', 'a')
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    for operation in plan.operations:
        kind = operation['type']
        if kind == 'file': atomic(operation['path'], operation['content'], operation['mode'])
        elif kind == 'command': run(operation['argv'])
        elif kind == 'key':
            with tempfile.TemporaryDirectory() as root:
                data = urllib.request.urlopen(operation['url'], timeout=30).read(1024 * 1024)
                source = Path(root) / 'key.asc'
                source.write_bytes(data)
                env = dict(os.environ, GNUPGHOME=root)
                output = run(['gpg', '--batch', '--show-keys', '--with-colons', str(source)], env=env, stdout=subprocess.PIPE).stdout.decode()
                # Trust only the primary key fingerprint, not a matching subkey.
                primary = output.split('pub:', 1)[-1].split('sub:', 1)[0]
                fingerprints = [line.split(':')[9] for line in primary.splitlines() if line.startswith('fpr:')]
                if fingerprints != [operation['fingerprint']]: raise ValueError('Repository key fingerprint mismatch')
                if operation['rpm']:
                    atomic(operation['path'] + '.asc', data, 0o644)
                    run(['rpm', '--import', operation['path'] + '.asc'])
                else:
                    keyring = Path(root) / 'key.gpg'
                    run(['gpg', '--batch', '--dearmor', '--output', str(keyring), str(source)], env=env)
                    atomic(operation['path'], keyring.read_bytes(), 0o644)
        elif kind == 'packages':
            pins = operation['pins']
            # Installing is not an implicit migration from proprietary/legacy Puppet.
            legacy = ('puppet-agent', 'puppetserver', 'puppet-enterprise')
            for name in legacy:
                query = (['dpkg-query', '-W', '-f=${db:Status-Status}', name] if operation['os'] == 'ubuntu'
                         else ['rpm', '-q', name])
                result = subprocess.run(query, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=30)
                if result.returncode == 0 and (operation['os'] != 'ubuntu' or result.stdout.decode().strip() == 'installed'):
                    raise ValueError('Existing legacy package requires an explicit migration: ' + name)
            if operation['os'] == 'ubuntu':
                # Keep package postinsts from starting unconfigured services.
                policy = Path('/usr/sbin/policy-rc.d')
                owned = not policy.exists() and not policy.is_symlink()
                if owned: atomic(str(policy), '#!/bin/sh\nexit 101\n', 0o755)
                try:
                    run(['apt-get', 'update'])
                    run(['apt-get', 'install', '-y', '--no-remove'] + [p + '=' + v for p, v in pins.items()], env=dict(os.environ, DEBIAN_FRONTEND='noninteractive'))
                finally:
                    if owned: policy.unlink()
            else:
                manager = 'yum' if operation['os'] == 'amzn' and operation['version'] == '2' else 'dnf'
                run([manager, 'install', '-y'] + [p + '-' + v for p, v in pins.items()])
            # Assert that package managers did not silently choose another version.
            for package, expected in pins.items():
                query = ['dpkg-query', '-W', '-f=${Version}', package] if operation['os'] == 'ubuntu' else ['rpm', '-q', '--qf', '%{VERSION}-%{RELEASE}', package]
                actual = run(query, stdout=subprocess.PIPE).stdout.decode().strip()
                if actual != expected: raise ValueError('Installed version differs from pin: ' + package)
        elif kind == 'puppetconf':
            path = Path('/etc/puppetlabs/puppet/puppet.conf')
            parser = configparser.ConfigParser(interpolation=None)
            if path.exists(): parser.read(str(path))
            # A section-specific setting overrides [main]; refuse ambiguous identity.
            for section in parser.sections():
                if section != 'main' and any(k in parser[section] for k in operation['settings']):
                    raise ValueError('Resolve conflicting puppet.conf section: ' + section)
            if not parser.has_section('main'): parser.add_section('main')
            for key, value in operation['settings'].items(): parser.set('main', key, value)
            output = io.StringIO(); parser.write(output)
            atomic(str(path), output.getvalue(), 0o644)
        elif kind == 'installer':
            # Validate all switches against the installed installer before mutation.
            help_text = run(['foreman-installer', '--full-help'], stdout=subprocess.PIPE).stdout.decode()
            help_text = help_text.replace('--[no-]enable-', '--enable-').replace('--[no-]', '--')
            for arg in operation['argv'][3:]:
                flag = arg.split('=', 1)[0].replace('--no-enable-', '--enable-')
                if flag not in help_text: raise ValueError('Unsupported installer option: ' + flag)
            logdir = Path('/var/log/foreman-openvox-bootstrap')
            logdir.mkdir(mode=0o700, exist_ok=True); logdir.chmod(0o700)
            # Installer may print initial credentials; never echo its output publicly.
            log = logdir / (plan.action + '.log')
            with os.fdopen(os.open(str(log), os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), 'w') as handle:
                os.chmod(str(log), 0o600)
                run(operation['argv'], stdout=handle, stderr=subprocess.STDOUT)
            print('Installer output stored in root-only ' + str(log))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=ACTIONS)
    parser.add_argument('--config', required=True, help='JSON input; do not put credentials in it')
    parser.add_argument('--apply', action='store_true', help='Apply changes locally; default is read-only plan')
    args = parser.parse_args()
    try:
        cfg = json.loads(Path(args.config).read_text())
        plan = Plan(cfg, args.action).build()
        if args.apply: apply(plan)
        else: print(json.dumps({'action': args.action, 'mode': 'plan', 'unresolved': plan.errors, 'operations': plan.operations}, indent=2))
    except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError) as error:
        print('ERROR: ' + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
