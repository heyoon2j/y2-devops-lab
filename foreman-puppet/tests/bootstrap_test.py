"""Plan/guard tests. Never installs software, downloads keys, or touches /etc."""
import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT / 'bootstrap'
spec = importlib.util.spec_from_file_location('bootstrap', ROOT / 'lib/bootstrap.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def fixture(agent=False):
    cfg = json.loads((ROOT / 'examples' / ('agent.json' if agent else 'server.json')).read_text())
    cfg.update({'host_fqdn': 'mgmt.dev.internal', 'foreman_fqdn': 'foreman.dev.internal',
                'puppet_fqdn': 'puppet.dev.internal', 'puppet_certname': 'mgmt.dev.internal',
                'ca_fqdn': 'ca.dev.internal', 'certname': 'node.dev.internal'})
    cfg['tls'] = {'ca_cert': '/opt/pki/ca.pem', 'host_cert': '/opt/pki/host.pem', 'host_key': '/opt/pki/host.key'}
    cfg['repository_keys']['foreman'] = 'A' * 40
    for name in cfg['package_versions']:
        cfg['package_versions'][name] = m.BASELINES.get(name, '1.0.0') + '-1noble'
    return cfg


class BootstrapTest(unittest.TestCase):
    def test_every_entrypoint_is_plan_only_without_apply(self):
        for action in m.ACTIONS:
            cfg = fixture(action.startswith('agent-'))
            with patch.object(m, 'run', side_effect=AssertionError('Plan executed a command')):
                plan = m.Plan(cfg, action).build()
            self.assertFalse(plan.errors, (action, plan.errors))
            self.assertTrue(plan.operations)

    def test_platform_repositories_and_agent_series(self):
        platforms = [('ubuntu', v) for v in ('22.04', '24.04', '26.04')]
        platforms += [('rocky', v) for v in ('8', '9')]
        platforms += [('amzn', v) for v in ('2', '2023')]
        for os_id, version in platforms:
            for arch in ('x86_64', 'aarch64'):
                cfg = fixture(True)
                cfg['os'] = {'id': os_id, 'version': version, 'architecture': arch}
                series = '8' if (os_id, version) == ('amzn', '2') else '9'
                cfg['package_versions']['openvox-agent'] = ('8.33.0' if series == '8' else '9.4.0') + '-1'
                repo = m.Plan(cfg, 'agent-repo').build()
                self.assertFalse(repo.errors)
                content = next(o['content'] for o in repo.operations if o['type'] == 'file')
                self.assertIn('openvox' + series, content)
                if os_id == 'amzn': self.assertIn('/amazon/' + version + '/$basearch', content)
                if os_id == 'rocky': self.assertIn('/el/' + version + '/$basearch', content)
                install = m.Plan(cfg, 'agent-install').build()
                self.assertFalse(install.errors)
                cfg['package_versions']['openvox-agent'] = '9.4.0-1' if series == '8' else '8.33.0-1'
                self.assertTrue(m.Plan(cfg, 'agent-install').build().errors)

    def test_missing_values_fail_before_mutation(self):
        cfg = json.loads((ROOT / 'examples/server.json').read_text())
        plan = m.Plan(cfg, 'foreman-config').build()
        with patch.object(m, 'run', side_effect=AssertionError('must not execute')):
            with self.assertRaises(ValueError): m.apply(plan)

    def test_no_ca_creation_and_foreman_options_preserved(self):
        cfg = fixture()
        plan = m.Plan(cfg, 'openvox-config').build()
        self.assertFalse(plan.errors)
        args = plan.operations[0]['argv']
        self.assertIn('--puppet-server-ca=false', args)
        self.assertIn('--foreman-db-manage=true', args)
        self.assertIn('--puppet-manage-packages=false', args)
        self.assertNotIn('--no-enable-foreman', args)
        self.assertNotIn('--no-enable-puppet', args)
        self.assertIn('--foreman-proxy-register-in-foreman=false', args)
        cfg['installer']['openvox_args'].append('--puppet-server-ca=true')
        self.assertTrue(m.Plan(cfg, 'openvox-config').build().errors)

    def test_agent_identity_facts_and_no_automatic_execution(self):
        cfg = fixture(True)
        plan = m.Plan(cfg, 'agent-config').build()
        self.assertFalse(plan.errors)
        self.assertFalse(any(o['type'] == 'command' for o in plan.operations))
        settings = plan.operations[0]['settings']
        self.assertEqual(settings['certname'], 'node.dev.internal')
        self.assertEqual(settings['waitforcert'], '0')
        self.assertEqual(settings['usecacheonfailure'], 'false')
        self.assertNotIn('pluginsync', settings)  # Removed in OpenVox 9.
        facts = json.loads(plan.operations[1]['content'])
        self.assertEqual(facts, {'deploy_env': 'dev', 'team': 'devops'})
        self.assertNotIn('role', facts)
        cfg['deploy_env'] = 'prd'
        self.assertTrue(m.Plan(cfg, 'agent-config').build().errors)

    def test_bad_os_key_and_hostname_are_rejected(self):
        cfg = fixture()
        cfg['os']['id'] = 'amzn'
        self.assertTrue(m.Plan(cfg, 'foreman-repo').build().errors)
        cfg = fixture(True)
        cfg['repository_keys']['openvox'] = 'not-a-fingerprint'
        self.assertTrue(m.Plan(cfg, 'agent-repo').build().errors)
        cfg['certname'] = 'node;touch /tmp/bad'
        self.assertTrue(m.Plan(cfg, 'agent-config').build().errors)

    def test_wrappers_help_and_dry_run(self):
        for file in sorted(list((ROOT / 'server').glob('*.sh')) + list((ROOT / 'agent').glob('*.sh'))):
            subprocess.run(['bash', '-n', str(file)], check=True)
            subprocess.run(['bash', str(file), '--help'], check=True, stdout=subprocess.DEVNULL)
            sample = ROOT / 'examples' / ('agent.json' if file.parent.name == 'agent' else 'server.json')
            result = subprocess.run(['bash', str(file), '--config', str(sample)], check=True, stdout=subprocess.PIPE)
            plan = json.loads(result.stdout)
            self.assertEqual(plan['mode'], 'plan')
            if not file.name.endswith('repo.sh') or file.name == 'foreman-repo.sh':
                self.assertTrue(plan['unresolved'])


if __name__ == '__main__':
    unittest.main()
