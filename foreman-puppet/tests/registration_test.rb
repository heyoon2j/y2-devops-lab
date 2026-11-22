require 'json'
require 'tmpdir'
require 'stringio'
require_relative '../bootstrap/lib/register'

def check(value, message)
  raise message unless value
end

def rejects(message)
  yield
  raise "Expected rejection: #{message}"
rescue Registration::Error
end

class FakeForeman
  attr_reader :calls
  attr_accessor :present, :ambiguous, :collision, :inherited_team, :old_policy
  def initialize(config)
    @h = config.fetch('host')
    @calls = []
  end
  def call(method, path, body = nil)
    @calls << [method, path, body]
    if method == :post
      @present = true
      raise Registration::Error, 'timeout' if @ambiguous
      return { 'id' => 42 }
    end
    return { 'subtotal' => @present ? 1 : 0, 'results' => @present ? [{ 'name' => @h['name'], 'id' => 42 }] : [] } if path.start_with?('/api/hosts?')
    if path.end_with?('/enc')
      params = @h.fetch('parameters').merge('bootstrap_identity' => @collision ? 'aws/other' : @h['bootstrap_identity'], 'csp' => @h['csp'])
      params['team'] = 'inherited' if @inherited_team
      params['deploy_env'] = 'prd' if @old_policy
      return { 'data' => { 'parameters' => params, 'environment' => @old_policy ? 'production' : @h['environment'], 'classes' => { @old_policy ? 'role::devops' : @h['role'] => {} } } }
    end
    return @h.slice('name', 'organization_id', 'location_id').merge('id' => 42) if path == '/api/hosts/42'
    { 'name' => case path
                when %r{/hostgroups/} then @h['csp']
                when %r{/environments/} then @h['environment']
                when %r{/puppetclasses/} then @h['role']
                end }
  end
end

cfg = JSON.parse(File.read(File.expand_path('../bootstrap/examples/registration.json', __dir__)))
cfg['host']['name'] = 'i-123.dev.example.internal'
Registration.validate(cfg)
api = FakeForeman.new(cfg)
check(Registration::Runner.new(cfg, api).run['status'] == 'created', 'new host')
posts = api.calls.select { |c| c.first == :post }
check(posts.size == 1, 'one POST')
h = posts.first.last.fetch('host')
check(h['overwrite'] == false && h['managed'] == false, 'no provisioning or overwrite')
params = h.fetch('host_parameters_attributes')
check(params.none? { |p| p['name'] == 'team' }, 'unset team omitted')
check(params.find { |p| p['name'] == 'puppet_managed' } == { 'name' => 'puppet_managed', 'value' => 'true', 'parameter_type' => 'boolean' }, 'typed Boolean')
check(h['puppet_attributes']['puppetclass_ids'] == [1], 'plugin payload')
api = FakeForeman.new(cfg)
api.present = api.old_policy = true
check(Registration::Runner.new(cfg, api).run['status'] == 'existing_preserved', 'central policy preserved')
check(api.calls.all? { |c| c.first == :get }, 'existing host has no writes')
api.collision = true
rejects('identity collision') { Registration::Runner.new(cfg, api).run }
api = FakeForeman.new(cfg)
api.ambiguous = true
check(Registration::Runner.new(cfg, api).run['status'] == 'existing_preserved', 'ambiguous POST reconciled')
check(api.calls.count { |c| c.first == :post } == 1, 'ambiguous POST never retried')
api = FakeForeman.new(cfg)
api.inherited_team = true
rejects('inherited nullable team') { Registration::Runner.new(cfg, api).run }
%w[sandbox invalid].each do |env|
  bad = Marshal.load(Marshal.dump(cfg))
  bad['host']['parameters']['deploy_env'] = env
  rejects('invalid environment') { Registration.validate(bad) }
end
bad = Marshal.load(Marshal.dump(cfg))
bad['foreman']['url'] = 'http://example.internal'
rejects('HTTP') { Registration.validate(bad) }
bad['foreman']['url'] = 'https://user:secret@example.internal'
rejects('userinfo') { Registration.validate(bad) }
Dir.mktmpdir do |dir|
  file = File.join(dir, 'pat')
  File.write(file, 'a-private-token-value')
  File.chmod(0o644, file)
  rejects('unsafe token mode') { Registration.token('source' => 'file', 'path' => file) }
  if Process.euid.zero?
    File.chmod(0o600, file)
    check(Registration.token('source' => 'file', 'path' => file) == 'a-private-token-value', 'safe PAT file')
  end
  File.symlink(file, File.join(dir, 'link'))
  rejects('symlink token file') { Registration.token('source' => 'file', 'path' => File.join(dir, 'link')) }
  input = File.join(dir, 'input.json')
  cfg['auth'] = { 'source' => 'file', 'path' => '/nonexistent/pat' }
  File.write(input, JSON.generate(cfg))
  previous, $stdout = $stdout, StringIO.new
  begin
    Registration.main(['--config', input])
    check(JSON.parse($stdout.string)['mode'] == 'plan', 'offline plan reads no secret or network')
  ensure
    $stdout = previous
  end
end
puts 'Registration tests passed: create-only payload, preserved policy, identity collision, ambiguous POST, inheritance, input and PAT guards, offline plan.'

