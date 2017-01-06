#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: RS-Base Install - chef
# Description: 'Installs HAProxy and sets up monitoring for the HAProxy process. '
# Inputs:
#   COLLECTD_SERVER:
#     Category: RightScale
#     Description: If using collectd, the FQDN or IP address of the remote collectd
#       server.
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: env:RS_TSS
#   RS_INSTANCE_UUID:
#     Category: RightScale
#     Description: If using collectd, the monitoring ID for this server.
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: env:RS_INSTANCE_UUID
#   EPHEMERAL_FILESYSTEM:
#     Category: Ephemeral Disk
#     Description: The filesystem to be used on the ephemeral volume. Defaults are based
#       on OS and determined in attributes/defaults.rb.
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:ext4
#   EPHEMERAL_LOGICAL_VOLUME_NAME:
#     Category: Ephemeral Disk
#     Description: The name of the logical volume for ephemeral LVM
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:ephemeral0
#   EPHEMERAL_LOGICAL_VOLUME_SIZE:
#     Category: Ephemeral Disk
#     Description: The size to be used for the ephemeral LVM
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:100%VG
#   EPHEMERAL_MOUNT_POINT:
#     Category: Ephemeral Disk
#     Description: "The mount point for the ephemeral volume\r\n"
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:/mnt/ephemeral
#   EPHEMERAL_STRIPE_SIZE:
#     Category: Ephemeral Disk
#     Description: The stripe size to be used for the ephemeral logical volume
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:512
#   EPHEMERAL_VOLUME_GROUP_NAME:
#     Category: Ephemeral Disk
#     Description: The volume group name for the ephemeral LVM
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:vg-data
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
    "collectd_server": "$COLLECTD_SERVER",
    "collectd_hostname": "$RS_INSTANCE_UUID"
  },
  "run_list": ["recipe[apt]","recipe[rs-base]"]
}
EOF


chef-client -j $chef_dir/chef.json
