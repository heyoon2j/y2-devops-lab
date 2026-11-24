# Offline bootstrap tests. No packages, keys, /etc, services or CA initialization.
require 'json'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'
require_relative '../bootstrap/lib/configure'

ROOT = File.expand_path('../bootstrap', __dir__)
def check(value, message)
  raise message unless value
end

def fixture(agent: false)
  cfg = JSON.parse(File.read(File.join(ROOT, 'examples', agent ? 'agent.json' : 'server.json')))
  cfg.merge!('host_fqdn' => 'mgmt.dev.internal', 'puppet_certname' => 'mgmt.dev.internal',
             'foreman_fqdn' => 'foreman.dev.internal', 'puppet_fqdn' => 'puppet.dev.internal',
             'ca_fqdn' => 'ca.dev.internal', 'certname' => 'node.dev.internal')
  if agent
    cfg['puppet_ca_fingerprint'] = (['AB'] * 32).join(':')
  else
    cfg['tls'] = { 'ca_cert' => '/opt/pki/ca.pem', 'host_cert' => '/opt/pki/server.pem', 'host_key' => '/opt/pki/server.key' }
    cfg['repository_keys']['foreman'] = 'A' * 40
  end
  baseline = JSON.parse(File.read(File.join(ROOT, 'config/versions.json')))
  cfg['package_versions'].keys.each { |name| cfg['package_versions'][name] = baseline.fetch(name, '16.0') + '-1' }
  cfg
end

def shell_plan(action, cfg)
  Dir.mktmpdir do |dir|
    input = File.join(dir, 'input.json'); File.write(input, JSON.generate(cfg))
    out, err, status = Open3.capture3({ 'FOREMAN_BOOTSTRAP_RUBY' => RbConfig.ruby }, 'bash', File.join(ROOT, 'lib/bootstrap.sh'), action, '--config', input)
    check(status.success?, "#{action} failed: #{err}")
    JSON.parse(out)
  end
end

# Every public wrapper remains read-only unless --apply is supplied.
wrappers = Dir.glob(File.join(ROOT, '{server,agent}', '*.sh')).sort
check(wrappers.size == 11, 'Missing stage wrapper')
wrappers.each do |path|
  check(system('bash', '-n', path), "Bash syntax: #{path}")
  check(system('bash', path, '--help', out: File::NULL), "Help failed: #{path}")
end
%w[foreman-repo openvox-repo foreman-install openvox-install foreman-config openvox-config ca-init agent-repo agent-install agent-config].each do |action|
  plan = shell_plan(action, fixture(agent: action.start_with?('agent-')))
  check(plan['mode'] == 'plan' && plan['unresolved'].empty?, "Invalid plan #{action}: #{plan['unresolved']}")
end

# Invalid apply input fails before networking, package commands or target file writes.
Dir.mktmpdir do |dir|
  input = File.join(dir, 'bad.json')
  cfg = fixture(agent: true); cfg['repository_keys']['openvox'] = 'bad'
  File.write(input, JSON.generate(cfg))
  _out, err, status = Open3.capture3('bash', File.join(ROOT, 'agent/repo.sh'), '--config', input, '--apply')
  check(!status.success? && err.include?('primary fingerprint'), 'Invalid apply was not rejected before target mutation')
end

# Both CPU architectures for all seven target OS versions; preserve literal $basearch.
platforms = { 'ubuntu' => %w[22.04 24.04 26.04], 'rocky' => %w[8 9], 'amzn' => %w[2 2023] }
platforms.each do |os, versions|
  versions.product(%w[x86_64 aarch64]).each do |version, arch|
    cfg = fixture(agent: true); cfg['os'] = { 'id' => os, 'version' => version, 'architecture' => arch }
    expected = os == 'amzn' && version == '2' ? '8.33.0' : '9.4.0'
    cfg['package_versions']['openvox-agent'] = expected + '-1'
    repo = shell_plan('agent-repo', cfg)
    check(repo['unresolved'].empty?, "Repository errors: #{os}/#{version}/#{arch}")
    content = repo['operations'].find { |op| op['type'] == 'file' }['content']
    check(content.include?('openvox' + expected[0]), 'Wrong series')
    check(content.include?('/$basearch'), 'Lost RPM variable') unless os == 'ubuntu'
    check(shell_plan('agent-install', cfg)['unresolved'].empty?, 'Valid install pin rejected')
    cfg['package_versions']['openvox-agent'] = expected.start_with?('8') ? '9.4.0-1' : '8.33.0-1'
    check(!shell_plan('agent-install', cfg)['unresolved'].empty?, 'Wrong series accepted')
  end
end

agent = Bootstrap::Plan.new(fixture(agent: true), 'agent-config').build
check(agent.errors.empty?, 'Valid Agent rejected')
check(agent.operations.map { |op| op[:type] } == %w[puppetconf bootstrap_instructions], 'Agent must not enroll/start or write policy Facts')
check(agent.operations.last[:automatic_execution] == false, 'Enrollment must be explicit')
check(!agent.operations.first[:content].include?('hostprivkey'), 'External PKI path retained')
%w[deploy_env team dr_site tls].each do |key|
  check(!Bootstrap::Plan.new(fixture(agent: true).merge(key => nil), 'agent-config').build.errors.empty?, "Legacy #{key} accepted")
