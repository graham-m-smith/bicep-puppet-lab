echo "" > /tmp/puppet_client_install.log

# Set FQDN
HOSTNAME=$(/bin/hostname)
hostnamectl set-hostname ${HOSTNAME}.gmslab.local >> /tmp/puppet_client_install.log 2>&1

# Get Access Token for Key Vault Access
export PYTHONIOENCODING=utf8
ACCESS_TOKEN_URI='http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net'
HEADER="Metadata:true"
ACCESS_TOKEN=$(/bin/curl -s ${ACCESS_TOKEN_URI} -H $HEADER | /bin/python -c "import sys, json; print json.load(sys.stdin)['access_token']" )

# Set Authorization Header
HEADER="Authorization: Bearer $ACCESS_TOKEN"

# Get TailScale Auth Key
URI='https://keyvault-gms.vault.azure.net/secrets/TailscaleAuthKey?api-version=2016-10-01'
AUTH_KEY=$(/bin/curl -s $URI -H "$HEADER" | /bin/python -c "import sys, json; print json.load(sys.stdin)['value']")

# Install TailScale
/bin/yum-config-manager --add-repo https://pkgs.tailscale.com/stable/centos/7/tailscale.repo >> /tmp/puppet_client_install.log 2>&1
/bin/yum install tailscale -y >> /tmp/puppet_client_install.log 2>&1
/bin/systemctl enable --now tailscaled >> /tmp/puppet_client_install.log 2>&1
/bin/tailscale up --authkey $AUTH_KEY >> /tmp/puppet_client_install.log 2>&1
/bin/tailscale ip -4 >> /tmp/puppet_client_install.log 2>&1

# Install Puppet Agent
/bin/yum install -y http://yum.puppetlabs.com/puppet7/puppet7-release-el-7.noarch.rpm
/bin/yum install puppet-agent -y

/bin/cat >> /etc/puppetlabs/puppet/puppet.conf << EOF
server = puppet.gmslab.local
certname = ${HOSTNAME}
environment = production
EOF
