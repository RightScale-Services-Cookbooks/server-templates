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
#   STOR_BACKUP_LINEAGE:
#     Category: Storage
#     Input Type: single
#     Required: true
#     Advanced: false
#   DEVICE_MOUNT_POINT:
#     Category: Storage
#     Description: 'The mount point to mount the device on. Example: /var/lib/jenkins'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:/var/lib/jenkins
#   DEVICE_NICKNAME:
#     Category: Storage
#     Description: 'Nickname for the device. rs-storage::volume uses this for the filesystem
#       label, which is restricted to 12 characters. If longer than 12 characters, the
#       filesystem label will be set to the first 12 characters. Example: data_storage'
#     Input Type: single
#     Required: true
#     Advanced: false
# Attachments: 
#   - rs-storage-d669f08f87743e072eba619a3fba6a9c9dd6bc89.tar
# ...

set -x
set -e

# https://github.com/berkshelf/berkshelf-api/issues/112
export LC_CTYPE=en_US.UTF-8

if [ ! -e /usr/bin/chef-client ]; then
  curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- -v 12.19.36
fi

HOME=/home/rightscale
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin

/sbin/mkhomedir_helper rightlink

export chef_dir=$HOME/.chef

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

if [ -f $RS_ATTACH_DIR/rs-storage-d669f08f87743e072eba619a3fba6a9c9dd6bc89.tar ]; then
  tar -xvf $RS_ATTACH_DIR/rs-storage-d669f08f87743e072eba619a3fba6a9c9dd6bc89.tar
fi

/opt/chef/embedded/bin/berks vendor $chef_dir/cookbooks

#get instance data to pass to chef server
instance_data=$(/usr/local/bin/rsc --rl10 cm15 index_instance_session  /api/sessions/instance)
instance_uuid=$(echo $instance_data | /usr/local/bin/rsc --x1 '.monitoring_id' json)
instance_id=$(echo $instance_data | /usr/local/bin/rsc --x1 '.resource_uid' json)

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
  "device": {
    "mount_point":"$DEVICE_MOUNT_POINT",
    "nickname":"$DEVICE_NICKNAME"
  },
  "backup":{
    "lineage":"$STOR_BACKUP_LINEAGE",
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

cat <<EOF> $chef_dir/solo.rb
cookbook_path "$chef_dir/cookbooks"
data_bag_path "$chef_dir/data_bags"
EOF

chef-solo -l info -L /var/log/chef.log -j $chef_dir/chef.json -c $chef_dir/solo.rb
