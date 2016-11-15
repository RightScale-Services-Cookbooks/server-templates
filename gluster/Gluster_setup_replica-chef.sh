#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Gluster setup replica - chef
# Description: Creates a replica volume across all servers
# Inputs:
#   GLUSTER_BRICK_PATH:
#     Category: GLUSTER
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:/mnt/ephemeral
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
instance_uuid=$(echo $instance_data | rsc --x1 '.monitoring_id' json)
instance_id=$(echo $instance_data | rsc --x1 '.resource_uid' json)
monitoring_server=$(echo $instance_data | rsc --x1 '.monitoring_server' json)
shard=$(echo $monitoring_server | sed -e 's/tss/us-/')

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
    "brick": {
      "path": "$GLUSTER_BRICK_PATH"
     },
    "unique": "$RSC_GLUSTER_UNIQUE_KEY"
   },
  "run_list": ["recipe[apt]","recipe[rsc_remote_recipe]","recipe[rsc_gluster::server-peer-probe]","recipe[rsc_gluster::setup-replica]"]
}
EOF


chef-client -j $chef_dir/chef.json 
