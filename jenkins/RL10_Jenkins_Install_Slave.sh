#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: RL10 Jenkins Install Slave
# Description: Install and configure Jenkins master server
# Inputs:
#   LOG_LEVEL:
#     Category: CHEF
#     Description: The log level for the chef install
#     Input Type: single
#     Required: true
#     Advanced: true
#     Possible Values:
#     - text:info
#     - text:warn
#     - text:fatal
#     - text:debug
#     Default: text:info
#   COOKBOOK_VERSION:
#     Category: JENKINS
#     Description: 'The jenkins cookbook version to install from.  This allows for multiple versions
#       of the same cookbook in the attachments. (e.g. If attachments is jenkins-201704111.tar the version is 201704111.)'
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:201704183
#   NAME:
#     Category: JENKINS
#     Description: 'The name of the jenkins slave server.'
#     Input Type: single
#     Required: true
#     Advanced: false
#   MASTER_IP:
#     Category: JENKINS
#     Description: 'The fqdn or IP address of the master.'
#     Input Type: single
#     Required: true
#     Advanced: false
#   SWARM_PLUGIN_VERSION:
#     Category: JENKINS
#     Description: 'The version of the swam plugin to install. https://wiki.jenkins-ci.org/display/JENKINS/Swarm+Plugin'
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:3.4
#   DESCRIPTION:
#     Category: JENKINS
#     Description: 'Description of slave instances.'
#     Input Type: single
#     Required: false
#     Advanced: false
#   AUTO_DISCOVERY_ADDRESS:
#     Category: JENKINS
#     Description: 'Use this address for udp-based auto-discovery'
#     Input Type: single
#     Required: false
#     Advanced: true
#   CANDIDATE_TAG:
#     Category: JENKINS
#     Description: 'Show swarm candidate with tag only'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:false
#     Possible Values: ["text:true", "text:false"]
#   DELETE_EXISTING:
#     Category: JENKINS
#     Description: 'Deletes any existing slave with the same name.'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:true
#     Possible Values: ["text:true", "text:false"]
#   DISABLE_UNIQUE_ID:
#     Category: JENKINS
#     Description: 'Disables clients unique ID.'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:false
#     Possible Values: ["text:true", "text:false"]
#   DISABLE_SSL_VERIFICATION:
#     Category: JENKINS
#     Description: 'Disables SSL verification. Must be set to true if HTTP is being used.'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:true
#     Possible Values: ["text:true", "text:false"]
#   EXECUTORS:
#     Category: JENKINS
#     Description: 'Number of executors.'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:2
#   LABELS:
#     Category: JENKINS
#     Description: 'Whitespace-separated list of labels to be assigned for this slave.'
#     Input Type: single
#     Required: false
#     Advanced: true
#   MASTER_PORT:
#     Category: JENKINS
#     Description: 'The port the Jenkins master is listening on.'
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:8080
#   MASTER_PROTOCOL:
#     Category: JENKINS
#     Description: 'The http(s) protocol the Jenkins master is listening on.'
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:http
#     Possible Values: ["text:http", "text:https"]
#   MODE:
#     Category: JENKINS
#     Description: 'The mode controlling how Jenkins allocates jobs to slaves. Can be either "normal" (utilize this slave as much as possible) or "exclusive" (leave this machine for tied jobs only) Default: normal.'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Possible Values: ["text:normal", "text:exclusive"]
#   NO_RETRY_AFTER_CONNECTED:
#     Category: JENKINS
#     Description: 'Do not retry if a successful connection gets closed.'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:false
#     Possible Values: ["text:true", "text:false"]
#   JENKINS_PASSWORD:
#     Category: JENKINS
#     Description: 'The Jenkins user password.'
#     Input Type: single
#     Required: false
#     Advanced: true
#   RETRY:
#     Category: JENKINS
#     Description: 'Number of retrys before giving up.'
#     Input Type: single
#     Required: false
#     Advanced: true
#   JENKINS_USERNAME:
#     Category: JENKINS
#     Description: 'The Jenkins user name.'
#     Input Type: single
#     Required: false
#     Advanced: true
#   RETRY_BACK_OFF_STRATEGY:
#     Category: JENKINS
#     Description: 'The mode controlling retry wait time.'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Possible Values: ["text:linear", "text:exponential", "text:none"]
#   RETRY_INTERVAL:
#     Category: JENKINS
#     Description: 'Time to wait before retry in seconds.'
#     Input Type: single
#     Required: false
#     Advanced: true
#   SSL_FINGER_PRINTS:
#     Category: JENKINS
#     Description: 'Whitespace-separated list of accepted certificate fingerprints (SHA-256/Hex), otherwise system truststore will be used.'
#     Input Type: single
#     Required: false
#     Advanced: true
#   MAX_RETRY_INTERVAL:
#     Category: JENKINS
#     Description: 'Max time to wait before retry in seconds.'
#     Input Type: single
#     Required: false
#     Advanced: true
# Attachments:
#   - rsc_jenkins-201704183.tar
# ...

