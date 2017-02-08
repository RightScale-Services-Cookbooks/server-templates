#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: MongoDB Install - chef
# Description: 'Installs MongoDB'
# Inputs:
#   MONGO_REPLICASET:
#     Category: MongoDB
#     Description: MongoDB ReplicaSet Name.
#     Input Type: single
#     Required: true
#     Advanced: false
# Attachments: []
# ...

#   MONGO_USE_STORAGE:
#   MONGO_VOLUME_NICKNAME:
#   MONGO_VOLUME_SIZE:
#   MONGO_VOLUME_FILESYSTEM:
#   MONGO_VOLUME_MOUNT_POINT:
#   MONGO_BACKUP_LINEAGE_NAME:
#   MONGO_RESTORE_FROM_BACKUP:
#   MONGO_RESTORE_LINEAGE_NAME:


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
    "instance_id":"$instance_id"
  },
  "apt": {
    "compile_time_update": "true"
  },
  "ephemeral_lvm":{
    "filesystem":"$EPHEMERAL_FILESYSTEM",
    "logical_volume_name":"$EPHEMERAL_LOGICAL_VOLUME_NAME",
    "logical_volume_size":"$EPHEMERAL_LOGICAL_VOLUME_SIZE",
    "mount_point":"$EPHEMERAL_MOUNT_POINT",
    "stripe_size":"$EPHEMERAL_STRIPE_SIZE",
    "volume_group_name":"$EPHEMERAL_VOLUME_GROUP_NAME"
  },
  "rs-base": {
    "collectd_server": "$monitoring_server",
    "collectd_hostname": "$instance_uuid"
  },
  "run_list": ["recipe[apt]","recipe[rsc_mongodb]"]
}
EOF


chef-client -j $chef_dir/chef.json
