# frozen_string_literal: true
# Uses only Ruby stdlib bundled with openvox-agent. No Python or extra gems.
require 'json'
require 'yaml'
require 'optparse'
require 'fileutils'
require 'tempfile'
require 'open3'
require 'timeout'
require 'socket'
require 'openssl'
require 'time'

module Bootstrap
  ROOT = File.expand_path('..', __dir__)
  CONFIG = File.join(ROOT, 'config')
  ANSWERS = '/etc/foreman-installer/scenarios.d/foreman-answers.yaml'
  SCENARIO = '/etc/foreman-installer/scenarios.d/foreman.yaml'
  SSL = '/etc/puppetlabs/puppet/ssl'
  CA = '/etc/puppetlabs/puppetserver/ca'
  PUPPET_CONF = '/etc/puppetlabs/puppet/puppet.conf'
  LOGDIR = '/var/log/foreman-openvox-bootstrap'

  def self.yaml(text)
    document = Psych.parse(text)
    inspect_node = lambda do |node|
      if node.is_a?(Psych::Nodes::Mapping)
        keys = node.children.each_slice(2).map { |key, _| key.value }
        raise 'Duplicate YAML keys' unless keys.uniq == keys
      end
      (node.respond_to?(:children) ? node.children : nil)&.each { |child| inspect_node.call(child) }
    end
    inspect_node.call(document)
    result = YAML.safe_load(text, permitted_classes: [Symbol], aliases: false)
    raise 'Expected YAML mapping' unless result.is_a?(Hash)
    result
  end

  def self.merge(existing, overlay)
    existing.merge(overlay) { |_key, old, new_value| old.is_a?(Hash) && new_value.is_a?(Hash) ? merge(old, new_value) : new_value }
  end

  def self.ini(text)
    result = {}; section = nil
    text.each_line do |line|
      stripped = line.strip
      next if stripped.empty? || stripped.start_with?('#', ';')
      if (match = stripped.match(/\A\[([a-zA-Z0-9_]+)\]\z/))
        section = match[1]
        raise 'Duplicate INI section' if result.key?(section)
        result[section] = {}
      elsif section && (match = stripped.match(/\A([a-zA-Z0-9_]+)\s*=\s*(.*?)\z/))
        raise 'Duplicate INI setting' if result[section].key?(match[1])
        result[section][match[1]] = match[2]
      else
        raise 'Unsupported puppet.conf syntax'
      end
    end
    result
  end

  def self.merge_ini(existing, candidate)
    incoming = ini(candidate)
    raise 'Agent template must contain only [main]' unless incoming.keys == ['main']
    current = ini(existing)
    current.each do |section, settings|
      raise "Conflicting puppet.conf section: #{section}" if section != 'main' && !(settings.keys & incoming['main'].keys).empty?
    end
    current['main'] = (current['main'] || {}).merge(incoming['main'])
    current.map { |name, settings| "[#{name}]\n" + settings.map { |key, value| "#{key} = #{value}\n" }.join }.join("\n")
  end

  # Bounded commands; timeout terminates the process group, including children.
  def self.run(argv, seconds: 3600, log: nil)
    pid = nil; output = ''
    options = { pgroup: true }
    if log
      File.open(log, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |handle|
        handle.chmod(0o600)
        pid = Process.spawn(*argv, **options, out: handle, err: handle)
        Timeout.timeout(seconds) { _child, status = Process.wait2(pid); raise "Command failed; inspect root-only #{log}" unless status.success? }
      end
    else
      Open3.popen2e(*argv, **options) do |stdin, stream, waiter|
        pid = waiter.pid; stdin.close
        begin
          Timeout.timeout(seconds) do
            output = stream.read
            raise "Command failed: #{argv[0]}" unless waiter.value.success?
          end
        rescue Timeout::Error
          begin Process.kill('KILL', -pid); rescue Errno::ESRCH; end
          raise
        end
      end
    end
    output
  rescue Timeout::Error
    begin Process.kill('KILL', -pid) if pid; rescue Errno::ESRCH; end
    begin Process.wait(pid) if pid; rescue Errno::ECHILD; end
    raise "Command timed out: #{argv[0]}"
  end

  def self.atomic(path, content, mode)
    raise "Refusing symlink: #{path}" if File.symlink?(path)
    FileUtils.mkdir_p(File.dirname(path))
    Tempfile.create('.bootstrap-', File.dirname(path)) do |file|
      file.chmod(mode); file.write(content); file.flush; file.fsync
      File.rename(file.path, path)
    end
  end

  class Plan
    attr_reader :cfg, :action, :errors, :operations, :config_root
    def initialize(cfg, action, config_root: CONFIG)
      @cfg, @action, @config_root = cfg, action, config_root
      @errors = []; @operations = []
    end
    def get(key)
      key.split('.').reduce(cfg) { |value, name| value.is_a?(Hash) ? value[name] : nil }
    end
    def need(key, pattern)
      value = get(key)
      unless value.is_a?(String) && pattern.match?(value)
        errors << "Set valid #{key}"; return "<unset:#{key}>"
      end
      value
    end
    def host(key)
      value = need(key, /\A(?=.{1,253}\z)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9-]+\z/)
      errors << "Replace example hostname: #{key}" if value.end_with?('.example.internal', '.example.com', '.invalid')
      value
    end
    def platform
      id, version, arch = get('os.id'), get('os.version'), get('os.architecture')
      allowed = { 'ubuntu' => %w[22.04 24.04 26.04], 'rocky' => %w[8 9], 'amzn' => %w[2 2023] }
      errors << 'Unsupported OS/version' unless allowed.fetch(id, []).include?(version)
      errors << 'Unsupported architecture' unless %w[x86_64 aarch64].include?(arch)
      errors << 'Management server requires Ubuntu 24.04 x86_64' unless action == 'agent-config' || [id, version, arch] == %w[ubuntu 24.04 x86_64]
    end
    def render(name, values)
      result = File.read(File.join(config_root, name)).gsub(/\{\{([a-z][a-z0-9_]*)\}\}/) do
        key = Regexp.last_match(1)
        raise "Unknown template variable: #{key}" unless values.key?(key)
        values[key].nil? ? "<unset:#{key}>" : values[key].to_s
      end
      raise 'Unresolved template expression' if result.include?('{{') || result.include?('}}')
      result
    end
    def packages
      %w[foreman.json openvox-server.json].flat_map { |name| JSON.parse(File.read(File.join(config_root, 'packages', name))) }
    end
    def values
      result = {}
      %w[host_fqdn foreman_fqdn foreman_service_fqdn puppet_fqdn puppet_certname ca_fqdn].each { |key| result[key] = host(key) }
      result
    end
    def build
      platform
      if action == 'agent-config'
        env = get('puppet_environment')
        errors << 'Environment must be development or production' unless %w[development production].include?(env)
        %w[deploy_env team dr_site tls].each { |key| errors << "Remove legacy #{key}; central parameters/internal CA are used" if cfg.key?(key) }
        fingerprint = need('puppet_ca_fingerprint', /\A(?:[A-Fa-f0-9]{2}:){31}[A-Fa-f0-9]{2}\z/)
        v = { 'puppet_fqdn' => host('puppet_fqdn'), 'ca_fqdn' => host('ca_fqdn'), 'certname' => host('certname'), 'puppet_environment' => env }
        text = render('agent/puppet.conf.tmpl', v)
        settings = Bootstrap.ini(text)
        raise 'Agent template must contain only [main]' unless settings.keys == ['main']
        { 'server' => v['puppet_fqdn'], 'ca_server' => v['ca_fqdn'], 'certname' => v['certname'], 'environment' => env,
          'waitforcert' => '0', 'usecacheonfailure' => 'false', 'certificate_revocation' => 'chain' }.each do |key, value|
          errors << "Required Agent setting: #{key}" unless settings['main'][key] == value
        end
        operations << { type: 'puppetconf', content: text, path: PUPPET_CONF, source: 'config/agent/puppet.conf.tmpl' }
        operations << { type: 'bootstrap_instructions', ca_fingerprint: fingerprint,
                        argv: ['/opt/puppetlabs/bin/puppet', 'ssl', 'bootstrap', '--ca-fingerprint', fingerprint, '--waitforcert', '0'],
                        automatic_execution: false }
      else
        v = values
        errors << 'Only the first single server can enable this CA; CA identity must match host FQDN' unless v['puppet_certname'] == v['host_fqdn']
        errors << 'Use ca_mode=internal_primary for the initial single server' unless get('ca_mode') == 'internal_primary'
        errors << 'Remove legacy installer argument lists; edit native YAML templates' if cfg.key?('installer')
        baselines = JSON.parse(File.read(File.join(config_root, 'versions.json')))
        packages.each do |package|
          pin = need('package_versions.' + package, /\A[A-Za-z0-9.+:~_-]+\z/)
          expected = baselines[package]
          errors << "Wrong upstream pin: #{package}" if expected && pin != expected && !pin.start_with?(expected + '-')
        end
        if action == 'ca-init'
          operations << { type: 'ca_init', argv: ['puppetserver', 'ca', 'setup', '--certname', v['puppet_certname'],
                                                 '--subject-alt-names', [v['host_fqdn'], v['puppet_fqdn'], v['ca_fqdn']].uniq.join(',')],
                          path: CA, existing_ca: 'verify and preserve; never regenerate' }
        else
          %w[ca_cert host_cert host_key].each { |key| v[key] = need('tls.' + key, %r{\A/[A-Za-z0-9_./-]+\z}) }
          overlay = {}
          sources = %w[server/foreman.answers.yaml.tmpl server/openvox.answers.yaml.tmpl]
          sources.each do |name|
            part = Bootstrap.yaml(render(name, v))
            raise 'Server templates overlap' unless (part.keys & overlay.keys).empty?
            overlay.merge!(part)
          end
          required = { 'puppet' => { 'server' => true, 'server_ca' => true, 'autosign' => false, 'manage_packages' => false,
                                     'client_package' => 'openvox-agent', 'server_package' => 'openvox-server',
                                     'server_foreman_url' => 'https://' + v['foreman_service_fqdn'] + ':8444' },
                       'foreman' => { 'db_manage' => true, 'ssl' => true, 'server_ssl_port' => 443, 'server_ssl_verify_client' => 'optional' },
                       'foreman_proxy' => { 'puppetca' => true, 'foreman_base_url' => 'https://' + v['foreman_service_fqdn'] + ':8444' } }
          required.each do |mod, entries|
            entries.each { |key, value| errors << "Required answers setting: #{mod}.#{key}" unless overlay.fetch(mod, {})[key] == value }
          end
          aliases = overlay.fetch('foreman', {})['serveraliases']
          [v['host_fqdn'], v['foreman_service_fqdn']].each do |name|
            errors << 'Keep host and internal service DNS aliases on the Foreman vhost' unless aliases.is_a?(Array) && aliases.include?(name)
          end
          overlay.each_value do |settings|
            next unless settings.is_a?(Hash)
            errors << 'Keep credentials out of public templates' if settings.keys.any? { |key| key.match?(/password|oauth_consumer_(key|secret)/) }
          end
          operations << { type: 'installer', path: ANSWERS, argv: ['foreman-installer', '--scenario', 'foreman'], answers_overlay: overlay,
                          sources: sources.map { |name| 'config/' + name } }
        end
      end
      self
    end
  end

  def self.verify_target(cfg)
    release = File.read('/etc/os-release').lines.filter_map { |line| line.strip.split('=', 2) if line.include?('=') }.to_h
    id = release['ID'].delete('"'); version = release['VERSION_ID'].delete('"')
    version = version.split('.').first if id == 'rocky'
    arch = run(['uname', '-m'], seconds: 10).strip
    raise 'Target OS does not match input' unless [id, version, arch] == cfg['os'].values_at('id', 'version', 'architecture')
  end

  def self.verify_pair(cert_path, key_path, ca_path, names)
    cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
    key = OpenSSL::PKey.read(File.read(key_path))
    raise 'Certificate/private key mismatch' unless cert.check_private_key(key)
    stat = File.stat(key_path)
    raise 'Private key must be root-owned and inaccessible to other users' unless stat.uid.zero? && (stat.mode & 0o007).zero?
    run(['openssl', 'verify', '-CAfile', ca_path, cert_path], seconds: 30)
    names.uniq.each { |name| run(['openssl', 'x509', '-in', cert_path, '-noout', '-checkhost', name], seconds: 30) }
  end

  def self.ca_state(path)
    raise 'Refusing symlink CA directory' if File.symlink?(path)
    return :empty unless File.exist?(path)
    raise 'CA path must be a directory' unless File.directory?(path)
    return :empty if Dir.glob(File.join(path, '**', '*'), File::FNM_DOTMATCH).none? { |entry| File.file?(entry) || File.symlink?(entry) }
    required = %w[ca_key.pem ca_crt.pem ca_crl.pem serial inventory.txt signed requests]
    required.all? { |name| File.exist?(File.join(path, name)) } ? :existing : :partial
  end

  def self.verify_ca(cfg)
    required = %w[ca_key.pem ca_crt.pem ca_crl.pem serial inventory.txt signed requests]
    raise 'Incomplete/missing CA state; restore or run explicit ca-init on a fresh host' unless required.all? { |name| File.exist?(File.join(CA, name)) }
    ca = OpenSSL::X509::Certificate.new(File.read(File.join(CA, 'ca_crt.pem')))
    key = OpenSSL::PKey.read(File.read(File.join(CA, 'ca_key.pem')))
    raise 'CA key mismatch' unless ca.check_private_key(key)
    name = cfg.fetch('puppet_certname')
    verify_pair(File.join(SSL, 'certs', name + '.pem'), File.join(SSL, 'private_keys', name + '.pem'),
                File.join(SSL, 'certs/ca.pem'), [cfg['host_fqdn'], cfg['puppet_fqdn'], cfg['ca_fqdn']])
    raise 'CA trust bundle differs from active CA' unless File.binread(File.join(SSL, 'certs/ca.pem')) == File.binread(File.join(CA, 'ca_crt.pem'))
  end

  def self.verify_agent_anchor(ca_file, fingerprint)
    return unless File.exist?(ca_file)
    cert = OpenSSL::X509::Certificate.new(File.read(ca_file))
    actual = OpenSSL::Digest::SHA256.hexdigest(cert.to_der).upcase
    raise 'Existing Agent CA differs from the pinned CA; explicit migration required' unless actual == fingerprint.delete(':').upcase
  end

  def self.apply(plan)
    raise plan.errors.join('; ') unless plan.errors.empty?
    raise '--apply must run as root on the target' unless Process.euid.zero?
    FileUtils.mkdir_p('/run/lock')
    File.open('/run/lock/foreman-openvox-bootstrap.lock', 'a') do |lock|
      raise 'Another bootstrap is running' unless lock.flock(File::LOCK_EX | File::LOCK_NB)
      verify_target(plan.cfg)
      unless plan.action == 'agent-config'
        raise 'Set actual host FQDN before configure' unless run(['hostname', '-f'], seconds: 10).strip == plan.cfg['host_fqdn']
        plan.packages.each do |package|
          actual = run(['dpkg-query', '-W', '-f=${Version}', package], seconds: 30).strip
          raise "Install pinned package first: #{package}" unless actual == plan.cfg['package_versions'][package]
        end
      end
      plan.operations.each do |operation|
        case operation[:type]
        when 'puppetconf'
          # Do not silently migrate preissued external-PKI settings to internal CA.
          existing = File.exist?(PUPPET_CONF) ? File.read(PUPPET_CONF) : ''
          prior = ini(existing)
          ca_file = File.join(SSL, 'certs/ca.pem')
          verify_agent_anchor(ca_file, plan.cfg.fetch('puppet_ca_fingerprint'))
          old_name = prior.fetch('main', {})['certname']
          raise 'Existing Agent identity requires explicit migration' if File.exist?(ca_file) && old_name && old_name != plan.cfg['certname']
          legacy = %w[localcacert hostcert hostprivkey ssldir]
          raise 'Review existing external-PKI path overrides before internal CA configuration' if prior.values.any? { |v| !(v.keys & legacy).empty? }
          atomic(PUPPET_CONF, merge_ini(existing, operation[:content]), 0o644)
        when 'bootstrap_instructions'
          puts 'Agent settings saved. Certificate enrollment and first apply are separate; regular service was not started.'
        when 'ca_init'
          legacy = File.join(SSL, 'ca')
          raise 'Legacy CA path requires explicit migration' if File.exist?(legacy)
          state = ca_state(CA)
          raise 'Partial CA state requires recovery, not initialization' if state == :partial
          if state == :existing
            verify_ca(plan.cfg)
            puts 'Existing complete CA preserved; no initialization performed.'
          else
            raise 'Existing SSL state requires review; refusing CA initialization' if File.exist?(SSL) && Dir.glob(File.join(SSL, '**', '*')).any? { |entry| File.file?(entry) || File.symlink?(entry) }
            raise 'Stop puppetserver before first CA setup' if system('systemctl', 'is-active', '--quiet', 'puppetserver')
            help = run(['puppetserver', 'ca', 'setup', '--help'], seconds: 60)
            %w[--certname --subject-alt-names].each { |flag| raise "Unsupported CA CLI option: #{flag}" unless help.include?(flag) }
            run(operation[:argv], seconds: 300)
            verify_ca(plan.cfg)
            puts 'Internal CA initialized; preserve its complete state in an encrypted external backup.'
          end
        when 'installer'
          verify_ca(plan.cfg)
          tls = plan.cfg.fetch('tls')
          verify_pair(tls.fetch('host_cert'), tls.fetch('host_key'), tls.fetch('ca_cert'), [plan.cfg['host_fqdn'], plan.cfg['foreman_service_fqdn']])
          help = run(['foreman-installer', '--full-help'], seconds: 120).gsub('--[no-]', '--')
          operation[:answers_overlay].each do |mod, settings|
            prefix = mod.tr(':', '-').gsub('--', '-').tr('_', '-')
            flags = settings.is_a?(Hash) ? settings.keys.map { |key| '--' + prefix + '-' + key.tr('_', '-') } : ['--enable-' + prefix]
            flags.each { |flag| raise "Unsupported installer option: #{flag}" unless help.match?(/#{Regexp.escape(flag)}(?=[\s=|,]|$)/) }
          end
          scenario = yaml(File.read(SCENARIO))
          raise 'Unexpected scenario answers path' unless (scenario[:answer_file] || scenario[':answer_file'] || scenario['answer_file']) == ANSWERS
          raise 'Refusing symlink log directory' if File.symlink?(LOGDIR)
          FileUtils.mkdir_p(LOGDIR, mode: 0o700); File.chmod(0o700, LOGDIR)
          raise 'Refusing symlink answers' if File.symlink?(ANSWERS)
          existing = {}
          if File.exist?(ANSWERS)
            st = File.stat(ANSWERS)
            raise 'Existing answers must be root-owned 0600' unless st.uid.zero? && (st.mode & 0o077).zero?
            existing = yaml(File.read(ANSWERS))
            atomic(File.join(LOGDIR, 'answers-before-' + Time.now.utc.strftime('%Y%m%dT%H%M%S%6N') + '.yaml'), File.binread(ANSWERS), 0o600)
          end
          # Refuse changing an existing installation from external PKI implicitly.
          old = existing['puppet']
          raise 'Existing external-CA answers require explicit migration' if old.is_a?(Hash) && old['server_ca'] == false
          atomic(ANSWERS, YAML.dump(merge(existing, operation[:answers_overlay])), 0o600)
          log = File.join(LOGDIR, plan.action + '.log')
          raise 'Refusing symlink log file' if File.symlink?(log)
          run(operation[:argv], log: log)
          puts "Installer output stored in root-only #{log}"
        end
      end
    end
  end

  def self.main(argv)
    action = argv.shift
    raise 'Unknown configuration stage' unless %w[foreman-config openvox-config agent-config ca-init].include?(action)
    options = {}
    OptionParser.new do |parser|
      parser.on('--config PATH') { |path| options[:config] = path }
      parser.on('--apply') { options[:apply] = true }
    end.parse!(argv)
    raise 'Unexpected arguments' unless argv.empty?
    plan = Plan.new(JSON.parse(File.read(options.fetch(:config))), action).build
    if options[:apply]
      apply(plan)
    else
      puts JSON.pretty_generate(action: action, mode: 'plan', unresolved: plan.errors, operations: plan.operations)
    end
    0
  rescue StandardError => error
    warn "ERROR: #{error.message}"
    1
  end
end
exit(Bootstrap.main(ARGV) || 0) if $PROGRAM_NAME == __FILE__