end
check(!Bootstrap::Plan.new(fixture(agent: true).merge('puppet_ca_fingerprint' => nil), 'agent-config').build.errors.empty?, 'Missing CA anchor accepted')
check(!Bootstrap::Plan.new(fixture(agent: true).merge('puppet_environment' => 'sandbox'), 'agent-config').build.errors.empty?, 'Sandbox must remain TODO')

server = Bootstrap::Plan.new(fixture, 'openvox-config').build
check(server.errors.empty?, server.errors.join('; '))
overlay = server.operations.first[:answers_overlay]
check(overlay['puppet']['server_ca'] == true && overlay['puppet']['autosign'] == false, 'CA/autosign policy')
check(overlay['foreman_proxy']['puppetca'] == true, 'CA Proxy disabled')
check(overlay['foreman_proxy']['puppet_ssl_cert'].include?('mgmt.dev.internal'), 'Proxy must use internal identity for Puppet API')
check(overlay['puppet']['server_foreman_ssl_ca'] == '/opt/pki/ca.pem', 'Internal service CA trust lost')
# Public UI/API uses ACM at the NLB. Certificate-authenticated service calls
# must bypass that listener or the original client certificate identity is lost.
check(overlay['foreman']['ssl'] == true && overlay['foreman']['server_ssl_port'] == 443, 'NLB backend must remain HTTPS')
check(overlay['foreman']['server_ssl_verify_client'] == 'optional', 'PAT/UI path must allow NLB without client cert')
check(overlay['foreman']['foreman_url'] == 'https://foreman.dev.internal', 'Public Foreman URL lost')
check(overlay['foreman']['serveraliases'].include?('mgmt.dev.internal'), 'Internal vhost alias missing')
check(overlay['puppet']['server_foreman_url'] == 'https://mgmt.dev.internal', 'ENC/Facts/Reports must bypass ACM listener')
check(overlay['foreman_proxy']['foreman_base_url'] == 'https://mgmt.dev.internal', 'Proxy must bypass ACM listener')
Dir.mktmpdir do |dir|
  FileUtils.cp_r(File.join(ROOT, 'config'), dir)
  config_root = File.join(dir, 'config')
  template = File.join(config_root, 'server/openvox.answers.yaml.tmpl')
  File.write(template, File.read(template).gsub('https://{{host_fqdn}}', 'https://{{foreman_fqdn}}'))
  check(!Bootstrap::Plan.new(fixture, 'openvox-config', config_root: config_root).build.errors.empty?, 'Service mTLS accidentally routed through terminating NLB')
end
check(Bootstrap::Plan.new(fixture, 'foreman-config').build.operations == server.operations, 'Config aliases diverged')
check(!Bootstrap::Plan.new(fixture.merge('ca_mode' => 'external'), 'openvox-config').build.errors.empty?, 'Implicit PKI migration accepted')
init = Bootstrap::Plan.new(fixture, 'ca-init').build
check(init.errors.empty? && init.operations.first[:argv].include?('setup'), 'CA init plan missing')
check(init.operations.first[:argv].last.include?('ca.dev.internal'), 'CA SAN missing')

# Native source changes drive configuration without edits to implementation.
Dir.mktmpdir do |dir|
  FileUtils.cp_r(File.join(ROOT, 'config'), dir)
  saved = Bootstrap::CONFIG
  Bootstrap.send(:remove_const, :CONFIG); Bootstrap.const_set(:CONFIG, File.join(dir, 'config'))
  begin
    file = File.join(Bootstrap::CONFIG, 'agent/puppet.conf.tmpl')
    File.write(file, File.read(file).sub('runinterval = 30m', 'runinterval = 60m'))
    changed = Bootstrap::Plan.new(fixture(agent: true), 'agent-config').build
    check(changed.operations.first[:content].include?('runinterval = 60m'), 'Template is not authoritative')
  ensure
    Bootstrap.send(:remove_const, :CONFIG); Bootstrap.const_set(:CONFIG, saved)
  end
end

existing = { 'foreman' => { 'db_password' => 'fixture-secret', 'db_manage' => false }, 'other' => true }
merged = Bootstrap.merge(existing, 'foreman' => { 'db_manage' => true })
check(merged['foreman']['db_password'] == 'fixture-secret' && existing['foreman']['db_manage'] == false, 'Merge lost secret or mutated input')
check(Bootstrap.merge_ini("[main]\nlogdest = syslog\n[agent]\nnoop = true\n", "[main]\nserver = new.internal\n").include?('noop = true'), 'Unmanaged Agent settings lost')
[-> { Bootstrap.yaml("puppet: true\npuppet: false\n") },
 -> { Bootstrap.merge_ini("[agent]\nserver = old.internal\n", "[main]\nserver = new.internal\n") }].each do |bad|
  raised = false; begin bad.call; rescue StandardError; raised = true; end
  check(raised, 'Ambiguous config accepted')
