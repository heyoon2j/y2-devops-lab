# A small Hiera-backed file example; no shell command is executed.
class profile::example_file (
  String[1] $content,
) {
  file { '/etc/foreman-puppet':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # Remove the old diagnostic file if an earlier catalog created it.
  file { '/etc/foreman-puppet/node.conf':
    ensure => absent,
  }

  file { '/etc/foreman-puppet/example.txt':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $content,
    require => File['/etc/foreman-puppet'],
  }
}
