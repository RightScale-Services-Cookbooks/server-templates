#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Mysql Server Decommission - chef
# Description: 'Destroys LVM conditionally, detaches and destroys volumes. This recipe
#   should be used as a decommission recipe in a RightScale ServerTemplate. '
# Inputs:
#   DEVICE_COUNT:
#     Category: Database
#     Description: The number of devices to create and use in the Logical Volume. If
#       this value is set to more than 1, it will create the specified number of devices
#       and create an LVM on the devices.
#     Input Type: single
#     Required: true
#     Advanced: false
#   DEVICE_DESTROY_ON_DECOMMISSION:
#     Category: Database
#     Description: If set to true, the devices will be destroyed on decommission.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:false
#     Possible Values:
#     - text:true
#     - text:false
#   DEVICE_MOUNT_POINT:
#     Category: Database
#     Description: 'The mount point to mount the device on. Example: /mnt/storage'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:/mnt/storage
#   DEVICE_NICKNAME:
#     Category: Database
#     Description: "Nickname for the device. rs-mysql::volume uses this for the filesystem
#       label, which is restricted to 12 characters. If longer than 12 characters, the
#       filesystem label will be set to the first 12 characters. Example: data_storage\r\n"
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:data_storage
# Attachments: []
# ...

set -e

HOME=/home/rightscale

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
    "instance_id":"$instance_id",
    "decom_reason":"${DECOM_REASON}"
 },

 "rs-mysql": {
  "device":{
  "count":"$DEVICE_COUNT",
  "destroy_on_decommission":"$DEVICE_DESTROY_ON_DECOMMISSION",
  "mount_point":"$DEVICE_MOUNT_POINT",
  "nickname":"$DEVICE_NICKNAME"
  }
 },

 "run_list": ["recipe[rs-mysql::decommission]"]
}
EOF


chef-client --json-attributes $chef_dir/chef.json
