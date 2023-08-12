# Deploy puppet server
HOSTNAME=$(/bin/hostname)
DOMAIN="gmslab5.local"
FQDN="${HOSTNAME}.${DOMAIN}"
hostnamectl set-hostname $FQDN

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

# Create directory for GitHub and EYAML keys
KEYS_DIR="/root/keys"
/bin/mkdir ${KEYS_DIR}

# Get Puppet EYAML Private Key
URI='https://keyvault-gms.vault.azure.net/secrets/puppet-eyaml-private?api-version=2016-10-01'
OUTPUT="${KEYS_DIR}/private_key.pkcs7.pem"
/bin/curl -s $URI -H "$HEADER" | /bin/python -c "import sys, json; print json.load(sys.stdin)['value']" > $OUTPUT

# Get Puppet EYAML Public Key
URI='https://keyvault-gms.vault.azure.net/secrets/puppet-eyaml-public?api-version=2016-10-01'
OUTPUT="${KEYS_DIR}/public_key.pkcs7.pem"
/bin/curl -s $URI -H "$HEADER" | /bin/python -c "import sys, json; print json.load(sys.stdin)['value']" > $OUTPUT

# Get Github Access Private Key
URI='https://keyvault-gms.vault.azure.net/secrets/id-github-private?api-version=2016-10-01'
OUTPUT="${KEYS_DIR}/id_github"
/bin/curl -s $URI -H "$HEADER" | /bin/python -c "import sys, json; print json.load(sys.stdin)['value']" > $OUTPUT

# Get Github Access Public Key
URI='https://keyvault-gms.vault.azure.net/secrets/id-github-public?api-version=2016-10-01'
OUTPUT="${KEYS_DIR}/id_github.pub"
/bin/curl -s $URI -H "$HEADER" | /bin/python -c "import sys, json; print json.load(sys.stdin)['value']" > $OUTPUT

# Set permissions on key files
/bin/chmod -R 700 ${KEYS_DIR}

# Install Git
/bin/yum install -y git

# Install Docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Puppet Server
/bin/yum install -y  http://yum.puppetlabs.com/puppet7/puppet7-release-el-7.noarch.rpm
/bin/yum install -y puppetserver

# puppet.conf file
/bin/cat >> /etc/puppetlabs/puppet/puppet.conf <<EOF
server = puppet.gmslab5.local
certname = puppet.gmslab5.local
[agent]
server = puppet.gmslab5.local
certname = puppet.gmslab5.local
environment = production
EOF

# Set-up CA
/opt/puppetlabs/bin/puppetserver ca setup

# Start Puppet
/bin/systemctl enable puppetserver
/bin/systemctl start puppetserver

# Puppet DB CLI
/opt/puppetlabs/puppet/bin/gem install --bindir /opt/puppetlabs/bin puppetdb_cli

# CLI Config File
/bin/mkdir -p $HOME/.puppetlabs/client-tools
/bin/cat > $HOME/.puppetlabs/client-tools/puppetdb.conf <<EOF
{
  "puppetdb": {
    "server_urls": "https://puppet.gmslab.local:8081",
    "cacert": "/etc/puppetlabs/puppet/ssl/certs/ca.pem",
    "cert": "/etc/puppetlabs/puppet/ssl/certs/puppet.gmslab.local.pem",
    "key": "/etc/puppetlabs/puppet/ssl/private_keys/puppet.gmslab.local.pem"
  }
}
EOF

# Install EYAML
/opt/puppetlabs/bin/puppetserver gem install hiera-eyaml
/bin/mkdir /etc/eyaml
/bin/cat > /etc/eyaml/config.yaml <<EOF
---
pkcs7_private_key: '/etc/puppetlabs/puppet/eyaml/private_key.pkcs7.pem'
pkcs7_public_key: '/etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem'
EOF

/bin/mkdir /etc/puppetlabs/puppet/eyaml
/bin/cp /root/keys/*_key.pkcs7.pem /etc/puppetlabs/puppet/eyaml/
/bin/chown -R puppet:puppet /etc/puppetlabs/puppet/eyaml
/bin/chmod -R 0500 /etc/puppetlabs/puppet/eyaml
/bin/chmod 0400 /etc/puppetlabs/puppet/eyaml/*.pem

# Install R10K
/opt/puppetlabs/puppet/bin/gem install r10k
/bin/mkdir -p /etc/puppetlabs/r10k
/bin/cat > /etc/puppetlabs/r10k/r10k.yaml <<EOF
# The location to use for storing cached Git repos
:cachedir: '/var/cache/r10k'

# A list of git repositories to create
:sources:
  # This will clone the git repository and instantiate an environment per
  # branch in /etc/puppetlabs/code/environments
  :my-org:
    remote: 'git@github.com:graham-m-smith/puppet-control-repo1.git'
    basedir: '/etc/puppetlabs/code/environments'
EOF

# SSH Github config
/bin/cat >> /root/.ssh/config <<EOF
Host github.com
        Hostname github.com
        IdentityFile /root/keys/id_github
EOF

# github.com host key
/bin/cat >> /root/.ssh/known_hosts <<EOF
github.com,140.82.121.3 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
EOF

# Puppet facts
mkdir -p /opt/gms-puppet/puppet-facts
/bin/cat > /opt/gms-puppet/puppet-facts/puppet.gmslab5.local.yaml <<EOF
server::facts:
  puppet_gmslab5_local:
    testfact1: testvalue2
EOF
chown -R puppet:puppet /opt/gms-puppet

# Deploy Puppet configuration from control repo
/opt/puppetlabs/puppet/bin/r10k deploy environment -v debug --modules

# Install ENC
# /opt/puppetlabs/bin/puppet apply -e "class { 'enc': }"

# Sync to ENC database
# /usr/local/bin/puppetconfig --debug --verbose sync

# Generate facts.yaml file
# /usr/local/bin/puppetconfig --debug --verbose generate

# Run Puppet agent to install PuppetDB
# /opt/puppetlabs/bin/puppet agent -t

# Enable puppet agent service
# /bin/systemctl enable puppet
# /bin/systemctl start puppet

# store reports in puppetdb
/bin/cat >> /etc/puppetlabs/puppet/puppet.conf <<EOF
reports = store,puppetdb
EOF