#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Tomcat Install - chef
# Description: 'Installs/configures the Tomcat application server '
# Inputs:
#   APPLICATION_NAME:
#     Category: Application
#     Description: 'The name of the application. This name is used to generate the path
#       of the application code and to determine the backend pool in a load balancer
#       server that the application server will be attached to. Application names can
#       have only alphanumeric characters and underscores. Example: hello_world'
#     Input Type: single
#     Required: true
#     Advanced: false
#   DATABASE_HOST:
#     Category: Application
#     Description: 'The FQDN of the database server. Example: db.example.com'
#     Input Type: single
#     Required: true
#     Advanced: false
#   DATABASE_SCHEMA:
#     Category: Application
#     Description: 'The password used to connect to the database. Example: cred:MYSQL_APPLICATION_PASSWORD'
#     Input Type: single
#     Required: true
#     Advanced: false
#   DATABASE_USER:
#     Category: Application
#     Description: 'The username used to connect to the database. Example: cred:MYSQL_APPLICATION_USERNAME'
#     Input Type: single
#     Required: true
#     Advanced: false
#   LISTEN_PORT:
#     Category: Application
#     Description: 'The port to use for the application to bind. Example: 8080'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:8080
#   BIND_NETWORK_INTERFACE:
#     Category: Application
#     Description: The network interface to use for the bind address of the application
#       server. It can be either 'private' or 'public' interface.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:private
#     Possible Values:
#     - text:private
#     - text:public
#   VHOST_PATH:
#     Category: Application
#     Description: 'The virtual host served by the application server. The virtual host
#       name can be a valid domain/path name supported by the access control lists (ACLs)
#       in a load balancer. Ensure that no two application servers in the same deployment
#       having the same application name have different vhost paths. Example: http:://www.example.com,
#       /index'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:/
#   REFRESH_TOKEN:
#     Category: Application
#     Description: 'The Rightscale OAUTH refresh token.  Example: cred: MY_REFRESH_TOKEN'
#     Input Type: single
#     Required: true
#     Advanced: false
#   DATABASE_PASSWORD:
#     Category: Application
#     Input Type: single
#     Required: true
#     Advanced: false
#   ROS_PROVIDER:
#     Category: Remote Object Store
#     Description: 'The remote object store provider used to download the war file'
#     Input Type: single
#     Possible Values: ["text:aws", "text:google"]
#     Required: false
#     Advanced: true
#   ROS_ACCESS_KEY:
#     Category: Remote Object Store
#     Description: 'The remote object store provider access key or username'
#     Input Type: single
#     Required: false
#     Advanced: true
#   ROS_SECRET_ACCESS_KEY:
#     Category: Remote Object Store
#     Description: 'The remote object store provider secret access key or password'
#     Input Type: single
#     Required: false
#     Advanced: true
#   ROS_BUCKET:
#     Category: Remote Object Store
#     Description: 'The remote object store bucket'
#     Input Type: single
#     Required: false
#     Advanced: true
#   ROS_FILE:
#     Category: Remote Object Store
#     Description: 'The remote object file to download.'
#     Input Type: single
#     Required: false
#     Advanced: true
#   ROS_DESTINATION:
#     Category: Remote Object Store
#     Description: 'location to store the file: exampe: /opt/tomcat/webapps'
#     Default: text:/opt/tomcat/webapps
#     Input Type: single
#     Required: false
#     Advanced: true
#   ROS_REGION:
#     Category: Remote Object Store
#     Description: 'The remote object store region: example: us-east-1'
#     Input Type: single
#     Required: false
#     Advanced: true
#   TOMCAT_VERSION:
#     Category: Tomcat
#     Description: 'The version of tomcat to install from the package manager: default: 8.0.36'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:8.0.36
#   CATALINA_OPTIONS:
#     Category: Tomcat
#     Description: 'The CATALINA_OPTIONS to include in setenv.sh'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:-Xmx128M -Djava.awt.headless=true
#   MAX_THREADS:
#     Category: Tomcat
#     Description: 'The maximum number of request processing threads to be created by this Connector'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:300
#   JAVA_VERSION:
#     Category: Java
#     Description: 'The version of java to install'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:8
#   JAVA_FLAVOR:
#     Category: Java
#     Description: 'The flavor of Java to install.  IE openjdk, oracle, ibm'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:openjdk
# Attachments: []
# ...

set -e

HOME=/home/rightscale
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin

/sbin/mkhomedir_helper rightlink

export chef_dir=$HOME/.chef
mkdir -p $chef_dir

#get instance data to pass to chef server
instance_data=$(/usr/local/bin/rsc --rl10 cm15 index_instance_session  /api/sessions/instance)
instance_uuid=$(echo $instance_data | /usr/local/bin/rsc --x1 '.monitoring_id' json)
instance_id=$(echo $instance_data | /usr/local/bin/rsc --x1 '.resource_uid' json)
monitoring_server=$(echo $instance_data | /usr/local/bin/rsc --x1 '.monitoring_server' json)
shard=$(echo $monitoring_server | sed -e 's/tss/us-/')

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
		"api_url": "https://${shard}.rightscale.com"
	},
	"rsc_tomcat": {
		"application_name": "$APPLICATION_NAME",
		"bind_network_interface": "$BIND_NETWORK_INTERFACE",
		"listen_port": "$LISTEN_PORT",
		"vhost_path": "$VHOST_PATH",
		"version": "$TOMCAT_VERSION",
		"catalina_options":"$CATALINA_OPTIONS",
		"MaxThreads":"$MAX_THREADS",
		"database": {
			"host": "$DATABASE_HOST",
			"schema": "$DATABASE_SCHEMA",
			"password": "$DATABASE_PASSWORD",
			"user": "$DATABASE_USER"
		},
		"java": {
			"flavor": "$JAVA_FLAVOR",
			"version": "$JAVA_VERSION"
		}
	},
	"rsc_ros": {
		"provider": "$ROS_PROVIDER",
		"access_key": "$ROS_ACCESS_KEY",
		"secret_key": "$ROS_SECRET_ACCESS_KEY",
		"bucket": "$ROS_BUCKET",
		"file": "$ROS_FILE",
		"destination": "$ROS_DESTINATION",
		"region": "$ROS_REGION"
	},
	"run_list": ["recipe[rsc_tomcat]", "recipe[rsc_tomcat::tags]"]
}
EOF


chef-client -j $chef_dir/chef.json
