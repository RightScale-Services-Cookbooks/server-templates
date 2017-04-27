#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Storage Toolbox Volume - chef
# Description: 'Creates a volume and attaches it to the server '
# Inputs:
#   DEVICE_IOPS:
#     Category: Storage
#     Description: 'IO Operations Per Second to use for the device. Currently this value
#       is only used on AWS clouds. Example: 100'
#     Input Type: single
#     Required: false
#     Advanced: false
#   DEVICE_MOUNT_POINT:
#     Category: Database
#     Description: 'The mount point to mount the device on. Example: /mnt/storage'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:/mnt/storage
#   DEVICE_NICKNAME:
#     Category: Storage
#     Description: 'Nickname for the device. rs-storage::volume uses this for the filesystem
#       label, which is restricted to 12 characters. If longer than 12 characters, the
#       filesystem label will be set to the first 12 characters. Example: data_storage'
#     Input Type: single
#     Required: true
#     Advanced: false
#   DEVICE_VOLUME_SIZE:
#     Category: Storage
#     Description: "Size of the volume or logical volume to create (in GB). Example:
#       10\r\n"
#     Input Type: single
#     Required: true
#     Advanced: false
#   DEVICE_VOLUME_TYPE:
#     Category: Storage
#     Description: "Volume Type to use for creating volumes. Example: gp2\r\n"
#     Input Type: single
#     Required: false
#     Advanced: false
#   STOR_RESTORE_LINEAGE:
#     Category: Storage
#     Description: 'The lineage name to restore backups. Example: staging'
#     Input Type: single
#     Required: false
#     Advanced: false
#   STOR_RESTORE_TIMESTAMP:
#     Category: Storage
#     Description: 'The timestamp (in seconds since UNIX epoch) to select a backup to
#       restore from. The backup selected will have been created on or before this timestamp.
#       Example: 1391473172'
#     Input Type: single
#     Required: false
#     Advanced: false
#   DEVICE_FILESYSTEM:
#     Category: Storage
#     Description: 'The filesystem to be used on the device. Defaults are based on OS
#       and determined in attributes/defaults.rb. Example: ext4'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:ext4
# Attachments: []
# ...

set -e

HOME=/home/rightscale
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin

/sbin/mkhomedir_helper rightlink

export chef_dir=$HOME/.chef
mkdir -p $chef_dir

if [ -e $chef_dir/chef.json ]; then
  rm -f $chef_dir/chef.json
fi

#get instance data to pass to chef server
instance_data=$(/usr/local/bin/rsc --rl10 cm15 index_instance_session  /api/sessions/instance)
instance_uuid=$(echo $instance_data | /usr/local/bin/rsc --x1 '.monitoring_id' json)
instance_id=$(echo $instance_data | /usr/local/bin/rsc --x1 '.resource_uid' json)

device_iops=''
if [ -n "$DEVICE_IOPS" ];then
  device_iops="\"iops\":\"$DEVICE_IOPS\","
fi

device_volume_type=''
if [ -n "$DEVICE_VOLUME_TYPE" ];then
  device_volume_type="\"volume_type\":\"$DEVICE_VOLUME_TYPE\","
fi

device_filesystem=''
if [ -n "$DEVICE_FILESYSTEM" ];then
  device_filesystem="\"filesystem\":\"$DEVICE_FILESYSTEM\","
fi

restore_lineage=''
if [ -n "$STOR_RESTORE_LINEAGE" ];then
comma=''
  if [ -n "$STOR_RESTORE_LINEAGE" ];then
   comma=","
  fi
  restore_lineage="\"lineage\":\"$STOR_RESTORE_LINEAGE\"$comma"
fi

restore_timestamp=''
if [ -n "$STOR_RESTORE_LINEAGE" ];then
  restore_timestamp="\"timestamp\":\"$STOR_RESTORE_LINEAGE\""
fi

if [ -e $chef_dir/chef.json ]; then
  rm -f $chef_dir/chef.json
fi
# add the rightscale env variables to the chef runtime attributes
# http://docs.rightscale.com/cm/ref/environment_inputs.html
cat <<EOF> $chef_dir/chef.json
{
	"name": "${HOSTNAME}",
	"normal": {
		"tags": []
	},
 
 "apt":{"compile_time_update":"true"},
 "build-essential":{"compile_time":"true"},

 "rightscale": {
    "instance_uuid":"$instance_uuid",
    "instance_id":"$instance_id"
	},

	"rs-storage": {
   "device":{
     $device_filesystem
     $device_iops
     "mount_point":"$DEVICE_MOUNT_POINT",
     "nickname":"$DEVICE_NICKNAME",
     $device_volume_type
     "volume_size":"$DEVICE_VOLUME_SIZE"
   },
   "restore":{
     $restore_lineage
     $restore_timestamp
   }

	},

	"run_list": ["recipe[apt]","recipe[build-essential]",
 "recipe[rs-storage::default]","recipe[rs-storage::volume]"]
}
EOF

chef-client --json-attributes $chef_dir/chef.json
