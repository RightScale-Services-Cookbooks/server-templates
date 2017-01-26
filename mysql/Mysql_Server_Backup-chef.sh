#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Mysql Server Backup - chef
# Description: 'Creates a backup '
# Inputs:
#   DEVICE_NICKNAME:
#     Category: Database
#     Description: 'Nickname for the device. rs-mysql::volume uses this for the filesystem
#       label, which is restricted to 12 characters. If longer than 12 characters, the
#       filesystem label will be set to the first 12 characters. Example: data_storage'
#     Input Type: single
#     Required: true
#     Advanced: false
#   DB_BACKUP_KEEP_DAILIES:
#     Category: Database
#     Description: 'Number of daily DB_BACKUPs to keep. Example: 14'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:14
#   DB_BACKUP_KEEP_LAST:
#     Category: Database
#     Description: 'Number of snapshots to keep. Example: 60'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:60
#   DB_BACKUP_KEEP_MONTHLIES:
#     Category: Database
#     Description: 'Number of monthly DB_BACKUPs to keep. Example: 12'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:12
#   DB_BACKUP_KEEP_WEEKLIES:
#     Category: Database
#     Description: 'Number of weekly DB_BACKUPs to keep. Example: 6'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:14
#   DB_BACKUP_KEEP_YEARLIES:
#     Category: Database
#     Description: "Number of yearly DB_BACKUPs to keep. Example: 2\r\n"
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:2
#   DB_BACKUP_LINEAGE:
#     Category: Database
#     Description: The prefix that will be used to name/locate the DB_BACKUP of the
#       MySQL database server.
#     Input Type: single
#     Required: true
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
	"normal": {
		"tags": []
	},

 "rightscale": {
    "instance_uuid":"$instance_uuid",
    "instance_id":"$instance_id"
	},
 "rs-mysql": {
  "device":{"nickname":"$DEVICE_NICKNAME"},
  "DB_BACKUP":{
    "lineage":"$DB_BACKUP_LINEAGE",
    "keep":{
    "dailies":"$DB_BACKUP_KEEP_DAILIES",
    "keep_last":"$DB_BACKUP_KEEP_LAST",
    "monthlies":"$DB_BACKUP_KEEP_MONTHLIES",
    "weeklies":"$DB_BACKUP_KEEP_WEEKLIES",
    "yearlies":"$DB_BACKUP_KEEP_YEARLIES"
    }
  }
 },

	"run_list": ["recipe[rs-mysql::backup]"]
}
EOF


chef-client --json-attributes $chef_dir/chef.json
