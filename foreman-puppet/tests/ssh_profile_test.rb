# Applies only temporary files with fake sshd/systemctl; never changes real SSH.
require 'tmpdir'
require 'fileutils'
require 'puppet'
require 'rbconfig'

def assert(condition, message)
  raise message unless condition
end

Dir.mktmpdir('foreman-puppet-ssh-') do |root|
  project = File.expand_path('..', __dir__)
  environments = File.join(root, 'environments')
  FileUtils.mkdir_p(environments)
  Puppet.initialize_settings([
    '--confdir', File.join(root, 'conf'), '--vardir', File.join(root, 'var'),
    '--logdir', File.join(root, 'log'), '--codedir', root,
    '--environmentpath', environments,
  ])
  Puppet[:node_terminus] = 'plain'

  make_case = lambda do |name, state: 'active', manage: true, policy: 'preserve'|
    path = File.join(environments, name)
    FileUtils.mkdir_p(File.join(path, 'manifests'))
    File.write(File.join(path, 'environment.conf'), "modulepath = #{project}/site-modules\nmanifest = manifests\n")
    File.write(File.join(path, 'state'), state)
    File.write(File.join(path, '00-managed.dropin'), "# existing config\n")
    File.write(File.join(path, 'main.conf'), "Include #{path}/*.dropin\n")
    sshd = File.join(path, 'sshd')
    File.write(sshd, <<~'SH')
      #!/bin/sh
      base=${0%/*}
      test "$2" = -f || exit 2
      printf 'validate\n' >> "$base/validation"
      if test -f "$base/hang"; then sleep 4; fi
      if /bin/grep -q invalid "$3"; then exit 1; fi
      if test "$1" = -T; then
        /usr/bin/awk 'NF && $1 !~ /^#/ { key=tolower($1); if (!seen[key]++) print key " " $2 }' "$3"
      fi
    SH
    systemctl = File.join(path, 'systemctl')
    File.write(systemctl, <<~'SH')
      #!/bin/sh
      base=${0%/*}
      case "$1" in
        is-active) test "$(cat "$base/state")" = active ;;
        reload|start)
          printf '%s\n' "$1" >> "$base/actions"
          if test -f "$base/fail"; then exit 1; fi
          if test "$1" = start; then printf active > "$base/state"; fi
          ;;
        *) exit 2 ;;
      esac
    SH
    [sshd, systemctl].each { |exe| File.chmod(0o755, exe) }
    File.write(File.join(path, 'manifests', 'site.pp'), <<~PP)
      class { 'profile::ssh':
        manage => #{manage},
        config_path => #{File.join(path, '00-managed.dropin').inspect},
        main_config => #{File.join(path, 'main.conf').inspect},
        validator_dir => #{File.join(path, 'validator').inspect},
        ruby => #{RbConfig.ruby.inspect},
        sshd => #{sshd.inspect}, systemctl => #{systemctl.inspect},
        state_policy => #{policy.inspect}, validation_timeout => 1, timeout => 5,
      }
    PP
    path
  end

  apply = lambda do |path, managed: true, failure: false|
    node = Puppet::Node.new('test.example.internal', environment: File.basename(path),
                            parameters: { 'puppet_managed' => managed },
                            facts: Puppet::Node::Facts.new('test.example.internal', { 'os' => { 'name' => 'Ubuntu' } }))
    compiled = Puppet::Parser::Compiler.compile(node)
    # Sandbox cannot chown to root. Preserve ownership assertions in catalog_test;
    # this apply harness exercises only temp-file content/mode and event behavior.
    compiled.resources.select { |resource| resource.type == 'File' }.each do |resource|
      resource.parameters.delete(:owner)
      resource.parameters.delete(:group)
    end
    catalog = compiled.to_ral
    catalog.host_config = false
    transaction = catalog.apply
    assert(transaction.report.resource_statuses.values.any?(&:failed?) == failure, "Unexpected result: #{path}: #{transaction.report.logs.select { |l| l.level == :err }.map(&:message).join("; ")}")
    log = File.join(path, 'actions')
    actions = File.exist?(log) ? File.readlines(log, chomp: true) : []
    File.write(log, '')
    catalog.clear
    actions
  end

  path = make_case.call('active')
  assert(apply.call(path) == ['reload'], 'Valid change must reload once')
  assert(File.read(File.join(path, '00-managed.dropin')).include?('PermitRootLogin yes'), 'Candidate not installed')
  assert((File.stat(File.join(path, '00-managed.dropin')).mode & 0o777) == 0o600, 'Wrong permissions')
  assert(apply.call(path).empty?, 'Unchanged config must not reload')
  File.write(File.join(path, '00-managed.dropin'), "# drift\n")
  assert(apply.call(path) == ['reload'], 'Drift must be corrected and reloaded')

  path = make_case.call('first_install')
  File.unlink(File.join(path, '00-managed.dropin'))
  assert(apply.call(path) == ['reload'], 'Include glob must accept a new managed drop-in')

  path = make_case.call('nested_include')
  File.write(File.join(path, 'main.conf'), "Include nested.conf\n")
  File.write(File.join(path, 'nested.conf'), "Include #{path}/*.dropin\n")
  assert(apply.call(path) == ['reload'], 'Nested relative Include must preserve managed position')

  path = make_case.call('inactive', state: 'inactive')
  assert(apply.call(path).empty?, 'Preserve must not start SSH')
  assert(File.read(File.join(path, '00-managed.dropin')).include?('PermitRootLogin yes'), 'Stopped service config not updated')
  path = make_case.call('running', state: 'inactive', policy: 'running')
  assert(apply.call(path) == ['start'], 'Running must start without redundant reload')

  path = make_case.call('invalid')
  File.write(File.join(path, 'main.conf'), "invalid config\nInclude #{path}/*.dropin\n")
  assert(apply.call(path, failure: true).empty?, 'Invalid config must not reload')
  assert(File.read(File.join(path, '00-managed.dropin')) == "# existing config\n", 'Invalid config replaced live file')

  path = make_case.call('validation_timeout')
  File.write(File.join(path, 'hang'), '')
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  assert(apply.call(path, failure: true).empty?, 'Timed-out validation must not reload')
  assert(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started < 10, 'Unbounded validation')
  assert(File.read(File.join(path, '00-managed.dropin')) == "# existing config\n", 'Timeout replaced live file')

  { 'missing_include' => "# no Include\n",
    'match_block' => "Include %PATH%/*.dropin\nMatch User root\n  PasswordAuthentication no\n",
    'shadowed' => "PasswordAuthentication no\nInclude %PATH%/*.dropin\n",
    'include_cycle' => "Include %PATH%/main.conf\nInclude %PATH%/*.dropin\n" }.each do |name, main|
    path = make_case.call(name)
    File.write(File.join(path, 'main.conf'), main.gsub('%PATH%', path))
    assert(apply.call(path, failure: true).empty?, "Unsafe config accepted: #{name}")
    assert(File.read(File.join(path, '00-managed.dropin')) == "# existing config\n", 'Failed validation replaced drop-in')
  end

  path = make_case.call('reload_failure')
  File.write(File.join(path, 'fail'), '')
  assert(apply.call(path, failure: true) == ['reload'], 'Failed reload retried or fell back')
  assert(apply.call(path).empty?, 'Unchanged run replayed failed event')

  [[false, true], [true, false]].each_with_index do |(manage, managed), i|
    path = make_case.call("excluded#{i}", manage: manage)
    assert(apply.call(path, managed: managed).empty?, 'Excluded SSH performed action')
    assert(!File.exist?(File.join(path, 'validation')), 'Excluded SSH validated config')
    assert(File.read(File.join(path, '00-managed.dropin')) == "# existing config\n", 'Excluded SSH changed config')
  end
  puts 'Passed: SSH candidate validation, idempotence/drift, state policy, timeout, reload failure and exclusion.'
end
