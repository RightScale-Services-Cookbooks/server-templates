#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Chef Client Install
# Description: Installs the Chef Client and prepares system to access the Chef Server
# Inputs:
#   CHEF_VALIDATION_KEY:
#     Category: CHEF
#     Description: 'The Chef Server Validation Key.  '
#     Input Type: single
#     Required: true
#     Advanced: false
#   CHEF_SERVER_URL:
#     Category: CHEF
#     Description: The Chef Server URL
#     Input Type: single
#     Required: true
#     Advanced: false
#   CHEF_VALIDATION_NAME:
#     Category: CHEF
#     Description: The Chef Server Validation Name
#     Input Type: single
#     Required: true
#     Advanced: false
#   CHEF_SERVER_SSL_CERT:
#     Category: CHEF
#     Description: The Chef Server SSL Certificate.  Use knife ssl fetch to retrieve
#       the ssl cert.
#     Input Type: single
#     Required: true
#     Advanced: false
#   LOG_LEVEL:
#     Category: CHEF
#     Description: 'The level of logging to be stored in a log file. Possible levels:
#       :auto (default), :debug, :info, :warn, :error, or :fatal. '
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text::info
#     Possible Values:
#     - text::auto
#     - text::debug
#     - text::info
#     - text::warn
#     - text::error
#     - text::fatal
#   CHEF_ENVIRONMENT:
#     Category: CHEF
#     Description: The name of the Chef environment.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:_default
#   VERSION:
#     Category: CHEF
#     Description: 'Version of chef client to install.  Example: 12.16'
#     Input Type: single
#     Required: true
#     Advanced: false
#   CHEF_SSL_VERIFY_MODE:
#     Category: CHEF
#     Description: 'Set the verify mode for HTTPS requests. Use :verify_none to do no validation of SSL certificates. Use :verify_peer to do validation of 
#         all SSL certificates, including the Chef server connections, S3 connections, and any HTTPS remote_file resource URLs used in the chef-client run. 
#         This is the recommended setting. Depending on how OpenSSL is configured, the ssl_ca_path may need to be specified. Default value: :verify_peer.'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default:  text::verify_peer
#     Possible Values:
#     - text::verify_peer
#     - text::verify_none
# ...

set -e

HOME=/home/rightscale

version="-v ${VERSION:-latest}"

if [ ! -e /usr/bin/chef-client ]; then
  curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- "$version"
fi

/sbin/mkhomedir_helper rightlink
export chef_dir=/etc/chef
mkdir -p $chef_dir

cat > $chef_dir/validation.pem <<-EOF
$CHEF_VALIDATION_KEY
EOF

if [ -e $chef_dir/client.rb ]; then
  rm -fr $chef_dir/client.rb
fi

#allow ohai to work for the clouds
if dmidecode | grep -q amazon; then
 mkdir -p /etc/chef/ohai/hints && touch "${_}/ec2.json"
fi

if dmidecode | grep -q google; then
 mkdir -p /etc/chef/ohai/hints && touch "${_}/gce.json"
fi

if dmidecode | grep -q 'Microsoft Corporation'; then
 mkdir -p /etc/chef/ohai/hints
 cat > /etc/chef/ohai/hints/azure.json <<-EOF
{
  "private_ip": "$PRIVATE_IP"
}
EOF
fi

if [ ! -e /usr/local/bin/rsc ]; then
  echo "rsc not found, RL10 is a requirement for the chef10 scripts"
  exit 1
fi

cat > $chef_dir/client.rb <<-EOF
log_level              $LOG_LEVEL
log_location           '/var/log/chef.log'
chef_server_url        "$CHEF_SERVER_URL"
validation_client_name "$CHEF_VALIDATION_NAME"
node_name              "${HOSTNAME}"
cookbook_path          "/var/chef/cache/cookbooks/"
validation_key         "$chef_dir/validation.pem"
environment            "$CHEF_ENVIRONMENT"
ssl_verify_mode        $CHEF_SSL_VERIFY_MODE
EOF

mkdir -p $chef_dir/trusted_certs
#get this by knife ssl fetch
/usr/bin/knife ssl fetch -c "$chef_dir/client.rb"

# test config and register node.
/usr/bin/chef-client
