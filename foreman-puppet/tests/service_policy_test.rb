# Applies isolated catalogs to temporary files and a fake systemctl executable.
# No real service or /etc file is modified.
require 'tmpdir'
require 'fileutils'
require 'puppet'

def assert(condition, message)
  raise message unless condition
end

def compile_case(path, name, managed: true)
  node = Puppet::Node.new('test.example.internal', environment: name,
                          parameters: { 'puppet_managed' => managed },
                          facts: Puppet::Node::Facts.new('test.example.internal', {}))
  Puppet::Parser::Compiler.compile(node)
end

def apply_case(path, name, managed: true, failure: false)
  catalog = compile_case(path, name, managed: managed).to_ral
  catalog.host_config = false
  transaction = catalog.apply
  failed = transaction.report.resource_statuses.values.any?(&:failed?)
  errors = transaction.report.logs.select { |log| log.level == :err }.map(&:message).join("\n")
  assert(failed == failure, "Unexpected apply result for #{name}: #{errors}")
  actions = File.exist?(File.join(path, 'actions')) ? File.readlines(File.join(path, 'actions'), chomp: true) : []
  File.write(File.join(path, 'actions'), '')
  actions
ensure
  catalog&.clear
end

Dir.mktmpdir('foreman-puppet-service-') do |root|
  project = File.expand_path('..', __dir__)
  environments = File.join(root, 'environments')
  FileUtils.mkdir_p(environments)
  Puppet.initialize_settings([
    '--confdir', File.join(root, 'conf'), '--vardir', File.join(root, 'var'),
    '--logdir', File.join(root, 'log'), '--codedir', root,
    '--environmentpath', environments,
  ])
  Puppet[:node_terminus] = 'plain'

  make_case = lambda do |name, state: 'active', policy: 'preserve', action: 'reload',
                         manage: true, timeout: 5, invalid_config: false, unit: 'test.service', files: true|
    path = File.join(environments, name)
    FileUtils.mkdir_p(File.join(path, 'manifests'))
    File.write(File.join(path, 'environment.conf'),
               "modulepath = #{project}/site-modules\nmanifest = manifests\n")
    File.write(File.join(path, 'state'), state)
    executable = File.join(path, 'systemctl')
    File.write(executable, <<~'SH')
      #!/bin/sh
      base=${0%/*}
      case "$1" in
        is-active) test "$(cat "$base/state")" = active ;;
        show) cat "$base/state" ;;
        validate) ! /bin/grep -q invalid "$2" ;;
        start|stop|reload|restart)
          action=$1
          printf '%s\n' "$action" >> "$base/actions"
          if test -f "$base/hang"; then sleep 4; fi
          if test -f "$base/fail"; then exit 1; fi
          case "$action" in
            start|restart) printf active > "$base/state" ;;
            stop) printf inactive > "$base/state" ;;
            reload) test "$(cat "$base/state")" = active ;;
          esac
          ;;
        *) exit 2 ;;
      esac
    SH
    File.chmod(0o755, executable)
    config = File.join(path, 'example.conf')
    content = invalid_config ? "invalid\n" : "managed\n"
    validation = invalid_config ? "validate_cmd => #{"#{executable} validate %".inspect}," : ''
    manifest = <<~PP
      file { #{config.inspect}:
        ensure => file,
        content => #{content.inspect},
        backup => false,
        show_diff => false,
        #{validation}
      }
      profile::service_control { #{unit.inspect}:
        manage => #{manage},
        state_policy => #{policy.inspect},
        change_action => #{action.inspect},
        config_files => #{files ? "[#{config.inspect}]" : '[]'},
        timeout => #{timeout},
        systemctl => #{executable.inspect},
      }
    PP
    File.write(File.join(path, 'manifests', 'site.pp'), manifest)
    path
  end

  path = make_case.call('preserve_active')
  assert(apply_case(path, 'preserve_active') == ['reload'], 'Changed config must reload once')
  assert(apply_case(path, 'preserve_active').empty?, 'Unchanged run must do nothing')
  File.write(File.join(path, 'example.conf'), "manual drift\n")
  assert(apply_case(path, 'preserve_active') == ['reload'], 'Corrected drift must reload once')

  path = make_case.call('preserve_inactive', state: 'inactive')
  assert(apply_case(path, 'preserve_inactive').empty?, 'Preserve must not start a stopped service')
  assert(File.read(File.join(path, 'state')) == 'inactive', 'Stopped state must be preserved')

  path = make_case.call('running_inactive', state: 'inactive', policy: 'running')
  assert(apply_case(path, 'running_inactive') == ['start'], 'Start once without redundant reload')
  assert(apply_case(path, 'running_inactive').empty?, 'Already-running service must not restart')
  File.write(File.join(path, 'state'), 'inactive')
  assert(apply_case(path, 'running_inactive') == ['start'], 'Running policy must repair stopped state')

  path = make_case.call('running_restart', policy: 'running', action: 'restart')
  assert(apply_case(path, 'running_restart') == ['restart'], 'Changed active service must restart once')

  path = make_case.call('stopped_active', policy: 'stopped', action: 'none')
  assert(apply_case(path, 'stopped_active') == ['stop'], 'Stopped policy must stop active service')
  assert(apply_case(path, 'stopped_active').empty?, 'Stopped service must remain unchanged')
  path = make_case.call('stopped_activating', state: 'activating', policy: 'stopped', action: 'none')
  assert(apply_case(path, 'stopped_activating') == ['stop'], 'Stop policy must cover an in-progress start')

  path = make_case.call('action_none', action: 'none')
  assert(apply_case(path, 'action_none').empty?, 'none must not act on a config event')
  path = make_case.call('profile_disabled', policy: 'running', state: 'inactive', manage: false)
  assert(apply_case(path, 'profile_disabled').empty?, 'Disabled helper must not act')
  path = make_case.call('host_disabled', policy: 'running', state: 'inactive')
  assert(apply_case(path, 'host_disabled', managed: false).empty?, 'Excluded host must not act')

  path = make_case.call('reload_failure', policy: 'running')
  File.write(File.join(path, 'fail'), '')
  assert(apply_case(path, 'reload_failure', failure: true) == ['reload'], 'No retry or fallback restart')
  File.delete(File.join(path, 'fail'))
  assert(apply_case(path, 'reload_failure').empty?, 'Failed refresh is not replayed without another event')

  path = make_case.call('reload_timeout', timeout: 1)
  File.write(File.join(path, 'hang'), '')
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  assert(apply_case(path, 'reload_timeout', failure: true) == ['reload'], 'Timeout must fail once')
  assert(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started < 10, 'Timed command must be bounded')

  path = make_case.call('invalid_config', invalid_config: true, policy: 'running')
  File.write(File.join(path, 'example.conf'), "old valid config\n")
  assert(apply_case(path, 'invalid_config', failure: true).empty?, 'Validation failure must skip service actions')
  assert(File.read(File.join(path, 'example.conf')) == "old valid config\n", 'Old file must survive validation failure')

  [
    ['invalid_combination', { policy: 'stopped', action: 'restart' }, 'stopped state_policy requires'],
    ['missing_files', { files: false }, 'config_files is required'],
    ['invalid_unit', { unit: 'test;echo bad' }, 'valid systemd unit name'],
  ].each do |name, options, message|
    path = make_case.call(name, **options)
    begin
      compile_case(path, name)
    rescue Puppet::Error => e
      assert(e.message.include?(message), "Wrong validation for #{name}: #{e.message}")
      next
    end
    raise "Expected compile failure for #{name}"
  end

  puts 'Passed: isolated service policy apply tests, idempotence, exclusion, failure, timeout, validation and 3 invalid configurations.'
end
