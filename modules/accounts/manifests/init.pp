class accounts {

  include groups
  include ssh

  $rootgroup = $osfamily ? {
    'Debian'  => 'sudo',
    'RedHat'  => 'wheel',
    default   => warning('This distribution is not supported by the Accounts module'),
  }
 
 user { 'vihar':
    ensure      => present,
    home        => '/home/vihar',
    shell       => '/bin/bash',
    managehome  => true,
    gid         => 'vihar',
    groups      => "$rootgroup",
    password    => '$1$tcdsmTQW$xnj98.gzd3M8NvnXOca2i.',
    }

}
