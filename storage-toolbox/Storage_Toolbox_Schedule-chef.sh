#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Storage Toolbox Schedule - chef
# Description: 'Enable/disable periodic backups '
# Inputs:
#   SCHEDULE_ENABLE:
#     Category: Storage
#     Description: Enable or disable periodic backup schedule
#     Input Type: single
#     Required: false
#     Advanced: false
#     Possible Values:
#     - text:true
#     - text:false
#   SCHEDULE_HOUR:
#     Category: Storage
#     Description: 'The hour to schedule the backup on. This value should abide by crontab
#       syntax. Use ''*'' for taking'' + '' backups every hour. Example: 23'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:23
#   SCHEDULE_MINUTE:
#     Category: Storage
#     Description: 'The minute to schedule the backup on. This value should abide by
#       crontab syntax. Example: 30'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:15
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
  "schedule":{
    "enable":"$SCHEDULE_ENABLE",
    "hour":$SCHEDULE_HOUR,
    "minute":$SCHEDULE_MINUTE
  }
	},

	"run_list": ["recipe[rs-storage::schedule]"]
}
EOF


chef-client --json-attributes $chef_dir/chef.json
