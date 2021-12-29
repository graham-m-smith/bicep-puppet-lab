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
/bin/curl -s $URI -H $HEADER | /bin/python -c "import sys, json; print json.load(sys.stdin)['access_token']" > $OUTPUT

# Get Puppet EYAML Public Key
URI='https://keyvault-gms.vault.azure.net/secrets/puppet-eyaml-public?api-version=2016-10-01'
OUTPUT="${KEYS_DIR}/public_key.pkcs7.pem"
/bin/curl -s $URI -H $HEADER | /bin/python -c "import sys, json; print json.load(sys.stdin)['access_token']" > $OUTPUT

# Get Github Access Private Key
URI='https://keyvault-gms.vault.azure.net/secrets/id-github-private?api-version=2016-10-01'
OUTPUT="${KEYS_DIR}/id_github"
/bin/curl -s $URI -H $HEADER | /bin/python -c "import sys, json; print json.load(sys.stdin)['access_token']" > $OUTPUT

# Get Github Access Public Key
URI='https://keyvault-gms.vault.azure.net/secrets/id-github-public?api-version=2016-10-01'
OUTPUT="${KEYS_DIR}/id_github.pub"
/bin/curl -s $URI -H $HEADER | /bin/python -c "import sys, json; print json.load(sys.stdin)['access_token']" > $OUTPUT

# Set permissions on key files
/bin/chmod -R 700 ${KEYS_DIR}
#yum update -y

#yum install git -y
#git config --global credential.helper store

#yum install -y http://yum.puppetlabs.com/puppet7/puppet7-release-el-7.noarch.rpm
#yum install -y puppetserver

