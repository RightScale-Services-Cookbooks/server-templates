#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Tomcat Appserver Install - chef
# Description: 'Installs/configures PHP application server '
# Inputs:
#   SCM_DEPLOY_KEY:
#     Category: Tomcat
#     Description: 'The private key to access the repository via SSH. Example: Cred:APP_DEPLOY_KEY'
#     Input Type: single
#     Required: false
#     Advanced: false
#   REFRESH_TOKEN:
#     Category: Rightscale
#     Description: 'The Rightscale OAUTH refresh token.  Example: cred: MY_REFRESH_TOKEN'
#     Input Type: single
#     Required: true
#     Advanced: false
#   TOMCAT_APPLICATION_NAME:
#     Category: Tomcat
#     Input Type: single
#     Required: true
#     Advanced: false
#   TOMCAT_VHOST_PATH:
#     Category: Tomcat
#     Input Type: single
#     Required: true
#     Advanced: false
#   TOMCAT_WAR_PATH:
#     Category: Tomcat
#     Input Type: single
#     Required: true
#     Advanced: false
#   TOMCAT_DATABASE_HOST:
#     Category: Tomcat
#     Input Type: single
#     Required: true
#     Advanced: false
#   TOMCAT_DATABASE_USER:
#     Category: Tomcat
#     Input Type: single
#     Required: true
#     Advanced: false
#   TOMCAT_DATABASE_PASSWORD:
#     Category: Tomcat
#     Input Type: single
#     Required: true
#     Advanced: false
#   TOMCAT_DATABASE_SCHEMA:
#     Category: Tomcat
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

#convert input array to array for json in chef.json below
packages_array=${PACKAGES//,/ }
packages_array=$(echo "$packages_array" | sed -e 's/\(\w*\)/,"\1"/g' | cut -d , -f 2-)

packages_array=''
if [ -n "$packages_array" ];then
  packages_array="\"packages\":[$packages_array]"
fi

#get instance data to pass to chef server
instance_uuid=$(echo $instance_data | /usr/local/bin/rsc --x1 '.monitoring_id' json)
instance_id=$(echo $instance_data | /usr/local/bin/rsc --x1 '.resource_uid' json)
monitoring_server=$(echo $instance_data | /usr/local/bin/rsc --x1 '.monitoring_server' json)
shard=${monitoring_server//tss/us-}

deploy_key=''
if [ -n "$SCM_DEPLOY_KEY" ];then
cat <<EOF>/tmp/deploy_key
$SCM_DEPLOY_KEY
EOF
  deploy_key_output="$(< /tmp/deploy_key | awk 1 ORS='\\n')"
  export deploy_key="\"deploy_key\":\"${deploy_key_output}\","
fi
rm -f /tmp/deploy_key

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
    "instance_uuid": "$instance_uuid",
    "instance_id": "$instance_id",
    "refresh_token": "$REFRESH_TOKEN",
    "api_url": "https://${shard}.rightscale.com",
    "sketchy": "${monitoring_server}.rightscale.com"
  },
  "rsc_tomcat": {
    "application_name": "$TOMCAT_APPLICATION_NAME",
    "vhost_path": "$TOMCAT_VHOST_PATH",
    "war": {
      "path": "$TOMCAT_WAR_PATH"
    },
    "database": {
      "host": "$TOMCAT_DATABASE_HOST",
      "user": "$TOMCAT_DATABASE_USER",
      "password":"$TOMCAT_DATABASE_PASSWORD",
      "schema": "$TOMCAT_DATABASE_SCHEMA"
    }
  },
  "run_list": [
    "recipe[rsc_tomcat]",
    "recipe[rsc_tomcat::tags]"
  ]
}
EOF


chef-client -j $chef_dir/chef.json
