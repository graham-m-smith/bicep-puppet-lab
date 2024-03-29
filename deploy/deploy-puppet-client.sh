echo "" > /tmp/puppet_client_install.log

# Set FQDN
HOSTNAME=$(/bin/hostname)
hostnamectl set-hostname ${HOSTNAME}.gmslab5.local 

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
/bin/yum-config-manager --add-repo https://pkgs.tailscale.com/stable/centos/7/tailscale.repo 
/bin/yum install tailscale -y 
/bin/systemctl enable --now tailscaled 
/bin/tailscale up --authkey $AUTH_KEY 
/bin/tailscale ip -4 

# Install Puppet Agent
/bin/yum install -y http://yum.puppetlabs.com/puppet7/puppet7-release-el-7.noarch.rpm
/bin/yum install puppet-agent -y

yum install https://yum.puppetlabs.com/puppet7/el/9/x86_64/puppet7-release-7.0.0-14.el9.noarch.rpm

/bin/cat >> /etc/puppetlabs/puppet/puppet.conf << EOF
server = puppet.gmslab5.local
certname = puppetlab5alma2.gmslab5.local
environment = production
EOF
