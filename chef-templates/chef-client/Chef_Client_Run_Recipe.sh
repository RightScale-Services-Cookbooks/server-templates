#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Chef Client Run Recipe
# Description: Run recipes from cookbooks on a Chef Server
# Inputs:
#   CHEF_SERVER_RUNLIST:
#     Category: CHEF
#     Description: 'The chef client runlist.  Seperate multiple recipes by commas. Example:
#       recipe[apt],recipe[tomcat::install]'
#     Input Type: single
#     Required: true
#     Advanced: false
# Attachments: []
# ...

set -x
set -e

formatted_runlist="${CHEF_SERVER_RUNLIST//,/\",\"}"

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

# add the rightscale env variables to the chef runtime attributes
# http://docs.rightscale.com/cm/ref/environment_inputs.html
cat <<EOF> $chef_dir/chef.json
{
  "name": "${HOSTNAME}",
  "normal": {

    "tags": [
    ]
  },
  "rightscale":{
    "instance_uuid":"$instance_uuid",
    "instance_id":"$instance_id"
  },

  "run_list": ["$formatted_runlist"]
}
EOF

chef-client --json-attributes $chef_dir/chef.json
