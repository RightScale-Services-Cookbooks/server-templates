#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: RL 10 CHEF SERVER BACKUP VIA RIGHTSCRIPTS
# Description: RL 10 CHEF SERVER BACKUP VIA RIGHTSCRIPTS
# Inputs:
#   CHEF_SERVER_LOG_LEVEL:
#     Category: CHEF
#     Description: Chef solo Log Level
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:info
#     Possible Values:
#     - text:info
#     - text:warn
#     - text:fatal
#     - text:error
#     - text:debug
#   BACKUP_LINEAGE:
#     Category: Backup
#     Description: Name of the backup
#     Input Type: single
#     Required: false
#     Advanced: false
#   STORAGE_ACCOUNT_ENDPOINT:
#     Category: Backup
#     Description: 'The endpoint URL for the storage cloud. This is used to override
#       the default endpoint or for generic storage clouds such as Swift Example: http://endpoint_ip:5000/v2.0/tokens'
#     Input Type: single
#     Required: false
#     Advanced: false
#   STORAGE_ACCOUNT_ID:
#     Category: Backup
#     Description: "In order to write the Chef Server backup file to the specified cloud
#       storage location you need to provide cloud authentication credentials\r\n    For
#       Amazon S3, use your AWS secret access key\r\n     (e.g., cred:AWS_SECRET_ACCESS_KEY).\r\n
#       \\    For Rackspace Cloud Files, use your Rackspace account API key     (e.g.,
#       cred:RACKSPACE_AUTH_KEY). Example: cred:AWS_SECRET_ACCESS_KEY"
#     Input Type: single
#     Required: false
#     Advanced: false
#   STORAGE_ACCOUNT_PROVIDER:
#     Category: Backup
#     Description: "In order to write the Chef Server backup file to the specified cloud
#       storage location\r\n   you need to provide cloud authentication credentials.\r\n
#       \\   For Amazon S3, use your Amazon access key ID\r\n    (e.g., cred:AWS_ACCESS_KEY_ID).
#       For Rackspace Cloud Files, use your\r\n     Rackspace login username (e.g.,
#       cred:RACKSPACE_USERNAME).\r\n    \" For OpenStack Swift the format is: 'tenantID:username'.\r\n
#       \\    Example: cred:AWS_ACCESS_KEY_ID"
#     Input Type: single
#     Required: false
#     Advanced: false
#     Possible Values:
#     - text:aws
#     - text:google
#     - text:rackspace
#   STORAGE_ACCOUNT_SECRET:
#     Category: Backup
#     Description: "In order to write the Chef Server backup file to the specified cloud
#       storage location you need to provide cloud authentication credentials\r\n    For
#       Amazon S3, use your AWS secret access key\r\n     (e.g., cred:AWS_SECRET_ACCESS_KEY).\r\n
#       \\    For Rackspace Cloud Files, use your Rackspace account API key     (e.g.,
#       cred:RACKSPACE_AUTH_KEY). Example: cred:AWS_SECRET_ACCESS_KEY"
#     Input Type: single
#     Required: false
#     Advanced: false
#   STORAGE_CONTAINER:
#     Category: Backup
#     Description: "The cloud storage location where the dump file will be saved to\r\n
#       \\   or restored from. For Amazon S3, use the bucket name.\r\n    For Rackspace
#       Cloud Files, use the container name.\r\n    Example: db_dump_bucket"
#     Input Type: single
#     Required: false
#     Advanced: false
#   REGION:
#     Category: Backup
#     Description: 'The cloud region where the bucket is located.   Example: us-west-2'
#     Input Type: single
#     Required: false
#     Advanced: false
# Attachments: []
# ...

set -e

echo "installing awscli for s3 access"
apt-get install -y awscli
echo "installed awscli successfully"

TIMESTAMP=`date '+%Y-%m-%d-%H-%M-%S'`
OPSCODE_PG_USER="opscode-pgsql"
PG_DUMP_BIN="/opt/opscode/embedded/bin/pg_dumpall"
PG_DUMP_FILE="/tmp/postgresql-dump-${TIMESTAMP}.gz"
TAR_BIN=`which tar`
 
# TODO: Is this sufficient to make sure that the server is "quiet"?
echo "Disabling outside access to Chef server..."
chef-server-ctl stop opscode-erchef
 
echo "Backing up Chef server database to [${PG_DUMP_FILE}]..."
cd /tmp
sudo -E -u ${OPSCODE_PG_USER} bash -c "${PG_DUMP_BIN} -c | gzip --fast > ${PG_DUMP_FILE}"
 
echo "Stopping all Chef server processes..."
chef-server-ctl stop

echo "Backing up Chef server database to [${PG_DUMP_FILE}]..."
cd /tmp
sudo -E -u ${OPSCODE_PG_USER} bash -c "${PG_DUMP_BIN} -c | gzip --fast > ${PG_DUMP_FILE}"
 
echo "Stopping all Chef server processes..."
chef-server-ctl stop

ETC_OPSCODE_BACKUP="/etc/opscode"
VAR_OPT_OPSCODE_BACKUP="/var/opt/opscode"
FULL_BACKUP="/tmp/chef-server-backup-${BACKUP_LINEAGE}-${TIMESTAMP}.tar.gz"
LATEST_BACKUP="chef-server-backup-${BACKUP_LINEAGE}-latest.tar.gz"
echo "Backing up all Chef server assets..."
${TAR_BIN} cvfzp ${FULL_BACKUP} ${ETC_OPSCODE_BACKUP} ${VAR_OPT_OPSCODE_BACKUP} ${PG_DUMP_FILE}
 
echo "Removing extra files..."
rm -f ${PG_DUMP_FILE}
 
echo "Starting all Chef server processes..."
chef-server-ctl start
 
echo "Backup complete!"
echo "Backup located at [${FULL_BACKUP}]."

echo "Pushing backup to s3://[${STORAGE_CONTAINER}]"
cd /tmp

aws s3 --region $REGION cp $FULL_BACKUP s3://$STORAGE_CONTAINER/
aws s3 --region $REGION cp $FULL_BACKUP s3://$STORAGE_CONTAINER/$LATEST_BACKUP
echo "Successfully pushed $FULL_BACKUP to S3:[${STORAGE_CONTAINER}]"

echo "Removing Backup"
rm -f ${FULL_BACKUP}
