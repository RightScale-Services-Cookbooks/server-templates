#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Mysql Server Master - chef
# Description: 'Sets up a MySQL master server '
# Inputs:
#   BIND_NETWORK_INTERFACE:
#     Category: Database
#     Description: The network interface to use for MySQL bind. It can be either 'private'
#       or 'public' interface.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:private
#     Possible Values:
#     - text:private
#     - text:public
#   DNS_MASTER_FQDN:
#     Category: Database
#     Description: The fully qualified domain name of the MySQL master database server.
#     Input Type: single
#     Required: true
#     Advanced: false
#   DNS_SECRET_KEY:
#     Category: Database
#     Description: The secret key to access/modify the DNS records.
#     Input Type: single
#     Required: true
#     Advanced: false
#   APPLICATION_DATABASE_NAME:
#     Category: Database
#     Description: 'The name of the application database. Example: mydb'
#     Input Type: single
#     Required: true
#     Advanced: false
#   APPLICATION_PASSWORD:
#     Category: Database
#     Description: 'The password of the application user. Example: cred:MYSQL_APPLICATION_PASSWORD'
#     Input Type: single
#     Required: true
#     Advanced: false
#   SERVER_ROOT_PASSWORD:
#     Category: Database
#     Description: 'The root password for MySQL server. Example: cred:MYSQL_ROOT_PASSWORD'
#     Input Type: single
#     Required: true
#     Advanced: false
#   SERVER_USAGE:
#     Category: Database
#     Description: "The Server Usage method. It is either 'dedicated' or 'shared'. In
#       a 'dedicated' server all server resources are dedicated to MySQL. In a 'shared'
#       server, MySQL utilizes only half of the resources. Example: 'dedicated'\r\n"
#     Input Type: single
#     Required: true
#     Advanced: false
#   SERVER_REPL_PASSWORD:
#     Category: Database
#     Description: "The replication password set on the master database and used by
#       the slave to authenticate and connect. If not set, rs-mysql/server_root_password
#       will be used. Example cred:MYSQL_REPLICATION_PASSWORD\r\n"
#     Input Type: single
#     Required: true
#     Advanced: false
#   DNS_USER_KEY:
#     Category: Database
#     Description: The user key to access/modify the DNS records.
#     Input Type: single
#     Required: true
#     Advanced: false
#   APPLICATION_USER_PRIVILEGES:
#     Category: Database
#     Description: 'The privileges given to the application user. This can be an array
#       of mysql privilege types. Example: select, update, insert'
#     Input Type: array
#     Required: true
#     Advanced: false
#     Default: array:["text:select","text:update","text:insert"]
#   APPLICATION_USERNAME:
#     Category: Database
#     Description: "The username of the application user. Example: cred:MYSQL_APPLICATION_USERNAME\r\nrs-mysql"
#     Input Type: single
#     Required: true
#     Advanced: false
#   DB_BACKUP_LINEAGE:
#     Category: Database
#     Description: The prefix that will be used to name/locate the backup of the MySQL
#       database server.
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
instance_data=$(/usr/local/bin/rsc --rl10 cm15 index_instance_session  /api/sessions/instance)
instance_uuid=$(echo $instance_data | /usr/local/bin/rsc --x1 '.monitoring_id' json)
instance_id=$(echo $instance_data | /usr/local/bin/rsc --x1 '.resource_uid' json)

#convert input array to array for json in chef.json below
user_priv_array=${APPLICATION_USER_PRIVILEGES//,/ }
user_priv_array=$(echo "$user_priv_array" | sed -e 's/\(\w*\)/,"\1"/g' | cut -d , -f 2-)


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
  "backup":{
    "lineage":"$DB_BACKUP_LINEAGE"
  },
  "dns":{
  "master_fqdn":"$DNS_MASTER_FQDN",
  "secret_key":"$DNS_SECRET_KEY",
  "user_key":"$DNS_USER_KEY"
  },
  "application_database_name":"$APPLICATION_DATABASE_NAME",
  "application_password":"$APPLICATION_PASSWORD",
  "application_user_privileges":[$user_priv_array],
  "application_username":"$APPLICATION_USERNAME",
  "bind_network_interface":"$BIND_NETWORK_INTERFACE",
  "server_repl_password":"$SERVER_REPL_PASSWORD",
  "server_root_password":"$SERVER_ROOT_PASSWORD",
  "server_usage":"$SERVER_USAGE"
 },

	"run_list": ["recipe[rs-mysql::master]"]
}
EOF


chef-client --json-attributes $chef_dir/chef.json
