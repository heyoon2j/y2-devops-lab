#!/usr/bin/env python3
"""Apply native repository and service configuration templates. Python >=3.7.
Server answers configuration additionally requires PyYAML.
No operation is applied unless --apply is explicitly supplied. No shell eval.
"""
import argparse
import configparser
import copy
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
CONFIG_ROOT = Path(__file__).resolve().parents[1] / 'config'
BASELINES = json.loads((CONFIG_ROOT / 'versions.json').read_text())
ANSWERS_PATH = Path('/etc/foreman-installer/scenarios.d/foreman-answers.yaml')
SCENARIO_PATH = Path('/etc/foreman-installer/scenarios.d/foreman.yaml')


def read_yaml(content):
    # Only server configuration needs PyYAML. Agent bootstrap remains stdlib-only.
    try:
        import yaml
    except ImportError as error:
        raise ValueError('Install python3-yaml/PyYAML for server answers configuration') from error

    class UniqueKeys(yaml.SafeLoader):
        pass

    def mapping(loader, node, deep=False):
        result = {}
        for key_node, value_node in node.value:
            key = loader.construct_object(key_node, deep=deep)
            if key in result:
                raise ValueError('Duplicate YAML key: ' + str(key))
            result[key] = loader.construct_object(value_node, deep=deep)
        return result
    UniqueKeys.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, mapping)
    try:
        result = yaml.load(content, Loader=UniqueKeys)
    except yaml.YAMLError as error:
        raise ValueError('Invalid installer answers YAML') from error
    if not isinstance(result, dict):
        raise ValueError('Installer answers must be a YAML mapping')
    return result


def merge_answers(existing, overlay):
    result = copy.deepcopy(existing)
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge_answers(result[key], value)
        else:
            result[key] = copy.deepcopy(value)
    return result


