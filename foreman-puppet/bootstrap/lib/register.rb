# Foreman create-only registration. Ruby standard library; no Puppet run or CA signing.
require 'json'
require 'net/http'
require 'openssl'
require 'uri'
require 'open3'
require 'timeout'

module Registration
  class Error < StandardError; end
  ROLES = %w[role::base role::unmanaged role::devops role::data_infra].freeze

  def self.validate(c)
    f, h, auth = c.fetch('foreman'), c.fetch('host'), c.fetch('auth')
    u = URI(f.fetch('url'))
    raise Error, 'Foreman URL must be an HTTPS origin' unless u.scheme == 'https' && u.host && !u.userinfo && !u.query && !u.fragment && ['', '/'].include?(u.path)
    raise Error, 'CA certificate path required' unless f['ca_cert'].is_a?(String) && f['ca_cert'].start_with?('/')
    raise Error, 'Username required' unless f['username'].is_a?(String) && f['username'].match?(/\A[a-zA-Z0-9_.@-]+\z/)
    %w[organization_id location_id hostgroup_id environment_id role_id puppet_proxy_id puppet_ca_proxy_id].each do |k|
      raise Error, "#{k} must be a positive integer" unless h[k].is_a?(Integer) && h[k].positive?
    end
    raise Error, 'Use a unique FQDN as both host name and agent certname' unless h['name'].is_a?(String) && h['name'].match?(/\A[a-z0-9][a-z0-9.-]*\.[a-z0-9-]+\z/) && h['name'].size <= 253
    raise Error, 'Invalid CSP' unless %w[aws gcp kc].include?(h['csp'])
    raise Error, 'Invalid role' unless ROLES.include?(h['role'])
    p = h.fetch('parameters')
    raise Error, 'Invalid deploy_env' unless %w[dev prd].include?(p['deploy_env'])
    raise Error, 'Environment must match deploy_env' unless h['environment'] == { 'dev' => 'development', 'prd' => 'production' }.fetch(p['deploy_env'])
    raise Error, 'Invalid team' unless p['team'].nil? || (p['team'].is_a?(String) && p['team'].match?(/\A[a-z][a-z0-9_-]{0,63}\z/))
    raise Error, 'Invalid dr_site' unless [nil, 'primary', 'secondary'].include?(p['dr_site'])
    raise Error, 'puppet_managed must be Boolean' unless [true, false].include?(p['puppet_managed'])
    raise Error, 'Unmanaged role requires puppet_managed=false' if h['role'] == 'role::unmanaged' && p['puppet_managed']
    raise Error, 'Unknown parameters' unless (p.keys - %w[deploy_env team dr_site puppet_managed]).empty?
    raise Error, 'Stable cloud resource identity required' unless h['bootstrap_identity'].is_a?(String) && h['bootstrap_identity'].match?(/\A[a-zA-Z0-9_:\/.=-]{3,256}\z/) && h['bootstrap_identity'].start_with?(h['csp'] + '/')
    raise Error, 'Unknown PAT source' unless %w[aws_ssm file].include?(auth['source'])
    if auth['source'] == 'aws_ssm'
      raise Error, 'SSM region/reference required' unless auth['region'].is_a?(String) && auth['region'].match?(/\A[a-z0-9-]+\z/) && auth['reference'].is_a?(String) && auth['reference'].match?(/\A[a-zA-Z0-9_\/.:-]+\z/)
    else
      raise Error, 'Absolute PAT file path required' unless auth['path'].is_a?(String) && auth['path'].start_with?('/')
    end
    c
  rescue KeyError, URI::InvalidURIError, NoMethodError, TypeError
    raise Error, 'Missing or malformed registration input'
  end

  def self.token(auth)
    value = if auth['source'] == 'file'
      File.open(auth.fetch('path'), File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |io|
        s = io.stat
        raise Error, 'PAT file must be root-owned regular file with mode 0600' unless s.file? && s.uid.zero? && (s.mode & 0o777) == 0o600 && s.size <= 4096
        io.read
      end
    else
      output = nil
      Open3.popen3({ 'AWS_PAGER' => '' }, 'aws', 'ssm', 'get-parameter', '--name', auth.fetch('reference'), '--with-decryption', '--region', auth.fetch('region'), '--output', 'json', pgroup: true) do |stdin, stdout, stderr, wait|
        stdin.close
        # Bound execution; stderr is drained but never included in errors.
        drain = Thread.new { loop { break unless stderr.read(4096) } }
        begin
          Timeout.timeout(30) do
            output = stdout.read(65_537)
            raise Error, 'SSM response too large' if output.bytesize > 65_536
            raise Error, 'SSM token retrieval failed' unless wait.value.success?
          end
        ensure
          # Kill the process group even if its leader exited with children alive.
          Process.kill('KILL', -wait.pid) rescue nil
          drain.join
        end
      end
      data = JSON.parse(output).fetch('Parameter')
      raise Error, 'SSM parameter must be SecureString' unless data['Type'] == 'SecureString'
      data.fetch('Value')
    end
    value = value.strip
    raise Error, 'Invalid PAT format' unless value.match?(/\A[!-~]{16,2048}\z/)
    value
  rescue JSON::ParserError, KeyError, SystemCallError, Timeout::Error
    raise Error, 'Could not securely load PAT'
  end

  class API
    def initialize(foreman, token)
      @url = URI(foreman.fetch('url'))
      @username, @ca = foreman.values_at('username', 'ca_cert')
      @token = token
    end

    def call(method, path, body = nil)
      http = Net::HTTP.new(@url.host, @url.port, nil) # Ignore ambient HTTP proxy variables.
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.verify_hostname = true
      http.ca_file = @ca
      http.open_timeout = 10
      http.read_timeout = 30
      http.write_timeout = 15
      request = (method == :get ? Net::HTTP::Get : Net::HTTP::Post).new(path)
      request.basic_auth(@username, @token)
      request['Accept'] = 'application/json'
      if body
        request['Content-Type'] = 'application/json'
        request.body = JSON.generate(body)
      end
      response = Timeout.timeout(60) { http.request(request) }
      raise Error, "Foreman HTTP #{response.code}" unless response.code.to_i.between?(200, 299)
      JSON.parse(response.body)
    rescue JSON::ParserError
      raise Error, 'Foreman returned invalid JSON'
    rescue OpenSSL::SSL::SSLError, IOError, SystemCallError, Timeout::Error
      raise Error, 'Foreman transport failed (verify TLS/network; POST is not retried)'
    end
  end

  class Runner
    def initialize(config, api)
      @c, @api = Registration.validate(config), api
      @h = @c.fetch('host')
    end

    def lookup
      query = URI.encode_www_form('search' => "name=\"#{@h['name']}\"", 'per_page' => 100)
      result = @api.call(:get, '/api/hosts?' + query)
      raise Error, 'Host lookup incomplete' if result.fetch('subtotal', 0) > 100
      found = result.fetch('results').select { |h| h['name'] == @h['name'] }
      raise Error, 'Ambiguous host name' if found.size > 1
      found.first
    end

    def verify(host, created: false)
      detail = @api.call(:get, "/api/hosts/#{Integer(host.fetch('id'))}")
      raise Error, 'Host name mismatch' unless detail['name'] == @h['name']
      %w[organization_id location_id].each do |k|
        raise Error, "Existing host #{k} mismatch" unless detail[k] == @h[k]
      end
      enc = @api.call(:get, "/api/hosts/#{Integer(host.fetch('id'))}/enc").fetch('data')
      p = enc.fetch('parameters')
      raise Error, 'Host identity collision; policy will not be overwritten' unless p['bootstrap_identity'] == @h['bootstrap_identity'] && p['csp'] == @h['csp']
      roles = enc.fetch('classes').keys.select { |k| k.start_with?('role::') }
      raise Error, 'Invalid central role assignment' unless roles.size == 1 && ROLES.include?(roles.first)
      raise Error, 'Invalid central management policy' unless [true, false].include?(p['puppet_managed']) && !(roles.first == 'role::unmanaged' && p['puppet_managed'])
      raise Error, 'Invalid central environment' unless { 'dev' => 'development', 'prd' => 'production' }[p['deploy_env']] == enc['environment'] && %w[dev prd].include?(p['deploy_env'])
      raise Error, 'Invalid central team' unless p['team'].nil? || (p['team'].is_a?(String) && p['team'].match?(/\A[a-z][a-z0-9_-]{0,63}\z/))
      raise Error, 'Invalid central dr_site' unless [nil, 'primary', 'secondary'].include?(p['dr_site'])
      if created
        raise Error, 'Created host role/environment differs from input' unless roles == [@h['role']] && enc['environment'] == @h['environment']
        @h.fetch('parameters').each { |k, v| raise Error, "Created host #{k} differs from input (check inheritance)" unless p[k] == v }
      end
      { 'status' => created ? 'created' : 'existing_preserved', 'id' => detail.fetch('id'), 'name' => @h['name'] }
    end

    def payload
      params = @h.fetch('parameters').merge('bootstrap_identity' => @h['bootstrap_identity'])
      { 'host' => @h.slice('name', 'organization_id', 'location_id', 'hostgroup_id', 'puppet_proxy_id', 'puppet_ca_proxy_id').merge(
        'managed' => false, 'build' => false, 'overwrite' => false,
        'puppet_attributes' => { 'environment_id' => @h['environment_id'], 'puppetclass_ids' => [@h['role_id']] },
        'host_parameters_attributes' => params.reject { |_, v| v.nil? }.map { |k, v| { 'name' => k, 'value' => v.to_s, 'parameter_type' => [true, false].include?(v) ? 'boolean' : 'string' } }) }
    end

    def run
      existing = lookup
      return verify(existing) if existing
      # Read reference objects first to catch stale IDs before any mutation.
      { 'hostgroups' => ['hostgroup_id', 'name', @h['csp']], 'environments' => ['environment_id', 'name', @h['environment']],
        'puppetclasses' => ['role_id', 'name', @h['role']] }.each do |endpoint, (key, field, expected)|
        obj = @api.call(:get, "/api/#{endpoint}/#{@h[key]}")
        raise Error, "#{endpoint} ID/name mismatch" unless obj[field] == expected
      end
      # At most one create request. Never retry an ambiguous POST or overwrite another host.
      begin
        created = @api.call(:post, '/api/hosts', payload)
      rescue Error => original
        existing = lookup
        return verify(existing) if existing
        raise original
      end
      verify(created, created: true)
    end
  end

  def self.main(args)
    apply = !!args.delete('--apply')
    raise Error, 'Usage: register.sh --config FILE [--apply]' unless args.size == 2 && args.first == '--config'
    c = validate(JSON.parse(File.read(args.last)))
    unless apply
      puts JSON.pretty_generate('mode' => 'plan', 'host' => c['host']['name'], 'policy' => 'create-only; existing central policy preserved', 'auth_source' => c['auth']['source'])
      return
    end
    raise Error, '--apply requires root' unless Process.euid.zero?
    puts JSON.pretty_generate(Runner.new(c, API.new(c['foreman'], token(c['auth']))).run)
  rescue StandardError => e
    # Parser errors can contain input text; never expose them or API bodies.
    warn(e.is_a?(Error) ? e.message : 'Invalid input or unexpected Foreman response')
    exit 1
  end
end
Registration.main(ARGV) if $PROGRAM_NAME == __FILE__
