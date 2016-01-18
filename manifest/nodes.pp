node 'puppet-master'  {
file { '/tmp/hello':
content => "Hello, world\n",
}
}

