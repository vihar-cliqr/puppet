#!/bin/bash
##########################################################################################
#This script will install puppet-client on Centos 7 instance
#version =1
#Revision =0
#Date = 15/Aug/16
#Author = Vihar Parameswaran
#Email ID: viparame@cisco.com
##########################################################################################

echo "Enter the Puppet master IP address"
read ipaddress
hostfile=/etc/hosts

#Setting up RPM for puppet agent
#log files
DATE='date +%Y/%m/%d:%H:%M:%S'
LOG='/var/log/puppetagent.log'

function logger {
    echo `$DATE`" $1" >> $LOG
}


logger rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
#configuring puppet.conf files
conf=/etc/puppet/puppet.conf
bak=/etc/puppet/puppet.conf.bak
  if [[ -e $conf ]]; then
    mv $conf $bak
logger    cat <<EOT >> $conf

    [main]
    # The Puppet log directory.
    # The default value is '$vardir/log'.
    logdir = /var/log/puppet

    # Where Puppet PID files are kept.
    # The default value is '$vardir/run'.
    rundir = /var/run/puppet

    # Where SSL certificates are kept.
    # The default value is '$confdir/ssl'.
    ssldir = $vardir/ssl

[agent]
    # The file in which puppetd stores a list of the classes
    # associated with the retrieved configuratiion.  Can be loaded in
    # the separate ``puppet`` executable using the ``--loadclasses``
    # option.
    # The default value is '$confdir/classes.txt'.
    classfile = $vardir/classes.txt

    # Where puppetd caches the local configuration.  An
    # extension indicating the cache format is added automatically.
    # The default value is '$confdir/localconfig'.
    localconfig = $vardir/localconfig
    server = puppetmaster01

EOT

  fi

#setting puppetmaster01 entry in clients host files
    if [[ $ipaddress -ne 0 ]]; then
        logger "setting $ipaddress to $hostfile"
        logger "$ipaddress puppetmaster01" >> $hostfile

    fi

#starting puppetagent service
logger systemctl start  puppet.service
logger systemctl enable puppet.service

#Verifying the certificates on client machine
logger puppet agent -t
logger "script run successfull"
exit