# Make Name URL Safe
# This should probably be done in the Jenkins cookbook
NAME=`echo "$NAME" | sed "s/ /_/g" | sed "s/[&$+,\/:;=?@#{}<>|%^]//g" | sed "s/[\[\]]//g"`

set -x
set -e

# https://github.com/berkshelf/berkshelf-api/issues/112
export LC_CTYPE=en_US.UTF-8

if [ ! -e /usr/bin/chef-client ]; then
  curl -L https://www.opscode.com/chef/install.sh | sudo bash
fi

chef_dir="/home/rightscale/.chef"

# if [ -e $chef_dir/cookbooks ]; then
#   echo "Jenkins already installed.  Exiting."
#   exit 0
# fi

rm -rf $chef_dir
mkdir -p $chef_dir/chef-install
chmod -R 0777 $chef_dir/chef-install

mkdir -p $chef_dir/cookbooks
chown -R 0777 $chef_dir/cookbooks

#install packages when on ubuntu
if which apt-get >/dev/null 2>&1; then
  apt-get -y update
  apt-get install -y build-essential git #ruby2.0 ruby2.0-dev
fi

#install packages for centos
if which yum >/dev/null 2>&1; then
  yum groupinstall -y 'Development Tools'
  yum install -y libxml2 libxml2-devel libxslt libxslt-devel git
fi

#install berkshelf
/opt/chef/embedded/bin/gem install berkshelf -v '4.3.5' --no-ri --no-rdoc

#checkout the chef server cookbook and install dependent cookbooks using berkshelf
cd $chef_dir

# # Download cookbooks from RS Attachments

if [ -f $RS_ATTACH_DIR/rsc_jenkins-$COOKBOOK_VERSION.tar ]; then
  tar -xvf $RS_ATTACH_DIR/rsc_jenkins-$COOKBOOK_VERSION.tar
fi

/opt/chef/embedded/bin/berks vendor $chef_dir/cookbooks

cd $HOME

if [ -e $chef_dir/chef.json ]; then
  rm -f $chef_dir/chef.json
fi

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
  "rsc_jenkins":{
    "swarm" : {
      "version": "$SWARM_PLUGIN_VERSION"
    },
    "slave": {
      "name": "$NAME",
      "description": "$DESCRIPTION",
      "master": "$MASTER_IP",
      "auto-discovery-address": "$AUTO_DISCOVERY_ADDRESS",
      "candidate-tag": $CANDIDATE_TAG,
      "delete-existing-clients": $DELETE_EXISTING,
      "disable-clients-unique-id": $DISABLE_UNIQUE_ID,
      "disable-ssl-verification": $DISABLE_SSL_VERIFICATION,
      "executors": "$EXECUTORS",
      "labels": "$LABELS",
      "master_port": "$MASTER_PORT",
      "master_protocol": "$MASTER_PROTOCOL",
      "mode": "$MODE",
      "no-retry-after-connected": $NO_RETRY_AFTER_CONNECTED,
      "password": "$JENKINS_PASSWORD",
      "retry": "$RETRY",
      "retry-back-off-strategy": "$RETRY_BACK_OFF_STRATEGY",
      "retry-interval": "$RETRY_INTERVAL",
      "ssl-finger-prints": "$SSL_FINGER_PRINTS",
      "username": "$JENKINS_USERNAME",
      "maxRetryInterval": "$MAX_RETRY_INTERVAL"
    }
  },
  "run_list": ["recipe[rsc_jenkins::slave]"]
}
EOF

cat <<EOF> $chef_dir/solo.rb
cookbook_path "$chef_dir/cookbooks"
EOF

#cp -f /tmp/environment /etc/environment
/sbin/mkhomedir_helper rightlink

chef-solo -l $LOG_LEVEL -L /var/log/chef.log -j $chef_dir/chef.json -c $chef_dir/solo.rb
