# Run with: bundle exec ruby tests/catalog_test.rb
# Compiles catalogs only; never applies resources to the local machine.
require 'tmpdir'
require 'fileutils'
require 'puppet'
require 'yaml'

project = File.expand_path('..', __dir__)

def assert(condition, message)
  raise message unless condition
end

def compile_catalog(facts, classes = ['role::base'], environment: nil, csp: 'aws', managed: true)
  name = 'test.example.internal'
  environment ||= facts['deploy_env'] == 'dev' ? 'development' : 'production'
  parameters = csp.nil? ? {} : { 'csp' => csp }
  parameters['puppet_managed'] = managed unless managed == :absent
  node = Puppet::Node.new(name, environment: environment, classes: classes, parameters: parameters,
                          facts: Puppet::Node::Facts.new(name, facts))
  Puppet::Parser::Compiler.compile(node)
end

def expect_failure(facts, message, environment: nil, csp: 'aws', managed: true)
  begin
    compile_catalog(facts, environment: environment, csp: csp, managed: managed)
  rescue Puppet::Error => e
    assert(e.message.include?(message), "Unexpected compilation failure: #{e.message}")
    return
  end
  raise "Expected compilation failure: #{message}"
end

Dir.mktmpdir('foreman-puppet-catalog-') do |root|
  # Work on a copy so hierarchy precedence fixtures never modify project data.
  code = File.join(root, 'code')
  FileUtils.mkdir_p(code)
  %w[environment.conf manifests hiera.yaml data site-modules].each do |entry|
    FileUtils.cp_r(File.join(project, entry), code)
  end
  environments = File.join(root, 'environments')
  FileUtils.mkdir_p(environments)
  FileUtils.ln_s(code, File.join(environments, 'production'))
  FileUtils.ln_s(code, File.join(environments, 'development'))
  FileUtils.ln_s(code, File.join(environments, 'unsupported'))
  Puppet.initialize_settings([
    '--confdir', File.join(root, 'conf'),
    '--vardir', File.join(root, 'var'),
    '--logdir', File.join(root, 'log'),
    '--codedir', root,
    '--environmentpath', environments,
    '--environment', 'production',
  ])
  Puppet[:node_terminus] = 'plain'

  os = {
    'name' => 'Ubuntu',
    'release' => { 'full' => '24.04' },
    'architecture' => 'amd64',
  }

  gpu_states = [[true, true], [true, false], [true, nil], [false, false], [nil, nil]]
  platforms = [
    ['Ubuntu', '20.04.6', %w[amd64 arm64]],
    ['Ubuntu', '22.04.5', %w[amd64 arm64]],
    ['Ubuntu', '24.04', %w[amd64 arm64]],
    ['Ubuntu', '26.04', %w[amd64 arm64]],
    ['Rocky', '8.10', %w[x86_64 aarch64]],
    ['Rocky', '9.6', %w[x86_64 aarch64]],
    ['Amazon', '2', %w[x86_64 aarch64]],
    ['Amazon', '2023.8.20250721', %w[x86_64 aarch64]],
  ].flat_map do |name, release, arches|
    arches.map { |arch| { 'name' => name, 'release' => { 'full' => release }, 'architecture' => arch } }
  end
  %w[dev prd].product(platforms, gpu_states, %w[role::base role::gpu_svr], %w[aws gcp kc]).each do |env, platform, gpu, role, csp|
    present, mig = gpu
    facts = {
      'deploy_env' => env,
      'team' => 'devops',
      'os' => platform,
      'gpu' => { 'present' => present, 'mig' => { 'configured' => mig } },
    }
    catalog = compile_catalog(facts, [role], csp: csp)
    gpu_profile = catalog.resource('Class', 'Profile::Gpu_system')
    assert(!gpu_profile.nil? == (role == 'role::gpu_svr'), 'Wrong GPU Profile selection')
    packages = catalog.resources.select { |r| r.type == 'Package' }.map(&:title).sort
    expected = %w[ca-certificates curl]
    assert(packages == expected, "Wrong Hiera packages for #{env}: #{packages}")

    old_info = catalog.resource('File', '/etc/foreman-puppet/node.conf')
    assert(old_info && old_info[:ensure].to_s == 'absent', 'Old diagnostic file must be removed')
    example = catalog.resource('File', '/etc/foreman-puppet/example.txt')
    assert(example && example[:content] == "echo xxx\n", 'Wrong literal example file content')
    assert(catalog.resources.none? { |r| r.type == 'Exec' }, 'Unexpected executable resource')
  end

  # GPU/MIG facts are optional telemetry and must not gate the base catalog.
  valid = { 'deploy_env' => 'dev', 'os' => os }
  compile_catalog(valid)
  unclassified = compile_catalog(valid, [])
  assert(unclassified.resources.none? { |r| %w[Package File].include?(r.type) },
         'Unclassified node must not receive managed resources')

  expect_failure(valid.reject { |k, _| k == 'deploy_env' }, 'deploy_env must be dev or prd')
  expect_failure(valid.merge('deploy_env' => 'production'), 'deploy_env must be dev or prd')
  expect_failure(valid.merge('deploy_env' => '../common'), 'deploy_env must be dev or prd')
  expect_failure(valid.merge('os' => os.merge('name' => 'Debian')), 'supports Ubuntu, Rocky or Amazon only')
  expect_failure(valid.merge('os' => os.merge('release' => { 'full' => '23.10' })),
                 'supports Ubuntu 20.04, 22.04, 24.04 or 26.04 only')
  expect_failure(valid.merge('os' => os.merge('architecture' => 's390x')),
                 'supports Ubuntu os.architecture amd64 or arm64 only')
  expect_failure(valid, 'deploy_env does not match', environment: 'production')
  expect_failure(valid.merge('deploy_env' => 'prd'), 'deploy_env does not match', environment: 'development')
  expect_failure(valid, 'supports Puppet environments development or production only', environment: 'unsupported')
  expect_failure(valid.merge('os' => { 'name' => 'Rocky', 'release' => { 'full' => '7.9' }, 'architecture' => 'x86_64' }),
                 'supports Rocky 8 or 9 only')
  expect_failure(valid.merge('os' => { 'name' => 'Rocky', 'release' => { 'full' => '9.6' }, 'architecture' => 's390x' }),
                 'supports Rocky os.architecture x86_64 or aarch64 only')
  ['1', '20230'].each do |release|
    expect_failure(valid.merge('os' => { 'name' => 'Amazon', 'release' => { 'full' => release }, 'architecture' => 'x86_64' }),
                   'supports Amazon Linux 2 or 2023 only')
  end
  expect_failure(valid.merge('os' => { 'name' => 'Amazon', 'release' => { 'full' => '2' }, 'architecture' => 's390x' }),
                 'supports Amazon os.architecture x86_64 or aarch64 only')
  expect_failure(valid, 'csp ENC parameter must be', csp: nil)
  expect_failure(valid, 'csp ENC parameter must be', csp: 'unknown')
  expect_failure(valid, 'csp ENC parameter must be', csp: '../common')

  %w[role::base role::gpu_svr profile::base profile::packages profile::example_file profile::gpu_system profile::services profile::ssh].each do |klass|
    catalog = compile_catalog(valid, [klass], managed: false)
    assert(catalog.resources.none? { |r| %w[Package File Exec Service].include?(r.type) },
           "Excluded node must not get managed resources from #{klass}")
  end
  %w[role::base role::gpu_svr].each do |role|
    compile_catalog({}, [role], csp: nil, managed: false)
  end
  expect_failure(valid, 'puppet_managed must be a Boolean', managed: :absent)
  expect_failure(valid, 'puppet_managed must be a Boolean', managed: 'false')
  expect_failure(valid, 'puppet_managed must be a Boolean', managed: nil)
  # A team or puppet_managed Fact is not the central ENC switch.
  compile_catalog(valid.merge('puppet_managed' => false, 'team' => 'other'), managed: true)

  # Team roles include common settings, but never infer ownership from facts.
  %w[devops data_infra].each do |team|
    catalog = compile_catalog(valid.merge('team' => 'other'), ["role::#{team}"])
    assert(catalog.resource('Class', "Profile::#{team.capitalize}"), "Missing team profile: #{team}")
    assert(catalog.resource('File', '/etc/foreman-puppet/example.txt'), 'Team role must include base')
    assert(catalog.resources.count { |r| r.type == 'Package' } == 2, 'Team role duplicates base packages')
    excluded = compile_catalog({}, ["role::#{team}"], managed: false, csp: nil)
    assert(excluded.resources.none? { |r| %w[Package File Exec Service].include?(r.type) }, 'Team role bypassed exclusion')
  end
  unmanaged = compile_catalog({}, ['role::unmanaged'], managed: false, csp: nil)
  assert(unmanaged.resources.none? { |r| %w[Package File Exec Service].include?(r.type) }, 'Unmanaged role changes resources')
  [true, :absent, 'false'].each do |value|
    begin
      compile_catalog(valid, ['role::unmanaged'], managed: value)
      raise "Unmanaged role accepted unsafe management value: #{value}"
    rescue Puppet::Error => e
      assert(e.message.include?('puppet_managed'), 'Unexpected unmanaged role failure')
    end
  end
  # A mistakenly retained managed role is also suppressed by the false flag.
  mixed = compile_catalog({}, ['role::unmanaged', 'role::devops'], managed: false, csp: nil)
  assert(mixed.resources.none? { |r| %w[Package File Exec Service].include?(r.type) }, 'Mixed roles bypassed exclusion')
  base_team_fact = compile_catalog(valid.merge('team' => 'devops'))
  assert(!base_team_fact.resource('Class', 'Profile::Devops'), 'Team fact selected a role')

  common_path = File.join(code, 'data', 'common.yaml')
  common = YAML.safe_load(File.read(common_path))
  {
    'profile::packages::manage' => ['Package'],
    'profile::example_file::manage' => ['File'],
    'profile::base::manage' => ['Package', 'File', 'Exec', 'Service'],
  }.each do |key, excluded_types|
    File.write(common_path, common.merge(key => false).to_yaml)
    catalog = compile_catalog(valid)
    assert(catalog.resources.none? { |r| excluded_types.include?(r.type) }, "Profile exclusion failed: #{key}")
  end
  File.write(common_path, common.to_yaml)

  # SSH is opt-in: verify enabled OS mapping, validation and state wiring.
  platforms.each do |platform|
    os_name = platform['name']
    File.write(common_path, common.merge('profile::ssh::manage' => true).to_yaml)
    catalog = compile_catalog(valid.merge('os' => platform))
    config = catalog.resource('File', '/etc/ssh/sshd_config.d/00-foreman-puppet.conf')
    assert(config && config[:validate_cmd].include?('validate-sshd-config.rb %'), 'SSH candidate validation missing')
    assert(config[:owner] == 'root' && config[:group] == 'root', 'SSH must be root-owned')
    assert(config[:content].include?("Banner /etc/issue.net\nPasswordAuthentication yes\nPermitRootLogin yes\n"), 'Requested SSH values missing')
    unit = os_name == 'Ubuntu' ? 'ssh.service' : 'sshd.service'
    assert(catalog.resource('Exec', "profile-service-#{unit}-refresh"), 'Wrong OS SSH service name')
    assert(!catalog.resource('Exec', "profile-service-#{unit}-state"), 'SSH default must preserve stopped state')
    excluded = compile_catalog({}, ['role::base'], csp: nil, managed: false)
    assert(!excluded.resource('File', '/etc/ssh/sshd_config.d/00-foreman-puppet.conf'), 'Host exclusion must suppress SSH')
  end
  File.write(common_path, common.to_yaml)

  policy_data = { 'example.service' => { 'state_policy' => 'running', 'change_action' => 'none' } }
  File.write(common_path, common.merge('profile::services::units' => policy_data).to_yaml)
  catalog = compile_catalog(valid)
  state = catalog.resource('Exec', 'profile-service-example.service-state')
  assert(state && state[:command].include?('start'), 'Hiera must select the running exception')
  File.write(common_path, common.merge('profile::services::units' => policy_data,
                                      'profile::services::manage' => false).to_yaml)
  catalog = compile_catalog(valid)
  assert(catalog.resources.none? { |r| r.type == 'Exec' }, 'services manage=false must suppress actions')
  policy_data['example.service']['manage'] = false
  File.write(common_path, common.merge('profile::services::units' => policy_data).to_yaml)
  catalog = compile_catalog(valid)
  assert(catalog.resources.none? { |r| r.type == 'Exec' }, 'Unit manage=false must suppress actions')
  File.write(common_path, common.to_yaml)

  # Add distinct values at each layer in the isolated test code environment.
  key = 'profile::example_file::content'
  File.write(File.join(code, 'data', 'deploy_env', 'dev.yaml'), { key => "environment\n" }.to_yaml)
  File.write(File.join(code, 'data', 'csp', 'aws.yaml'), { key => "csp\n" }.to_yaml)
  FileUtils.mkdir_p(File.join(code, 'data', 'csp', 'aws'))
  File.write(File.join(code, 'data', 'csp', 'aws', 'prd.yaml'), { key => "csp+environment\n" }.to_yaml)
  %w[aws gcp kc].product(%w[dev prd]).each do |csp, env|
    catalog = compile_catalog(valid.merge('deploy_env' => env), csp: csp)
    expected = if csp == 'aws'
                 env == 'prd' ? "csp+environment\n" : "csp\n"
               else
                 env == 'dev' ? "environment\n" : "echo xxx\n"
               end
    content = catalog.resource('File', '/etc/foreman-puppet/example.txt')[:content]
    assert(content == expected, "Wrong hierarchy precedence for #{csp}/#{env}: #{content.inspect}")
  end
  puts 'Passed: 960 base combinations; team/unmanaged roles; opt-in SSH policy; host/profile exclusion and Boolean validation; 17 platform rejection cases; 6 hierarchy precedence cases.'

end
