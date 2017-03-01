#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: MongoDB Add To Replicaset-chef
# Description: 'Adds mongo instance to replicaset'
# Inputs:
#   MONGO_REPLICASET:
#     Category: MongoDB
#     Description: MongoDB ReplicaSet Name.
#     Input Type: single
#     Required: true
#     Advanced: false
#   MONGO_USE_STORAGE:
#     Category: MongoDB
#     Description: Enables the use of volumes for the Mongodb data store
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:false
#   MONGO_VOLUME_NICKNAME:
#     Category: MongoDB
#     Description: Name of the Volume.
#     Input Type: single
#     Required: true
#     Advanced: false
#   MONGO_VOLUME_SIZE:
#     Category: MongoDB
#     Description: Size of the Mongo Volume.
#     Input Type: single
#     Required: true
#     Advanced: false
#   MONGO_VOLUME_FILESYSTEM:
#     Category: MongoDB
#     Description: Mongo Volume FileSystem.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:ext4
#   MONGO_VOLUME_MOUNT_POINT:
#     Category: MongoDB
#     Description: MongoDB ReplicaSet Name.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:/var/lib/mongodb
#   MONGO_BACKUP_LINEAGE_NAME:
#     Category: MongoDB
#     Description: MongoDB ReplicaSet Name.
#     Input Type: single
#     Required: true
#     Advanced: false
#   MONGO_RESTORE_FROM_BACKUP:
#     Category: MongoDB
#     Description: MongoDB ReplicaSet Name.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:false
#   MONGO_RESTORE_LINEAGE_NAME:
#     Category: MongoDB
#     Description: MongoDB ReplicaSet Name.
#     Input Type: single
#     Required: true
#     Advanced: false
#   MONGO_KEYFILE:
#     Category: MongoDB
#     Description: KeyFile
#     Input Type: single
#     Required: true
#     Advanced: false
#   MONGO_USER:
#     Category: MongoDB
#     Description: MongoDB User.
#     Input Type: single
#     Required: true
#     Advanced: false
#   MONGO_PASSWORD:
#     Category: MongoDB
#     Description: MongoDB Password.
#     Input Type: single
#     Required: true
#     Advanced: false
# Attachments: []
# ...

set -e

cat > /tmp/cert <<-EOF
$MONGO_KEYFILE
EOF
key_output="$(< /tmp/cert awk 1 ORS='\\n')"

HOME=/home/rightscale
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin

/sbin/mkhomedir_helper rightlink

export chef_dir=$HOME/.chef
mkdir -p $chef_dir

#get instance data to pass to chef server
instance_data=$(/usr/local/bin/rsc --rl10 cm15 index_instance_session  /api/sessions/instance)
instance_uuid=$(echo "$instance_data" | /usr/local/bin/rsc --x1 '.monitoring_id' json)
instance_id=$(echo "$instance_data" | /usr/local/bin/rsc --x1 '.resource_uid' json)
monitoring_server=$(echo "$instance_data" | /usr/local/bin/rsc --x1 '.monitoring_server' json)

if [ -e $chef_dir/chef.json ]; then
  rm -f $chef_dir/chef.json
fi

# add the rightscale env variables to the chef runtime attributes
# http://docs.rightscale.com/cm/ref/environment_inputs.html
cat > $chef_dir/chef.json <<-EOF
{
  "name": "${HOSTNAME}",
  "rightscale":{
    "instance_uuid":"$instance_uuid",
    "instance_id":"$instance_id"
  },
  "apt": {
    "compile_time_update": "true"
  },
  "rs-base": {
    "collectd_server": "$monitoring_server",
    "collectd_hostname": "$instance_uuid"
  },
  "mongodb": {
    "key_file_content": "${key_output}"
  },
  "rsc_mongodb": {
    "replicaset":"$MONGO_REPLICASET",
    "use_storage":"$MONGO_USE_STORAGE",
    "volume_nickname":"$MONGO_VOLUME_NICKNAME",
    "volume_size":"$MONGO_VOLUME_SIZE",
    "volume_filesystem":"$MONGO_VOLUME_FILESYSTEM",
    "volume_mount_point":"$MONGO_VOLUME_MOUNT_POINT",
    "backup_lineage_name":"$MONGO_BACKUP_LINEAGE_NAME",
    "restore_from_backup":"$MONGO_RESTORE_FROM_BACKUP",
    "user":"$MONGO_USER",
    "password":"$MONGO_PASSWORD",
    "restore_lineage_name":"$MONGO_RESTORE_LINEAGE_NAME"
  },
  "run_list": ["recipe[apt]","recipe[rsc_mongodb::add_to_replicaset]"]
}
EOF

chef-client -j $chef_dir/chef.json
