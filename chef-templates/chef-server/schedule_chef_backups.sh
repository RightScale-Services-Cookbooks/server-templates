#!/usr/bin/sudo /bin/bash
# ---
# RightScript Name: Schedule Chef Backups
# Description: Creates a cron job that kicks off backups via 'Chef Backup' and installs backup tools.
# Inputs:
#   SCHEDULE:
#     Category: Backup
#     Description: Cron style time schedule. (Defaults to 11am UTC, 1 11 * * *)
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:1 11 * * *
#   STORAGE_PROVIDER:
#     Category: Backup
#     Description: AWS or GCE storage backend to copy Chef backups.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Possible Values:
#       - text:AWS
#       - text:GCE
#   GSUTIL_JSON:
#     Category: Backup
#     Description: JSON file with gsutil json credentials.
#     Input Type: single
#     Required: false
#     Advanced: false
#   GCE_PROJECT_NAME:
#     Category: Backup
#     Description: Name of the GCE project.
#     Input Type: single
#     Required: false
#     Advanced: false
#   AWS_ACCESS_KEY:
#     Category: Backup
#     Description: AWS Access Key.
#     Required: false
#     Advanced: false
#   AWS_SECRET_ACCESS_KEY:
#     Category: Backup
#     Description: AWS Secret Access Key.
#     Required: false
#     Advanced: false
#   BUCKET_REGION:
#     Category: Backup
#     Description: Region where backup bucket lives. Only applicable if using AWS.
#     Required: false
#     Advanced: false
# Attachments: []
# ...

YUM_REPO="[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
"

AWS_CREDS="[default]
output = text
region = ${BUCKET_REGION}
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
"

CRONTAB="$SCHEDULE root /usr/local/bin/rsc rl10 run_right_script /rll/run/right_script right_script=\"Chef Backup\""

# HOME doesnt get changed on ubuntu when sudoing.
# This forces the backup script to properly use roots homedir to find the creds.
SUDOERS_HOMEDIR="Defaults    always_set_home"

if [ "${STORAGE_PROVIDER}" == "GCE" ]; then
  if [ -x "$(which yum)" ]; then
    cat > /etc/yum.repos.d/google-cloud-sdk.repo <<-EOF
			$YUM_REPO
		EOF
    
    yum install -y google-cloud-sdk
  fi

  if [ -x "$(which apt-get)" ]; then
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    apt-get update && apt-get install -y google-cloud-sdk
   fi

  cat > /root/gsutil.json <<-EOF
		$GSUTIL_JSON
	EOF

  gcloud auth activate-service-account --key-file=/root/gsutil.json
  gcloud config set project "${GCE_PROJECT_NAME}"
  ln -sf /home/rightlink/.config /root/.config
  rm -f /root/gsutil.json
fi

if [ "${STORAGE_PROVIDER}" == "AWS" ]; then
  if [ -x "$(which yum)" ]; then
    yum install -y python2-pip
    pip install awscli
  fi

  if [ -x "$(which apt-get)" ]; then
    apt-get update && apt-get install -y python-pip
    pip install awscli
  fi
   
   cat > /etc/sudoers.d/90-rightscale-backups <<-EOF
			$SUDOERS_HOMEDIR
		EOF

    chmod 0440 /etc/sudoers.d/90-rightscale-backups
    visudo -c || exit 1

  rm -rf /root/.aws
  mkdir /root/.aws

  cat > /root/.aws/credentials <<-EOF
		$AWS_CREDS
	EOF
fi

rm -f /etc/cron.d/chef-backup
cat > /etc/cron.d/chef-backup <<-EOF
	$CRONTAB
EOF
