# Deploy puppet server
HOSTNAME=$(/bin/hostname)
hostnamectl set-hostname ${HOSTNAME}.gmslab.local

yum install -y http://yum.puppetlabs.com/puppet7/puppet7-release-el-7.noarch.rpm
yum install -y puppetserver