def merge_agent_content(existing, content):
    candidate = configparser.ConfigParser(interpolation=None)
    candidate.read_string(content)
    if candidate.sections() != ['main'] or candidate.defaults():
        raise ValueError('Agent template must contain only a [main] section')
    parser = configparser.ConfigParser(interpolation=None)
    if existing:
        parser.read_string(existing)
    for section in parser.sections():
        if section != 'main' and any(key in parser[section] for key in candidate['main']):
            raise ValueError('Resolve conflicting puppet.conf section: ' + section)
    if not parser.has_section('main'):
        parser.add_section('main')
    for key, value in candidate['main'].items():
        parser.set('main', key, value)
    output = io.StringIO()
    parser.write(output)
    return output.getvalue()



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

    def render(self, name, values):
        source = (CONFIG_ROOT / name).read_text()
        def replace(match):
            key = match.group(1)
            if key not in values:
                raise ValueError('Unknown template variable: ' + key + ' in ' + name)
            value = values[key]
            return '<unset:' + key + '>' if value is None else str(value)
        result = re.sub(r'\{\{([a-z][a-z0-9_]*)\}\}', replace, source)
        if '{{' in result or '}}' in result:
            raise ValueError('Unresolved template expression in ' + name)
        return result

    def package_list(self, name):
        packages = json.loads((CONFIG_ROOT / 'packages' / name).read_text())
        if not isinstance(packages, list) or not packages or any(not isinstance(p, str) or not re.fullmatch(r'[a-z0-9][a-z0-9+.-]*', p) for p in packages):
            raise ValueError('Invalid package list: ' + name)
        return packages

    def repo(self, foreman=False):
        os_id, version = self.platform()
        product = 'foreman' if foreman else 'openvox'
        fingerprint = self.need('repository_keys.' + product, r'[A-F0-9]{40}')
        key_url = ('https://deb.theforeman.org/foreman.asc' if foreman else
                   'https://apt.voxpupuli.org/GPG-KEY-openvox.pub')
        series = '8' if (os_id, version) == ('amzn', '2') else '9'
        key_path = '/usr/share/keyrings/' + product + '-bootstrap.gpg'
        values = {'key_path': key_path, 'os_version': version, 'series': series,
                  'rpm_family': 'amazon' if os_id == 'amzn' else 'el'}
        self.operations.append({'type': 'key', 'url': key_url, 'fingerprint': fingerprint,
                                'path': key_path, 'rpm': os_id != 'ubuntu'})
        if os_id == 'ubuntu':
            name = 'repos/apt/' + product + '.sources.tmpl'
            self.file('/etc/apt/sources.list.d/' + product + '-bootstrap.sources', self.render(name, values))
            self.operations[-1]['source'] = 'config/' + name
            self.command('apt-get', 'update')
        else:
            self.operations[-1]['url'] = 'https://yum.voxpupuli.org/GPG-KEY-openvox.pub'
            self.file('/etc/yum.repos.d/openvox-bootstrap.repo', self.render('repos/yum/openvox.repo.tmpl', values))
            self.operations[-1]['source'] = 'config/repos/yum/openvox.repo.tmpl'

    def install(self, packages):
        os_id, version = self.platform()
        pins = {}
        for package in packages:
            full = self.need('package_versions.' + package, r'[A-Za-z0-9.+:~_-]+')
            expected = BASELINES['amazon2-agent'] if package == 'openvox-agent' and (os_id, version) == ('amzn', '2') else BASELINES.get(package)
            if expected and not (full == expected or full.startswith(expected + '-')):
                self.errors.append('Pin ' + package + ' to upstream ' + expected + ' plus the distribution revision')
            pins[package] = full
        self.operations.append({'type': 'packages', 'os': os_id, 'version': version, 'pins': pins})

    def certificates(self):
        # Corporate PKI material is provisioned separately; never initialise a CA.
        for key in ('ca_cert', 'host_cert', 'host_key'):
            self.need('tls.' + key, r'/[A-Za-z0-9_./-]+')

    def installer(self):
        # Both public entrypoints converge the same complete installer stack.
        # Splitting the source files must not disable the other component.
        self.platform()
        values = {}
        for key in ('host_fqdn', 'foreman_fqdn', 'puppet_fqdn', 'puppet_certname'):
            values[key] = self.host(key)
        for package in self.package_list('foreman.json') + self.package_list('openvox-server.json'):
            self.need('package_versions.' + package, r'[A-Za-z0-9.+:~_-]+')
        self.certificates()
        values.update(self.get('tls', {}))
        if 'installer' in self.cfg:
            self.errors.append('Remove legacy installer argument lists; edit config/server YAML templates')
        overlay = {}
        for name in ('server/foreman.answers.yaml.tmpl', 'server/openvox.answers.yaml.tmpl'):
            fragment = read_yaml(self.render(name, values))
            if set(fragment) & set(overlay):
                raise ValueError('Server templates must not own the same top-level module')
            overlay.update(fragment)
        def required(module, key, value):
            settings = overlay.get(module, {})
            if not isinstance(settings, dict) or settings.get(key) != value:
                self.errors.append('Required answers setting: ' + module + '.' + key)
        for key, value in {'server': True, 'server_ca': False, 'manage_packages': False,
                           'client_package': 'openvox-agent', 'server_package': 'openvox-server',
                           'server_foreman': True, 'server_foreman_facts': True,
                           'server_reports': ['foreman']}.items():
            required('puppet', key, value)
        required('foreman', 'db_manage', True)
        required('foreman_proxy', 'puppetca', False)
        # The repository contains only public configuration, never credentials.
        for module, settings in overlay.items():
            if isinstance(settings, dict) and any(re.search(r'password|oauth_consumer_(key|secret)', key) for key in settings):
                self.errors.append('Keep credentials in existing root-only installer answers')
        self.operations.append({'type': 'installer', 'argv': ['foreman-installer', '--scenario', 'foreman'],
                                'path': str(ANSWERS_PATH), 'answers_overlay': overlay,
                                'sources': ['config/server/foreman.answers.yaml.tmpl',
                                            'config/server/openvox.answers.yaml.tmpl']})

    def agent_config(self):
        self.platform()
        server = self.host('puppet_fqdn')
        ca_server = self.host('ca_fqdn')
        certname = self.host('certname')
        env = self.get('puppet_environment')
        if env not in ('development', 'production'):
            self.errors.append('Environment must be development or production')
        for key in ('deploy_env', 'team', 'dr_site'):
            if key in self.cfg:
                self.errors.append('Move ' + key + ' to Foreman host parameters; Agent config does not write policy Facts')
        self.certificates()
        values = {'puppet_fqdn': server, 'ca_fqdn': ca_server, 'certname': certname,
                  'puppet_environment': env}
        values.update(self.get('tls', {}))
        content = self.render('agent/puppet.conf.tmpl', values)
        candidate = configparser.ConfigParser(interpolation=None)
        candidate.read_string(content)
        if candidate.sections() != ['main'] or candidate.defaults():
            raise ValueError('Agent template must contain only [main]')
        settings = dict(candidate['main'])
        for key, value in {'server': server, 'certname': certname, 'environment': env,
                           'waitforcert': '0', 'usecacheonfailure': 'false'}.items():
            if settings.get(key) != value:
                self.errors.append('Required Agent setting: ' + key)
        self.operations.append({'type': 'puppetconf', 'content': content, 'settings': settings,
                                'source': 'config/agent/puppet.conf.tmpl'})
        # Deliberately no CSR/signing, first apply, service enable or service start.

    def build(self):
        if self.action == 'foreman-repo': self.repo(True)
        elif self.action in ('openvox-repo', 'agent-repo'): self.repo()
        elif self.action == 'foreman-install': self.install(self.package_list('foreman.json'))
        elif self.action == 'openvox-install': self.install(self.package_list('openvox-server.json'))
        elif self.action == 'agent-install': self.install(self.package_list('openvox-agent.json'))
        elif self.action == 'foreman-config': self.installer()
        elif self.action == 'openvox-config': self.installer()
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
        if plan.action in ('openvox-config', 'foreman-config'):
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
    for operation in plan.operations:
        if operation['type'] == 'file' and operation['path'].endswith('-bootstrap.sources'):
            legacy = Path(operation['path']).with_suffix('.list')
            if legacy.exists() or legacy.is_symlink():
                raise ValueError('Review and migrate legacy repository file before applying: ' + str(legacy))
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
            existing = path.read_text() if path.exists() else ''
            atomic(str(path), merge_agent_content(existing, operation['content']), 0o644)
        elif kind == 'installer':
            # Validate all switches against the installed installer before mutation.
            help_text = run(['foreman-installer', '--full-help'], stdout=subprocess.PIPE).stdout.decode()
            help_text = help_text.replace('--[no-]enable-', '--enable-').replace('--[no-]', '--')
            for module, settings in operation['answers_overlay'].items():
                prefix = module.replace('::', '-').replace('_', '-')
                flags = (['--' + prefix + '-' + key.replace('_', '-') for key in settings]
                         if isinstance(settings, dict) else ['--enable-' + prefix])
                for flag in flags:
                    if not re.search(re.escape(flag) + r'(?=[\s=|,]|$)', help_text):
                        raise ValueError('Unsupported installer option: ' + flag)
            # The selected scenario must read the answers file we are managing.
            scenario = read_yaml(SCENARIO_PATH.read_text())
            actual_path = scenario.get(':answer_file', scenario.get('answer_file'))
            if actual_path != operation['path']:
                raise ValueError('Installed Foreman scenario uses a different answers path')
            logdir = Path('/var/log/foreman-openvox-bootstrap')
            logdir.mkdir(mode=0o700, exist_ok=True); logdir.chmod(0o700)
            # Installer may print initial credentials; never echo its output publicly.
            answers = Path(operation['path'])
            if answers.is_symlink():
                raise ValueError('Refusing symlink answers destination')
            existing = {}
            if answers.exists():
                info = answers.stat()
                if info.st_uid != 0 or stat.S_IMODE(info.st_mode) & 0o077:
                    raise ValueError('Existing answers must be root-owned and mode 0600')
                existing = read_yaml(answers.read_text())
                # Preserve the pre-run file, including generated credentials.
                from datetime import datetime
                stamp = datetime.utcnow().strftime('%Y%m%dT%H%M%S%f')
                atomic(str(logdir / ('answers-before-' + stamp + '.yaml')), answers.read_bytes(), 0o600)
            import yaml
            merged = merge_answers(existing, operation['answers_overlay'])
            atomic(str(answers), yaml.safe_dump(merged, sort_keys=False), 0o600)
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
