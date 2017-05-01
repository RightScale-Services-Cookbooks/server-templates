#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Storage Toolbox Stripe - chef
# Description: Creates volumes, attaches them to the server, and sets up a striped LVM
# Inputs:
#   DEVICE_IOPS:
#     Category: Storage
#     Description: 'IO Operations Per Second to use for the device. Currently this value
#       is only used on AWS clouds. Example: 100'
#     Input Type: single
#     Required: false
#     Advanced: false
#   DEVICE_MOUNT_POINT:
#     Category: Storage
#     Description: 'The mount point to mount the device on. Example: /mnt/storage'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:/mnt/storage
#   DEVICE_VOLUME_SIZE:
#     Category: Storage
#     Description: 'Size of the volume or logical volume to create (in GB). Example:
#       10'
#     Input Type: single
#     Required: true
#     Advanced: false
#   DEVICE_VOLUME_TYPE:
#     Category: Storage
#     Description: 'Volume Type to use for creating volumes. Example: gp2'
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
#   DEVICE_COUNT:
#     Category: Storage
#     Description: "The number of devices to create and use in the Logical Volume. If
#       this value is set to more than 1, it will create the specified number of devices
#       and create an LVM on the devices.\r\n"
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:2
#   DEVICE_NICKNAME:
#     Category: Storage
#     Description: 'Nickname for the device. rs-storage::volume uses this for the filesystem
#       label, which is restricted to 12 characters. If longer than 12 characters, the
#       filesystem label will be set to the first 12 characters. Example: data_storage'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:data_storage
# Attachments: []
# ...

set -e

HOME=/home/rightscale
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin

sudo /sbin/mkhomedir_helper rightlink

export chef_dir=$HOME/.chef
mkdir -p $chef_dir

if [ -e $chef_dir/chef.json ]; then
  rm -f $chef_dir/chef.json
fi

#get instance data to pass to chef server
instance_data=$(/usr/local/bin/rsc --rl10 cm15 index_instance_session  /api/sessions/instance)
instance_uuid=$(echo "$instance_data" | /usr/local/bin/rsc --x1 '.monitoring_id' json)
instance_id=$(echo "$instance_data" | /usr/local/bin/rsc --x1 '.resource_uid' json)

device_iops=''
if [ -n "${DEVICE_IOPS:-$((DEVICE_VOLUME_SIZE*3))}" ];then
  device_iops="\"iops\":\"$DEVICE_IOPS\","
fi

device_filesystem=''
if [ -n "${DEVICE_FILESYSTEM:-ext4}" ];then
  device_filesystem="\"filesystem\":\"$DEVICE_FILESYSTEM\","
fi
device_volume_type=''
if [ -n "${DEVICE_VOLUME_TYPE:-gp2}" ];then
  device_volume_type="\"volume_type\":\"$DEVICE_VOLUME_TYPE\""
fi

restore_lineage=''
if [ -n "$STOR_RESTORE_LINEAGE" ];then
  restore_lineage="\"lineage\":\"$STOR_RESTORE_LINEAGE\"$comma"
fi

restore_timestamp=''
comma=""
if [ -n "$STOR_RESTORE_TIMESTAMP" ];then
  comma=","
  restore_timestamp="\"timestamp\":\"$STOR_RESTORE_TIMESTAMP\""
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

 "rightscale": {
    "instance_uuid":"$instance_uuid",
    "instance_id":"$instance_id"
	},
 "apt":{"compile_time_update":"true"},
 "build-essential":{"compile_time":"true"},
 "rs-storage": {
   "device":{
     "count":"$DEVICE_COUNT",
     $device_filesystem
     $device_iops
     $device_volume_type
     "mount_point":"$DEVICE_MOUNT_POINT",
     "nickname":"$DEVICE_NICKNAME",
     "volume_size":"$DEVICE_VOLUME_SIZE"

   },
   "restore":{
     $restore_lineage$comma
     $restore_timestamp
   }

	},

	"run_list": ["recipe[apt]","recipe[build-essential]",
 "recipe[rs-storage::default]","recipe[rs-storage::stripe]"]
}
EOF


chef-client --json-attributes $chef_dir/chef.json
