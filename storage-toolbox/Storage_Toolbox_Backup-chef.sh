#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Storage Toolbox Backup - chef
# Description: Create a backup of all volumes attached to the server
# Inputs:
#   BACKUP_KEEP_DAILIES:
#     Category: Storage
#     Description: 'Number of daily backups to keep. Example: 14'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:14
#   BACKUP_KEEP_LAST:
#     Category: Storage
#     Description: "Number of snapshots to keep. Example: 60\r\n"
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:60
#   BACKUP_KEEP_MONTHLIES:
#     Category: Storage
#     Description: 'Number of monthly backups to keep. Example: 12'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:12
#   BACKUP_KEEP_WEEKLIES:
#     Category: Storage
#     Description: 'Number of weekly backups to keep. Example: 6'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:14
#   BACKUP_KEEP_YEARLIES:
#     Category: Storage
#     Description: "Number of yearly backups to keep. Example: 2\r\n"
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:2
#   BACKUP_LINEAGE:
#     Category: Storage
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

if [ -e $chef_dir/chef.json ]; then
  rm -f $chef_dir/chef.json
fi

#get instance data to pass to chef server
instance_data=$(rsc --rl10 cm15 index_instance_session  /api/sessions/instance)
instance_uuid=$(echo $instance_data | rsc --x1 '.monitoring_id' json)
instance_id=$(echo $instance_data | rsc --x1 '.resource_uid' json)

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
 "rs-storage": {
  "backup":{
    "lineage":"$BACKUP_LINEAGE",
    "keep":{
    "dailies":"$BACKUP_KEEP_DAILIES",
    "keep_last":"$BACKUP_KEEP_LAST",
    "monthlies":"$BACKUP_KEEP_MONTHLIES",
    "weeklies":"$BACKUP_KEEP_WEEKLIES",
    "yearlies":"$BACKUP_KEEP_YEARLIES"
    }
  }
 },

	"run_list": ["recipe[rs-storage::backup]"]
}
EOF


chef-client --json-attributes $chef_dir/chef.json
