#!/bin/bash -xh

##########################################################################################
#This script will install puppet-master on Centos 7 instance
#version =1
#Revision =0
#Date = 4/Aug/16
#Author = Vihar Parameswaran
#Email ID: viparame@cisco.com
##########################################################################################
#log files
DATE='date +%Y/%m/%d:%H:%M:%S'
LOG='/var/log/puppetagent.log'

function logger {
    echo `$DATE`" $1" >> $LOG
}

##########################################################################################
#PRE-REQUSITES

function epel_repo_check {

repo_chk=`yum repolist |grep -ir epel`

     logger `wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm`
     logger `rpm -ivh epel-release-7-8.noarch.rpm`
     sleep 4
     if [$repo_chk -eq $?]; then
        logger "yum repository has been set up"
     fi
}

redhat=/etc/redhat-release
centos=/etc/redhat-release
output=`cat /etc/redhat-release`

        if  [ -f "$redhat" ] || [ -f "$centos" ]
then
          logger "Your are running $output"
else
          logger "The script does not support your operating system"
          logger "Exiting"
	 fi

#############################################################################################
# Setting hostname and verifying the connectivity to client and internet

hostname=puppetmaster01
host_file=/etc/hosts
ip_address=`ifconfig eth0 2>/dev/null|awk '/inet / {print $2}'|sed 's/inet://'`

#Setting IP address and hostname to puppetmaster01 in hosts file

	   grep -i "$ip_address $hostname" $host_file
if [ $? -ne 0 ]; then
	   logger $ip_address $hostname >> $host_file
fi

#echo `cat $host_file`

# Checking internet connectivity from puppetmaster01

#Checking connectivity for default gateway:

	    ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo Succeed || echo Failed to ping gateway
	    echo Check if your network is up

#Checking the internet connection:

host=google.com
        function ping_check {
                ping=`ping  -c 1 -W 1 $host | grep bytes |wc -l`
        if [["$ping" -gt 1 ]]; then
            echo "The network is up"
          else
            echo "The network is down"
        fi
}

ping_check

# Downloaing repository for Puppet master version 3.8.7

	    curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo

##To install the puppet master / agent, we would require to setup puppet repository on the all the nodes. Enable puppet labs repository by installing below rpm.

	    rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm

# Install and Configure Puppet server

	    logger "Installing puppet server"
	    logger yum -y install puppet-server

# Verifying puppet.conf file

puppet_dir=/etc/puppet
puppet_conf=puppet.conf

	    cd $puppet_dir
if [ -e $puppet_conf ]; then
  	    grep -i puppetmaster01 $puppet_conf
  if [ $? -ne 0 ]; then
	    logger "configuring puppet.conf file"
	    sed -i '/ssldir/ a dns_alt_names = puppetmaster01' $puppet_conf
	    sed -i '/dns_alt_names/ a certname = puppetmaster01' $puppet_conf
else
	    logger "puppet.conf is already configured"
  fi
else
  	  logger "File not found"
fi
#Generating puppet master certifacte in puppet server
	    logger "Generating puppetmaster certificate on $hostname"

certificate_gen=` puppet master --verbose --daemonize --debug --verbose`
#kill_puppet=`ps -ef | grep "puppet" | awk '{print $2}'`


             logger $certificate_gen
#            echo `kill -9 $kill_puppet`

#Configure a Production-Ready Web Server:

web_install=`yum -y install httpd httpd-devel mod_ssl ruby-devel rubygems gcc gcc-c++ pygpgme curl`
passenger=`yum install -y mod_passenger`

#passenger requires ruby-rake version to install passenger #
        logger "Downloading ruby-rake package from the repository"
#        download
#        install_rake
         set_repo
	logger "installing components for web server"
	logger $web_install
	sleep 5
	logger "Installing mod_passenger service"
  logger $passenger

#Creating directories under /usr/share/puppet/rack/ folder

make_dir=`mkdir -p /usr/share/puppet/rack/puppetmasterd public tmp`

	logger $make_dir
	logger  `cp /usr/share/puppet/ext/rack/config.ru /usr/share/puppet/rack/puppetmasterd/`
	logger  `chown puppet:puppet /usr/share/puppet/rack/puppetmasterd/config.ru`

# Creating and populating puppetmaster.conf file

puppet_masterd_conf=/etc/httpd/conf.d/puppetmaster.conf
ssl_certificate_file=/var/lib/puppet/ssl/certs/puppetmaster01.pem
ssl_certificate_key_file=/var/lib/puppet/ssl/private_keys/puppetmaster01.pem

	if [ ! -f $puppet_masterd_conf ]; then
         logger "File not found!"

	logger touch $puppet_masterd_conf

	logger cat <<EOT >> $puppet_masterd_conf

	# you probably want to tune these settings
	PassengerHighPerformance on
	PassengerMaxPoolSize 12
	PassengerPoolIdleTime 1500
	# PassengerMaxRequests 1000
	PassengerStatThrottleRate 120

Listen 8140

