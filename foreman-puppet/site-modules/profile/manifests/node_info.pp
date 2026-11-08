# Do not write back into facts.d: deploy_env remains owned by user-data.
class profile::node_info {
  file { '/etc/foreman-puppet':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/foreman-puppet/node.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('profile/node.conf.epp', {
      'deploy_env' => $facts['deploy_env'],
      'puppet_env' => $environment,
      'os_name'    => $facts['os']['name'],
      'os_release' => $facts['os']['release']['full'],
      'arch'       => $facts['os']['architecture'],
    }),
    require => File['/etc/foreman-puppet'],
  }
}
