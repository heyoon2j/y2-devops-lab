# Run with: bundle exec ruby tests/catalog_test.rb
# Compiles catalogs only; never applies resources to the local machine.
require 'tmpdir'
require 'fileutils'
require 'puppet'

project = File.expand_path('..', __dir__)

def assert(condition, message)
  raise message unless condition
end

def compile_catalog(facts, classes = ['role::base'])
  name = 'test.example.internal'
  node = Puppet::Node.new(name, environment: 'production', classes: classes,
                          facts: Puppet::Node::Facts.new(name, facts))
  Puppet::Parser::Compiler.compile(node)
end

def expect_failure(facts, message)
  begin
    compile_catalog(facts)
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

  %w[dev prd].product(%w[amd64 arm64], [true, false, nil]).each do |env, arch, mig|
    facts = {
      'deploy_env' => env,
      'os' => os.merge('architecture' => arch),
      'gpu' => { 'mig' => { 'configured' => mig } },
    }
    catalog = compile_catalog(facts)
    packages = catalog.resources.select { |r| r.type == 'Package' }.map(&:title).sort
    expected = env == 'dev' ? %w[ca-certificates curl jq] : %w[ca-certificates curl]
    assert(packages == expected, "Wrong Hiera packages for #{env}: #{packages}")

    info = catalog.resource('File', '/etc/foreman-puppet/node.conf')
    assert(info && info[:content].include?("deploy_env=#{env}\n"), 'Missing environment in node.conf')
    assert(info[:content].include?("arch=#{arch}\n"), 'Wrong architecture in node.conf')
    assert(catalog.resources.none? { |r| r.type == 'Exec' }, 'Unexpected executable resource')
  end

  # MIG facts are optional telemetry and must not gate the base catalog.
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
  puts 'Passed: 12 environment/architecture/MIG combinations, missing MIG, unclassified node, 6 rejection cases.'
end