<VirtualHost *:8140>
        SSLEngine on
        SSLProtocol             ALL -SSLv2 -SSLv3
        SSLCipherSuite          EDH+CAMELLIA:EDH+aRSA:EECDH+aRSA+AESGCM:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH:+CAMELLIA256:+AES256:+CAMELLIA128:+AES128:+SSLv3:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!IDEA:!ECDSA:kEDH:CAMELLIA256-SHA:AES256-SHA:CAMELLIA128-SHA:AES128-SHA
        SSLHonorCipherOrder     on

        SSLCertificateFile      /var/lib/puppet/ssl/certs/server.itzgeek.local.pem
        SSLCertificateKeyFile   /var/lib/puppet/ssl/private_keys/server.itzgeek.local.pem
        SSLCertificateChainFile /var/lib/puppet/ssl/ca/ca_crt.pem
        SSLCACertificateFile   /var/lib/puppet/ssl/ca/ca_crt.pem
        # If Apache complains about invalid signatures on the CRL, you can try disabling
        # CRL checking by commenting the next line, but this is not recommended.
        SSLCARevocationFile     /var/lib/puppet/ssl/ca/ca_crl.pem
        # Apache 2.4 introduces the SSLCARevocationCheck directive and sets it to none
        # which effectively disables CRL checking; if you are using Apache 2.4+ you must
        # specify 'SSLCARevocationCheck chain' to actually use the CRL.
        # SSLCARevocationCheck chain
        SSLVerifyClient optional
        SSLVerifyDepth  1
        # The "ExportCertData" option is needed for agent certificate expiration warnings
        SSLOptions +StdEnvVars +ExportCertData

        # This header needs to be set if using a loadbalancer or proxy
        RequestHeader unset X-Forwarded-For

        RequestHeader set X-SSL-Subject %{SSL_CLIENT_S_DN}e
        RequestHeader set X-Client-DN %{SSL_CLIENT_S_DN}e
        RequestHeader set X-Client-Verify %{SSL_CLIENT_VERIFY}e

        DocumentRoot /usr/share/puppet/rack/puppetmasterd/public
        RackBaseURI /
        <Directory /usr/share/puppet/rack/puppetmasterd/>
                Options None
                AllowOverride None
                Order allow,deny
                allow from all
        </Directory>
</VirtualHost>

EOT

fi
################################################################################
#Replacing SSLCertificateFile and SSL CertificateKey file

	sed -i "s?SSLCertificateFile      /var/lib/puppet/ssl/certs/server.itzgeek.local.pem?SSLCertificateFile 	      $(echo $ssl_certificate_file)?g" $puppet_masterd_conf
	sed -i "s?SSLCertificateKeyFile   /var/lib/puppet/ssl/private_keys/server.itzgeek.local.pem?SSLCertificateKeyFile     $(echo $ssl_certificate_key_file)?g" $puppet_masterd_conf

#################################################################################
#Setup puppet File server
auth_file=/etc/puppet/auth.conf
file_server=/etc/puppet/fileserver.conf

        logger "Setting up puppet File Server"
        mkdir /etc/puppet/files
        cp /etc/hosts /etc/puppet/files/
        echo "[files]" >> $file_server #Editing fileserver.conf
        echo "path /etc/puppet/files" >> $file_server #Editing fileserver.conf

        logger "Setting up puppet auth.conf file"
        echo "path /files" >> $auth_file
        echo "auth any"    >> $auth_file
        echo "allow *"     >> $auth_file

##################################################################################
#Setting up manifiest file
manifest_file=/etc/puppet/manifests/site.pp
    logger "creating manifests"

        function create_manifest {
        touch $manifest_file
        echo "node default {"         >> $manifest_file
        echo "package { 'ntp' : ensure => installed, }"  >> $manifest_file
        echo "package { 'sudo' : ensure => installed, }" >> $manifest_file
        echo "package { 'screen' : ensure => installed, }" >> $manifest_file
        echo "package { 'nano' : ensure => installed, }" >> $manifest_file

        echo "service { "ntpd" : ensure => running, enable => true, }"   >> $manifest_file
        echo "service { "puppet" : ensure => running, enable => true, }" >> $manifest_file

        echo "file { '/etc/hosts' :"    >> $manifest_file
        echo "source => 'puppet:///files/hosts',"       >> $manifest_file
        echo "mode => 0644,"            >> $manifest_file
        echo "owner => "root"," >> $manifest_file
        echo "group => "root"," >> $manifest_file
        echo "}"        >> $manifest_file
        echo "}"        >> $manifest_file

}


#Restarting puppet service
cmd1=`systemctl restart  httpd.service`
cmd2=`systemctl disable puppet.service`
cmd3=`systemctl enable httpd.service`

 echo $cmd1 $cmd2 $cmd3

        if [ $? == 0 ]; then
          echo "http service is restarted and enabled"
        fi
	create_manifest
exit

#################################################################################
# Autosign the client certificates

 echo "*" >> /etc/puppet/autosign.conf