end
# Empty package-created directories permit initialization; partial state never does.
Dir.mktmpdir do |dir|
  ca = File.join(dir, 'ca')
  check(Bootstrap.ca_state(ca) == :empty, 'Absent CA state')
  FileUtils.mkdir_p(File.join(ca, 'signed'))
  check(Bootstrap.ca_state(ca) == :empty, 'Empty directory layout must not be treated as a CA')
  File.write(File.join(ca, 'ca_key.pem'), 'fixture, not a real key')
  check(Bootstrap.ca_state(ca) == :partial, 'Partial CA would be overwritten')
  %w[ca_crt.pem ca_crl.pem serial inventory.txt].each { |name| File.write(File.join(ca, name), 'fixture') }
  FileUtils.mkdir_p(File.join(ca, 'requests'))
  check(Bootstrap.ca_state(ca) == :existing, 'Existing CA must be preserved and verified')
end
# Existing Agent trust cannot silently move to a new CA.
Dir.mktmpdir do |dir|
  key = OpenSSL::PKey::RSA.new(1024)
  cert = OpenSSL::X509::Certificate.new
  cert.version = 2; cert.serial = 1
  cert.subject = OpenSSL::X509::Name.parse('/CN=fixture-ca')
  cert.issuer = cert.subject; cert.public_key = key.public_key
  cert.not_before = Time.now - 60; cert.not_after = Time.now + 3600
  cert.sign(key, OpenSSL::Digest::SHA256.new)
  file = File.join(dir, 'ca.pem'); File.write(file, cert.to_pem)
  fingerprint = OpenSSL::Digest::SHA256.hexdigest(cert.to_der).scan(/../).join(':')
  Bootstrap.verify_agent_anchor(file, fingerprint)
  rejected = false
  begin Bootstrap.verify_agent_anchor(file, (['00'] * 32).join(':')); rescue StandardError; rejected = true; end
  check(rejected, 'Existing CA silently replaced')
end
# An invalid plan cannot issue commands or touch /etc.
invalid = Bootstrap::Plan.new(JSON.parse(File.read(File.join(ROOT, 'examples/server.json'))), 'openvox-config').build
raised = false; begin Bootstrap.apply(invalid); rescue StandardError; raised = true; end
check(raised, 'Missing input did not block apply')
# Timeout kills child processes before Open3 waits for them.
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
raised = false; begin Bootstrap.run([RbConfig.ruby, '-e', 'sleep 20'], seconds: 0.1); rescue StandardError; raised = true; end
check(raised && Process.clock_gettime(Process::CLOCK_MONOTONIC) - started < 5, 'Timeout did not bound process lifetime')
# Stub only the local DNS/interface view; other read-only OS/resource checks
# may fail on this test machine. Assert DNS roles without pretending to run AWS.
Dir.mktmpdir do |dir|
  stubs = {
    'hostname' => "echo mgmt.dev.internal\n",
    'ip' => "echo '2: eth0 inet 10.1.0.10/24'\n",
    'getent' => <<~SH,
      case "$2" in
        foreman.dev.internal|puppet.dev.internal) echo "${TEST_SERVICE_IP:-10.1.0.99} STREAM $2" ;;
        ca.dev.internal) echo "${TEST_CA_IP:-10.1.0.10} STREAM $2" ;;
        *) echo "10.1.0.10 STREAM $2" ;;
      esac
    SH
  }
  stubs.each { |name, code| path = File.join(dir, name); File.write(path, "#!/bin/bash\n" + code); File.chmod(0o700, path) }
  script = File.expand_path('../scripts/server-preflight.sh', __dir__)
  args = %w[mgmt.dev.internal foreman.dev.internal puppet.dev.internal ca.dev.internal]
  env = { 'PATH' => dir + ':' + ENV.fetch('PATH') }
  out, = Open3.capture3(env, 'bash', script, *args)
  check(out.include?('PASS Host/CA DNS reaches this VM: mgmt.dev.internal') &&
        out.include?('PASS Host/CA DNS reaches this VM: ca.dev.internal') &&
        out.include?('PASS Service DNS resolves off-VM; confirm NLB alias separately: foreman.dev.internal'), 'NLB DNS roles rejected')
  out, = Open3.capture3(env.merge('TEST_SERVICE_IP' => '10.1.0.10'), 'bash', script, *args)
  check(out.include?('FAIL Service DNS bypasses NLB'), 'Direct service DNS accepted as NLB')
  out, = Open3.capture3(env.merge('TEST_CA_IP' => '10.1.0.99'), 'bash', script, *args)
  check(out.include?('FAIL Host/CA DNS does not resolve to this VM: ca.dev.internal'), 'CA DNS incorrectly pooled')
end
puts 'Passed: 11 wrappers; all stages plan-only; 7 OS x 2 architectures; exact pins; internal CA/manual approval/trust anchor; native templates; merge/guards; timeout; NLB/backend TLS and DNS roles.'
