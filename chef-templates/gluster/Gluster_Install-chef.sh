#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Gluster Install - chef
# Description: Sets up repos and installs gluster
# Inputs:
#   REFRESH_TOKEN:
#     Category: RightScale
#     Input Type: single
#     Required: true
#     Advanced: false
#   RSC_GLUSTER_UNIQUE_KEY:
#     Category: GLUSTER
#     Input Type: single
#     Required: true
#     Advanced: false
# Attachments: []
# ...

set -e

HOME=/home/rightscale
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin

/sbin/mkhomedir_helper rightlink

export chef_dir=$HOME/.chef
mkdir -p $chef_dir

#get instance data to pass to chef server
instance_data=$(rsc --rl10 cm15 index_instance_session  /api/sessions/instance)
instance_uuid=$(echo "$instance_data" | rsc --x1 '.monitoring_id' json)
instance_id=$(echo "$instance_data" | rsc --x1 '.resource_uid' json)
monitoring_server=$(echo "$instance_data" | rsc --x1 '.monitoring_server' json)
shard=${monitoring_server//tss/us-}

if [ -e $chef_dir/chef.json ]; then
  rm -f $chef_dir/chef.json
fi
# add the rightscale env variables to the chef runtime attributes
# http://docs.rightscale.com/cm/ref/environment_inputs.html
cat <<EOF> $chef_dir/chef.json
{
  "name": "${HOSTNAME}",
 
  "rightscale":{
    "instance_uuid":"$instance_uuid",
    "instance_id":"$instance_id",
    "refresh_token": "$REFRESH_TOKEN",
    "api_url": "https://${shard}.rightscale.com"
  },
  "build-essential": {
    "compile_time": "true"
  },
  "apt": {
    "compile_time_update": "true"
  },
  "rsc_gluster": {
    "unique": "$RSC_GLUSTER_UNIQUE_KEY"
  }, 
  "run_list": ["recipe[apt]","recipe[ephemeral_lvm]","recipe[rsc_gluster::server]","recipe[rsc_remote_recipe]"]
}
EOF


chef-client -j $chef_dir/chef.json 
