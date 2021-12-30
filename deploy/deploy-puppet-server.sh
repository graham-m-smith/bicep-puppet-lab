# Deploy puppet server
HOSTNAME=$(/bin/hostname)
hostnamectl set-hostname ${HOSTNAME}.gmslab.local

# Get Access Token for Key Vault Access
export PYTHONIOENCODING=utf8
ACCESS_TOKEN_URI='http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net'
HEADER="Metadata:true"
ACCESS_TOKEN=$(/bin/curl -s ${ACCESS_TOKEN_URI} -H $HEADER | /bin/python -c "import sys, json; print json.load(sys.stdin)['access_token']" )

# Set Authorization Header
HEADER="Authorization: Bearer $ACCESS_TOKEN"

# Create directory for keys
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
yum install -y git > /tmp/puppet_server_config.log 2>&1

# Install Puppet Server
yum install -y  http://yum.puppetlabs.com/puppet7/puppet7-release-el-7.noarch.rpm >> /tmp/puppet_server_config.log 2>&1
yum install -y puppetserver >> /tmp/puppet_server_config.log 2>&1

# puppet.conf file
cat >> /etc/puppetlabs/puppet/puppet.conf <<EOF
server = puppet.gmslab.local
certname = puppet.gmslab.local
[agent]
server = puppet.gmslab.local
certname = puppet.gmslab.local
environment = production
EOF

# Set-up CA
/opt/puppetlabs/bin/puppetserver ca setup >> /tmp/puppet_server_config.log 2>&1

# Start Puppet
systemctl enable puppetserver >> /tmp/puppet_server_config.log 2>&1
systemctl start puppetserver >> /tmp/puppet_server_config.log 2>&1

# Puppet DB CLI
/opt/puppetlabs/puppet/bin/gem install --bindir /opt/puppetlabs/bin puppetdb_cli RU>> /tmp/puppet_server_config.log 2>&1

# CLI Config File
mkdir -p $HOME/.puppetlabs/client-tools >> /tmp/puppet_server_config.log 2>&1
cat > $HOME/.puppetlabs/client-tools/puppetdb.conf <<EOF
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
/opt/puppetlabs/bin/puppetserver gem install hiera-eyaml >> /tmp/puppet_server_config.log 2>&1
mkdir /etc/eyaml >> /tmp/puppet_server_config.log 2>&1
cat > /etc/eyaml/config.yaml <<EOF
---
pkcs7_private_key: '/etc/puppetlabs/puppet/eyaml/private_key.pkcs7.pem'
pkcs7_public_key: '/etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem'
EOF

mkdir /etc/puppetlabs/puppet/eyaml >> /tmp/puppet_server_config.log 2>&1
cp /root/keys/*_key.pkcs7.pem /etc/puppetlabs/puppet/eyaml/ >> /tmp/puppet_server_config.log 2>&1
chown -R puppet:puppet /etc/puppetlabs/puppet/eyaml >> /tmp/puppet_server_config.log 2>&1
chmod -R 0500 /etc/puppetlabs/puppet/eyaml >> /tmp/puppet_server_config.log 2>&1
chmod 0400 /etc/puppetlabs/puppet/eyaml/*.pem >> /tmp/puppet_server_config.log 2>&1

# Install R10K
/opt/puppetlabs/puppet/bin/gem install r10k >> /tmp/puppet_server_config.log 2>&1
mkdir -p /etc/puppetlabs/r10k >> /tmp/puppet_server_config.log 2>&1
cat > /etc/puppetlabs/r10k/r10k.yaml <<EOF
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
cat >> $HOME/.ssh/config <<EOF
Host github.com
        Hostname github.com
        IdentityFile /root/keys/id_github
EOF

# github.com host key
cat >> $HOME/.ssh/known_hosts <<EOF
github.com,140.82.121.3 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
EOF

# Deploy Puppet configuration from control repo
/opt/puppetlabs/puppet/bin/r10k deploy environment -v debug --modules  >> /tmp/puppet_server_config.log 2>&1
