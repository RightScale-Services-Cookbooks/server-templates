#!/usr/bin/sudo /bin/bash
# ---
# RightScript Name: Schedule Chef Backups
# Description: Creates a cron job that kicks off backups via 'Chef Backup'
# Inputs:
#   SCHEDULE:
#     Category: CHEF
#     Description: Cron style time schedule. (Defaults to 11am UTC, 1 11 * * *)
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:1 11 * * *
# Attachments: []
# ...

set ex

# Configure awscli
if [ -x "$(which yum)" ]; then
  yum install -y python2-pip
  pip install awscli
fi

if [ -x "$(which apt-get)" ]; then
  apt-get update && apt-get install -y python-pip
  pip install awscli
fi

# Setup AWS credentials
rm -rf /root/.aws
mkdir /root/.aws

cat << EOF >> /root/.aws/credentials
[default]
output = text
region = ${CHEF_BACKUP_BUCKET_REGION}
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOF

# Add backup crontab
if [ -f /etc/cron.d/chef-backup ]; then
  rm -rf /etc/cron.d/chef-backup
fi

cat << EOF > /etc/cron.d/chef-backup
$SCHEDULE root /usr/local/bin/rsc rl10 run_right_script /rll/run/right_script right_script="Chef Backup"
EOF
