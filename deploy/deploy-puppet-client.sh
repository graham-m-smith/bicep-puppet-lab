# Deploy puppet client
HOSTNAME=$(/bin/hostname)
hostnamectl set-hostname ${HOSTNAME}.gmslab.local

yum install -y http://yum.puppetlabs.com/puppet7/puppet7-release-el-7.noarch.rpm
yum install -y puppet-agent

cat >> /etc/puppetlabs/puppet/puppet.conf << EOF
server = puppetserver.gmslab.local
certname = ${HOSTNAME}.gmslab.local
environment = production
EOF

systemctl enable puppet
systemctl start puppet
systemctl status puppet
