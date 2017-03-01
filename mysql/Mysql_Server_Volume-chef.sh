#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Mysql Server Volume - chef
# Description: 'Creates a volume, attaches it to the server, and moves the MySQL data
#   to the volume '
# Inputs:
#   DEVICE_IOPS:
#     Category: Database
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
#     Category: Database
#     Description: 'Nickname for the device. rs-mysql::volume uses this for the filesystem
#       label, which is restricted to 12 characters. If longer than 12 characters, the
#       filesystem label will be set to the first 12 characters. Example: data_storage'
#     Input Type: single
#     Required: true
#     Advanced: false
#   DEVICE_VOLUME_SIZE:
#     Category: Database
#     Description: 'Size of the volume or logical volume to create (in GB). Example:
#       10'
#     Input Type: single
#     Required: true
#     Advanced: false
#   DEVICE_VOLUME_TYPE:
#     Category: Database
#     Description: 'Volume Type to use for creating volumes. Example: gp2'
#     Input Type: single
#     Required: false
#     Advanced: false
#   DEVICE_FILESYSTEM:
#     Category: Database
#     Description: 'The filesystem to be used on the device. Defaults are based on OS
#       and determined in attributes/volume.rb. Example: ext4'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:ext4
#   DB_RESTORE_LINEAGE:
#     Category: Database
#     Description: 'The lineage name to restore backups. Example: staging'
#     Input Type: single
#     Required: false
#     Advanced: false
#   DB_RESTORE_TIMESTAMP:
#     Category: Database
#     Description: "The timestamp (in seconds since UNIX epoch) to select a backup to
#       restore from. The backup selected will have been created on or before this timestamp.
#       Example: 1391473172\r\n"
#     Input Type: single
#     Required: false
#     Advanced: false
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
instance_uuid=$(echo $instance_data | /usr/local/bin/rsc --x1 '.monitoring_id' json)
instance_id=$(echo $instance_data | /usr/local/bin/rsc --x1 '.resource_uid' json)


device_iops=''
if [ -n "${DEVICE_IOPS:-$((DEVICE_VOLUME_SIZE*3))}" ];then
  device_iops="\"iops\":\"$DEVICE_IOPS\","
fi

volume_type=''
if [ -n "${DEVICE_VOLUME_TYPE:-gp2}" ];then
  volume_type="\"volume_type\":\"$DEVICE_VOLUME_TYPE\","
fi

device_filesystem=''
if [ -n "${DEVICE_FILESYSTEM:-ext4}" ];then
  device_filesystem="\"filesystem\":\"$DEVICE_FILESYSTEM\","
fi

restore_lineage=''
if [ -n "$DB_RESTORE_LINEAGE" ];then
comma=''
  if [ -n "$DB_RESTORE_TIMESTAMP" ];then
   comma=","
  fi
  restore_lineage="\"lineage\":\"$DB_RESTORE_LINEAGE\"$comma"
fi

restore_timestamp=''
if [ -n "$DB_RESTORE_TIMESTAMP" ];then
  restore_timestamp="\"timestamp\":\"$DB_RESTORE_TIMESTAMP\""
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

	"rs-mysql": {
   "device":{
     $device_filesystem
     $device_iops
     "mount_point":"$DEVICE_MOUNT_POINT",
     "nickname":"$DEVICE_NICKNAME",
     $volume_type
     "volume_size":"$DEVICE_VOLUME_SIZE"
   },
   "restore":{
     $restore_lineage
     $restore_timestamp
   }

	},

	"run_list": ["recipe[rs-mysql::volume]"]
}
EOF


chef-client --json-attributes $chef_dir/chef.json
