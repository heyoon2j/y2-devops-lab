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

def compile_catalog(facts, classes = ['role::base'], environment: nil, csp: 'aws')
  name = 'test.example.internal'
  environment ||= facts['deploy_env'] == 'dev' ? 'development' : 'production'
  parameters = csp.nil? ? {} : { 'csp' => csp }
  node = Puppet::Node.new(name, environment: environment, classes: classes, parameters: parameters,
                          facts: Puppet::Node::Facts.new(name, facts))
  Puppet::Parser::Compiler.compile(node)
end

def expect_failure(facts, message, environment: nil, csp: 'aws')
  begin
    compile_catalog(facts, environment: environment, csp: csp)
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
    ['Ubuntu', '24.04', %w[amd64 arm64]],
    ['Ubuntu', '26.04', %w[amd64 arm64]],
    ['Rocky', '8.10', %w[x86_64 aarch64]],
    ['Rocky', '9.6', %w[x86_64 aarch64]],
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
  expect_failure(valid.merge('os' => os.merge('name' => 'Debian')), 'supports Ubuntu or Rocky only')
  expect_failure(valid.merge('os' => os.merge('release' => { 'full' => '22.04' })),
                 'supports Ubuntu 20.04, 24.04 or 26.04 only')
  expect_failure(valid.merge('os' => os.merge('architecture' => 's390x')),
                 'supports Ubuntu os.architecture amd64 or arm64 only')
  expect_failure(valid, 'deploy_env does not match', environment: 'production')
  expect_failure(valid.merge('deploy_env' => 'prd'), 'deploy_env does not match', environment: 'development')
  expect_failure(valid, 'supports Puppet environments development or production only', environment: 'unsupported')
  expect_failure(valid.merge('os' => { 'name' => 'Rocky', 'release' => { 'full' => '7.9' }, 'architecture' => 'x86_64' }),
                 'supports Rocky 8 or 9 only')
  expect_failure(valid.merge('os' => { 'name' => 'Rocky', 'release' => { 'full' => '9.6' }, 'architecture' => 's390x' }),
                 'supports Rocky os.architecture x86_64 or aarch64 only')
  expect_failure(valid, 'csp ENC parameter must be', csp: nil)
  expect_failure(valid, 'csp ENC parameter must be', csp: 'unknown')
  expect_failure(valid, 'csp ENC parameter must be', csp: '../common')

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
  puts 'Passed: 600 CSP/role/environment/OS/architecture/GPU combinations, optional facts, unclassified node, 14 rejection cases, 6 hierarchy precedence cases.'

end
