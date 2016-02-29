node 'puppet' {
  include accounts
  include firewall
 } 

node 'client1.novalocal' {
  
  include apache
  include memcached 


resources { 'firewall':
    purge => true,
  }

  Firewall {
    before        => Class['firewall::post'],
    require       => Class['firewall::pre'],
  }

  class { ['firewall::pre', 'firewall::post']: }

}
        
node 'client2.novalocal' {
  include accounts

  resources { 'firewall':
    purge => true,
  }

  Firewall {
    before        => Class['firewall::post'],
    require       => Class['firewall::pre'],
  }

  class { ['firewall::pre', 'firewall::post']: }

}

 