# Real local TLS transport: CA verification, Basic header, redirect refusal.
require 'socket'
require 'openssl'
key = OpenSSL::PKey::RSA.new(2048)
cert = OpenSSL::X509::Certificate.new
cert.version, cert.serial = 2, 1
cert.subject = cert.issuer = OpenSSL::X509::Name.parse('/CN=localhost')
cert.public_key = key.public_key
cert.not_before, cert.not_after = Time.now - 60, Time.now + 3600
factory = OpenSSL::X509::ExtensionFactory.new
factory.subject_certificate = factory.issuer_certificate = cert
cert.add_extension(factory.create_extension('basicConstraints', 'CA:TRUE', true))
cert.add_extension(factory.create_extension('subjectAltName', 'DNS:localhost'))
cert.sign(key, OpenSSL::Digest::SHA256.new)
Dir.mktmpdir do |dir|
  ca = File.join(dir, 'ca.pem')
  File.write(ca, cert.to_pem)
  [200, 302, 401].each do |code|
    tcp = TCPServer.new('127.0.0.1', 0)
    sslctx = OpenSSL::SSL::SSLContext.new
    sslctx.cert, sslctx.key = cert, key
    server = OpenSSL::SSL::SSLServer.new(tcp, sslctx)
    headers = nil
    worker = Thread.new do
      socket = server.accept
      begin
        headers = ''
        headers << socket.gets until headers.end_with?("\r\n\r\n")
        socket.write("HTTP/1.1 #{code} Status\r\nContent-Length: 2\r\nConnection: close\r\nLocation: https://elsewhere.invalid/\r\n\r\n{}")
      ensure
        socket.close
      end
    end
    api = Registration::API.new({ 'url' => "https://localhost:#{tcp.addr[1]}", 'username' => 'bootstrap', 'ca_cert' => ca }, 'private-token-value')
    if code == 200
      check(api.call(:get, '/api/hosts') == {}, 'trusted HTTPS works')
    else
      rejects('redirect/auth refusal') { api.call(:get, '/api/hosts') }
    end
    worker.value
    check(headers.include?('Authorization: Basic '), 'PAT uses Basic over TLS')
    tcp.close
  end
  tcp = TCPServer.new('127.0.0.1', 0)
  sslctx = OpenSSL::SSL::SSLContext.new
  sslctx.cert, sslctx.key = cert, key
  server = OpenSSL::SSL::SSLServer.new(tcp, sslctx)
  worker = Thread.new do
    begin
      socket = server.accept
      socket.close
    rescue OpenSSL::SSL::SSLError
      # Expected TLS client abort for an untrusted issuer.
    end
  end
  api = Registration::API.new({ 'url' => "https://localhost:#{tcp.addr[1]}", 'username' => 'bootstrap', 'ca_cert' => '/etc/ssl/certs/ca-certificates.crt' }, 'private-token-value')
  rejects('untrusted certificate') { api.call(:get, '/api/hosts') }
  worker.value
  tcp.close
end
puts 'HTTPS transport tests passed: trusted CA, Basic header, redirects refused, untrusted CA refused.'

# Validate the AWS CLI boundary without making a real AWS request.
Dir.mktmpdir do |dir|
  aws = File.join(dir, 'aws')
  File.write(aws, "#!/bin/bash\nprintf '%s' '{\"Parameter\":{\"Type\":\"SecureString\",\"Value\":\"test-private-token-value\"}}'\n")
  File.chmod(0o700, aws)
  previous_path = ENV['PATH']
  begin
    ENV['PATH'] = dir + ':' + previous_path
    token = Registration.token('source' => 'aws_ssm', 'region' => 'ap-northeast-2', 'reference' => '/foreman/dev/pat')
    check(token == 'test-private-token-value', 'SSM SecureString decoding')
    File.write(aws, "#!/bin/bash\nprintf '%s' '{\"Parameter\":{\"Type\":\"String\",\"Value\":\"test-private-token-value\"}}'\n")
    rejects('plaintext SSM parameter') { Registration.token('source' => 'aws_ssm', 'region' => 'ap-northeast-2', 'reference' => '/foreman/dev/pat') }
  ensure
    ENV['PATH'] = previous_path
  end
end

# Source-only Bash function delegates argv safely, including whitespace paths.
Dir.mktmpdir('registration adapter ') do |dir|
  require 'fileutils'
  FileUtils.mkdir_p(File.join(dir, 'bootstrap/agent'))
  File.write(File.join(dir, 'bootstrap/agent/register.sh'), "printf '%s\\n' \"$@\"\n")
  config = File.join(dir, 'input with spaces.json')
  File.write(config, '{}')
  source = File.expand_path('../bootstrap/user-data/register.bash', __dir__)
  [nil, 'apply'].each do |mode|
    out, err, status = Open3.capture3('bash', '-c', 'source "$1"; foreman_register "$2" "$3" ${4:+"$4"}', 'adapter-test', source, dir, config, *[mode].compact)
    expected = "--config\n#{config}\n" + (mode ? "--apply\n" : '')
    check(status.success? && out == expected, "Bash adapter failed: #{err}")
  end
end
puts 'PAT provider and Bash adapter tests passed.'
