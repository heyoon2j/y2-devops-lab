# Run with: bundle exec ruby tests/catalog_test.rb
# Compiles catalogs only; never applies resources to the local machine.
require 'tmpdir'
require 'fileutils'
require 'puppet'

project = File.expand_path('..', __dir__)

def assert(condition, message)
  raise message unless condition
end

def compile_catalog(facts, classes = ['role::base'], environment: nil)
  name = 'test.example.internal'
  environment ||= facts['deploy_env'] == 'dev' ? 'development' : 'production'
  node = Puppet::Node.new(name, environment: environment, classes: classes,
                          facts: Puppet::Node::Facts.new(name, facts))
  Puppet::Parser::Compiler.compile(node)
end

def expect_failure(facts, message, environment: nil)
  begin
    compile_catalog(facts, environment: environment)
  rescue Puppet::Error => e
    assert(e.message.include?(message), "Unexpected compilation failure: #{e.message}")
    return
  end
  raise "Expected compilation failure: #{message}"
end

Dir.mktmpdir('foreman-puppet-catalog-') do |root|
  environments = File.join(root, 'environments')
  FileUtils.mkdir_p(environments)
  FileUtils.ln_s(project, File.join(environments, 'production'))
  FileUtils.ln_s(project, File.join(environments, 'development'))
  FileUtils.ln_s(project, File.join(environments, 'unsupported'))
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
  %w[dev prd].product(%w[amd64 arm64], gpu_states, %w[role::base role::gpu_svr]).each do |env, arch, gpu, role|
    present, mig = gpu
    facts = {
      'deploy_env' => env,
      'os' => os.merge('architecture' => arch),
      'gpu' => { 'present' => present, 'mig' => { 'configured' => mig } },
    }
    catalog = compile_catalog(facts, [role])
    gpu_profile = catalog.resource('Class', 'Profile::Gpu_system')
    assert(!gpu_profile.nil? == (role == 'role::gpu_svr'), 'Wrong GPU Profile selection')
    packages = catalog.resources.select { |r| r.type == 'Package' }.map(&:title).sort
    expected = %w[ca-certificates curl]
    assert(packages == expected, "Wrong Hiera packages for #{env}: #{packages}")

    info = catalog.resource('File', '/etc/foreman-puppet/node.conf')
    assert(info && info[:content].include?("deploy_env=#{env}\n"), 'Missing environment in node.conf')
    puppet_env = env == 'dev' ? 'development' : 'production'
    assert(info[:content].include?("puppet_env=#{puppet_env}\n"), 'Wrong Puppet code environment')
    assert(info[:content].include?("arch=#{arch}\n"), 'Wrong architecture in node.conf')
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
  expect_failure(valid.merge('os' => os.merge('name' => 'Debian')), 'supports Ubuntu 24.04 only')
  expect_failure(valid.merge('os' => os.merge('release' => { 'full' => '22.04' })),
                 'supports Ubuntu 24.04 only')
  expect_failure(valid.merge('os' => os.merge('architecture' => 's390x')),
                 'supports os.architecture amd64 or arm64 only')
  expect_failure(valid, 'deploy_env does not match', environment: 'production')
  expect_failure(valid.merge('deploy_env' => 'prd'), 'deploy_env does not match', environment: 'development')
  expect_failure(valid, 'supports Puppet environments development or production only', environment: 'unsupported')
  puts 'Passed: 40 role/environment/architecture/GPU combinations, missing GPU facts, unclassified node, 9 rejection cases.'
end
