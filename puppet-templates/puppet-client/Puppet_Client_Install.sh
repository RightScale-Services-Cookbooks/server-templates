#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Puppet Client Install
# Description: Installs the Puppet Client and prepares system to access the Puppet Server
# Inputs:
#   PUPPET_SERVER:
#     Category: PUPPET
#     Description: The Puppet Server URL
#     Input Type: single
#     Required: true
#     Advanced: false
#   PUPPET_ROLE:
#     Category: PUPPET
#     Description: The Puppet Server URL
#     Input Type: single
#     Required: true
#     Advanced: false
# Attachments: []
# ...
# Puppet 
set -e
exec 1> >(logger -s -t puppet_install) 2>&1
HOME=/home/rightscale
# Boot-optimized images (pre-cached AMIs) seem to boot up with LANG=US-ASCII
# which causes Puppet to throw all kinds of errors.
#
# https://tickets.puppetlabs.com/browse/PUP-1386
export LANG=en_US.UTF-8

#Set curl opts
curl=$(command -v curl)
curl_opts="--silent --fail --retry 3 --retry-delay 10 --connect-timeout 10 --speed-limit 10240"
if [[ -z "$curl" ]]; then
  echo "Missing curl. Exiting!" && exit 1
fi

if [ ! -e /usr/local/bin/rsc ]; then
  echo "rsc not found, RL10 is a requirement for the chef10 scripts"
  exit 1
fi

instance_data=$(rsc --rl10 cm15 index_instance_session  /api/sessions/instance)
instance_uuid=$(echo "$instance_data" | rsc --x1 '.monitoring_id' json)
export instance_uuid
instance_id=$(echo "$instance_data" | rsc --x1 '.resource_uid' json)
export instance_id
monitoring_server=$(echo "$instance_data" | rsc --x1 '.monitoring_server' json)
region=$(rsc --rl10 --x1 '.name' cm15 show "$(rsc --rl10 --x1 'object:has(.rel:val("cloud")).href' cm15 index_instance_session  /api/sessions/instance)"| awk '{print $2}')
export region
instance_href=$(rsc --rl10 --x1 'object:has(.rel:val("self")).href' cm15 index_instance_session  /api/sessions/instance)
export instance_href

create_tag() {
  self_href=$(rsc --rl10 --x1 'object:has(.rel:val("self")).href' cm15 index_instance_session sessions/instance)
  rsc --rl10 cm15 multi_add /api/tags/multi_add resource_hrefs[]="$self_href" tags[]="$1"
}
#requires observer
# export image_name=$(rsc --rl10 --x1 '.name' cm15 show `rsc --rl10 --x1 'object:has(.rel:val("cloud")).href' cm15 index_instance_session  /api/sessions/instance`| awk '{print $1}')
export daemonsplay='true'
export splaylimit='30'
image_name=$(curl --silent --show-error --retry 3 http://169.254.169.254/latest/meta-data/ami-id)
export image_name
shard=${monitoring_server//tss/us-}
export shard

if [ ! -e /usr/local/bin/puppet ]; then
  $curl "$curl_opts" -k "https://$PUPPET_SERVER:8140/packages/current/install.bash" | sudo bash -s agent:certname="$instance_id" \
agent:splay=$daemonsplay \
extension_requests:pp_instance_id="$instance_id" \
extension_requests:pp_region="$region" \
extension_requests:pp_image_name="$image_name" extension_requests:pp_role="$PUPPET_ROLE"
fi
puppet_agent=$(command -v puppet)
$curl "$curl_opts" -L https://github.com/puppetlabs/puppet-agent-bootstrap/archive/0.2.1.tar.gz -o /tmp/puppet-agent-bootstrap-0.2.1.tar.gz
$puppet_agent module install /tmp/puppet-agent-bootstrap-0.2.1.tar.gz --ignore-dependencies
$puppet_agent agent --enable
$puppet_agent agent --onetime --no-daemonize --no-usecacheonfailure --no-splay
$puppet_agent resource service puppet ensure=running enable=true

create_tag puppet:pp_instance_id="$instance_id"
create_tag puppet:pp_region="$region"
create_tag puppet:pp_role="$PUPPET_ROLE"
create_tag agent:certname="$instance_id"