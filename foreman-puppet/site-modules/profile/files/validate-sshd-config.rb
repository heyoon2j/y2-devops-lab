# Run with the Puppet Agent Ruby. The timeout is supplied by File.validate_cmd.
# Flatten existing Include directives in order and substitute the candidate only
# at the managed drop-in's actual include position. Never modify live inputs.
require 'open3'
require 'shellwords'
require 'tempfile'

begin
  candidate, managed, main, sshd = ARGV
  raise 'Expected candidate, managed path, main config and sshd executable' unless ARGV.length == 4
  managed = File.expand_path(managed)
  include_root = File.dirname(File.expand_path(main))
  inserted = 0
  expand = nil
  expand = lambda do |path, stack|
    path = File.expand_path(path)
    raise 'Include cycle or excessive depth' if stack.include?(path) || stack.length >= 16
    input = path == managed ? candidate : path
    inserted += 1 if path == managed
    File.readlines(input).flat_map do |line|
      # Include inside Match has parser scope semantics that text expansion cannot
      # safely reproduce. Require an explicit implementation for such configs.
      raise 'Match blocks require a separate SSH integration; refusing staged expansion' if line.match?(/^\s*Match(?:\s|=)/i)
      if line.match?(/^\s*Include\s+/i)
        # Shellwords handles quoted paths; full-line comments never enter here.
        patterns = Shellwords.split(line.strip).drop(1)
        raise 'Empty Include directive' if patterns.empty?
        patterns.flat_map do |pattern|
          raise 'Unsupported Include expansion' if pattern.match?(/[~$%]/)
          pattern = File.expand_path(pattern, include_root)
          paths = Dir.glob(pattern).sort
          # The new managed file may not exist on the first Puppet application.
          if File.fnmatch?(pattern, managed, File::FNM_PATHNAME)
            paths = (paths + [managed]).uniq.sort
          end
          paths.flat_map { |included| expand.call(included, stack + [path]) }
        end
      else
        # Ensure files without a final newline cannot merge adjacent directives.
        [line.end_with?("\n") ? line : "#{line}\n"]
      end
    end
  end
  lines = expand.call(main, [])
  raise 'Main config must include the managed drop-in exactly once' unless inserted == 1
  expected = File.readlines(candidate).filter_map do |line|
    next if line.strip.empty? || line.lstrip.start_with?('#')
    key, value = line.strip.split(/\s+/, 2)
    [key.downcase, value]
  end.to_h
  raise 'Unexpected candidate directives' unless expected.keys.sort == %w[banner passwordauthentication permitrootlogin]
  Tempfile.create(['foreman-sshd-', '.conf']) do |file|
    file.chmod(0o600)
    file.write(lines.join)
    file.flush
    _output, error, status = Open3.capture3(sshd, '-t', '-f', file.path)
    raise "Combined SSH validation failed: #{error}" unless status.success?
    # Check global defaults and a root-login context. Other Match contexts still
    # require OS/operator validation; this is not a connectivity test.
    [[], ['-C', 'user=root,host=localhost,addr=127.0.0.1']].each do |context|
      output, error, status = Open3.capture3(sshd, '-T', '-f', file.path, *context)
      raise "SSH effective config check failed: #{error}" unless status.success?
      effective = output.lines.map { |line| line.strip.split(/\s+/, 2) }.to_h
      raise 'Requested SSH values are shadowed by existing settings' unless expected.all? { |key, value| effective[key] == value }
    end
  end
rescue StandardError => e
  warn e.message
  exit 1
end
