#!/usr/bin/sudo /bin/bash
# ---
# RightScript Name: Chef Backup to S3
# Description: Backup a snapshot of the Chef environment to S3.
# Inputs:
#   CHEF_BACKUP_BUCKET:
#     Category: Backup
#     Description: s3 bucket to save backups to.
#     Input Type: single
#     Required: true
#     Advanced: false
#   CHEF_BACKUP_BUCKET_REGION:
#     Category: Backup
#     Description: s3 bucket region.
#     Input Type: single
#     Required: true
#     Advanced: false
#   AWS_ACCESS_KEY:
#     Category: Backup
#     Description: AWS Access Key.
#     Required: true
#     Advanced: false
#   AWS_SECRET_ACCESS_KEY:
#     Category: Backup
#     Description: AWS Secret Access Key.
#     Required: true
#     Advanced: false
# Attachments: []
# ...

TIMESTAMP=`date '+%Y-%m-%d-%H-%M-%S'`
OPSCODE_PG_USER="opscode-pgsql"
PG_DUMP_BIN="/opt/opscode/embedded/bin/pg_dumpall"
PG_DUMP_FILE="/tmp/postgresql-dump-${TIMESTAMP}.gz"
TAR_BIN=`which tar`

echo "Disabling outside access to Chef server..."
chef-server-ctl stop opscode-erchef
 
echo "Backing up Chef server database to [${PG_DUMP_FILE}]..."
cd /tmp
sudo -E -u ${OPSCODE_PG_USER} bash -c "${PG_DUMP_BIN} -c | gzip --fast > ${PG_DUMP_FILE}"
 
echo "Stopping all Chef server processes..."
chef-server-ctl stop
 
ETC_OPSCODE_BACKUP="/etc/opscode"
VAR_OPT_OPSCODE_BACKUP="/var/opt/opscode"
FULL_BACKUP="/tmp/chef-server-backup-${TIMESTAMP}.tar.gz"
SHORT_BACKUP=`basename ${FULL_BACKUP}`
S3_LOCATION="s3://${CHEF_BACKUP_BUCKET}/${SHORT_BACKUP}"

echo "Backing up all Chef server assets..."
${TAR_BIN} cvfzp ${FULL_BACKUP} ${ETC_OPSCODE_BACKUP} ${VAR_OPT_OPSCODE_BACKUP} ${PG_DUMP_FILE}
 
echo "Removing extra files..."
rm -f ${PG_DUMP_FILE}
 
echo "Starting all Chef server processes..."
chef-server-ctl start
 
aws s3 cp ${FULL_BACKUP} ${S3_LOCATION}
rm ${FULL_BACKUP}

echo "Backup complete!"
echo "Backup located at: ${S3_LOCATION}"
