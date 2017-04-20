#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: RL10 Jenkins Install Master
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
#   SWARM_PLUGIN_VERSION:
#     Category: JENKINS
#     Description: 'The swarm plugin version to use.'
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:3.4
# Attachments:
#   - rsc_jenkins-201704183.tar
# ...

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

# Download cookbooks from RS Attachments

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
      "version" : "$SWARM_PLUGIN_VERSION"
    }
  },
  "run_list": ["recipe[rsc_jenkins::master]","recipe[rsc_jenkins::swarm-plugin]"]
}
EOF

cat <<EOF> $chef_dir/solo.rb
cookbook_path "$chef_dir/cookbooks"
data_bag_path "$chef_dir/data_bags"
EOF

#cp -f /tmp/environment /etc/environment
/sbin/mkhomedir_helper rightlink

chef-solo -l $LOG_LEVEL -L /var/log/chef.log -j $chef_dir/chef.json -c $chef_dir/solo.rb
