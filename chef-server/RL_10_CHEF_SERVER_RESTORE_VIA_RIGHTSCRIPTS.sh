#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: RL 10 CHEF SERVER RESTORE VIA RIGHTSCRIPTS
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
#   RESTORE_LINEAGE:
#     Category: Backup
#     Description: Name of the restore file. e.g. latest
#     Input Type: single
#     Required: false
#     Advanced: false
# Attachments: []
# ...

set -e

HOME=/home/rightscale
/sbin/mkhomedir_helper rightlink

set +e
echo "installing awscli for s3 access"
apt-get install -y awscli jq
echo "installed awscli successfully"

TIMESTAMP=`date '+%Y-%m-%d-%H-%M-%S'`
OPSCODE_PG_USER="opscode-pgsql"
WORKING_DIR="/tmp/chef-server-restore"

BACKUP_FILE="chef-server-backup-$BACKUP_LINEAGE-$RESTORE_LINEAGE.tar.gz"

#BACKUP_FILE="$RESTORE_LINEAGE.tgz"

#BACKUP_PATH=$WORKING_DIR/$RESTORE_LINEAGE

echo "Creating working directory: [${WORKING_DIR}]..."
mkdir -p ${WORKING_DIR}

echo "Storage Container: [${STORAGE_CONTAINER}]..."

echo "Full Path of File: [${STORAGE_CONTAINER}][${BACKUP_FILE}]..."
echo "Pulling down the backup from S3:[${STORAGE_CONTAINER}][${BACKUP_FILE}]...  "

cd ${WORKING_DIR}
aws s3 --region $REGION cp s3://$STORAGE_CONTAINER/$BACKUP_FILE .

if [ ! -f "${BACKUP_FILE}" ] ; then
  echo "ERROR: [${BACKUP_FILE}] does not look like a proper backup file."
  exit 1
else
  echo "Successfully downloaded chef-server backup file"
fi
 
cd ${WORKING_DIR}
tar xvfzp ${BACKUP_FILE} --exclude='var/opt/opscode/drbd/data/postgresql_9.2' -C ${WORKING_DIR}
 
echo "Stopping all Chef server processes..."
chef-server-ctl stop
 
ETC_OPSCODE_BACKUP="/etc/opscode"
echo "Deleting Chef server directory: [${ETC_OPSCODE_BACKUP}]..."
rm -rf ${ETC_OPSCODE_BACKUP}
 
VAR_OPT_OPSCODE_BACKUP="/var/opt/opscode"
echo "Deleting Chef server directory: [${VAR_OPT_OPSCODE_BACKUP}]..."
rm -rf ${VAR_OPT_OPSCODE_BACKUP}
 
echo "Restoring [${ETC_OPSCODE_BACKUP}] from backup..."
cp -rp ${WORKING_DIR}/etc/opscode ${ETC_OPSCODE_BACKUP}
 
echo "Restoring [${VAR_OPT_OPSCODE_BACKUP}] from backup..."
cp -rp ${WORKING_DIR}/var/opt/opscode ${VAR_OPT_OPSCODE_BACKUP}
 
echo "Starting Chef server postgresql service..."
chef-server-ctl start postgresql
 
echo "Waiting for postgresql service to start up..."
# TODO - see if we can determine that this is up for certain; for now, 15 seconds works fine
sleep 15
 
echo "Finding database backup file in [${WORKING_DIR}]..."
DB_BACKUP_FILE=`find ${WORKING_DIR}/tmp -maxdepth 1 -type f -name "postgresql-dump-*.gz" | head -n1`
echo "Found database backup file: [${DB_BACKUP_FILE}]."
 
echo "Restoring postgresql data from [${DB_BACKUP_FILE}]..."
sudo -E -u ${OPSCODE_PG_USER} bash -c "gunzip -c ${DB_BACKUP_FILE} | /opt/opscode/embedded/bin/psql -U '${OPSCODE_PG_USER}' -d postgres"
 
#echo "Fixing Reporting SQL Password"
#opscode_pgsql_password=`jq .private_chef.postgresql.db_superuser_password /etc/opscode/chef-server-running.json`
#jq .postgresql.db_superuser_password=$opscode_pgsql_password /etc/opscode-reporting/opscode-reporting-secrets.json > /etc/opscode-reporting/tmp_secrets.json
#mv /etc/opscode-reporting/tmp_secrets.json /etc/opscode-reporting/opscode-reporting-secrets.json

echo "Reconfiguring Chef server..."
chef-server-ctl reconfigure
 
##echo "Running Chef server upgrade process. This may take some time..."
##chef-server-ctl upgrade

#echo "Running Chef Reporting Service management console reconfigure."
#opscode-reporting-ctl reconfigure

echo "Running Chef Server management console reconfigure. This may take about ~45 seconds"
opscode-manage-ctl reconfigure

echo "Restarting Chef server processes..."
chef-server-ctl restart
 
echo "Removing working directory..."
rm -rf ${WORKING_DIR}
 
echo "Restore complete!"
