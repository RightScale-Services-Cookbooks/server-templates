#!/usr/bin/sudo /bin/bash
# ---
# RightScript Name: Chef Backup
# Description: Backup a snapshot of the Chef environment.
# Inputs:
#   CHEF_BACKUP_BUCKET:
#     Category: Backup
#     Description: Bucket to store backups. Please do not include "s3://" or "gs://"
#     Input Type: single
#     Required: true
#     Advanced: false
#   STORAGE_PROVIDER:
#     Category: Backup
#     Description: AWS or GCE storage backend to copy Chef backups.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Possible Values:
#       - text:AWS
#       - text:GCE
# Attachments: []
# ...

TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
OPSCODE_PG_USER="opscode-pgsql"
PG_DUMP_BIN="/opt/opscode/embedded/bin/pg_dumpall"
PG_DUMP_FILE="/tmp/postgresql-dump-${TIMESTAMP}.gz"
TAR_BIN=$(which tar)

if [ "${STORAGE_PROVIDER}" == "AWS" ]; then
  STORAGE_PREFIX="s3://"
else
  STORAGE_PREFIX="gs://"
fi

echo "Disabling outside access to Chef server..."
chef-server-ctl stop opscode-erchef
 
echo "Backing up Chef server database to [${PG_DUMP_FILE}]..."
cd /tmp || exit 1
sudo -E -u ${OPSCODE_PG_USER} bash -c "${PG_DUMP_BIN} -c | gzip --fast > ${PG_DUMP_FILE}"
 
echo "Stopping all Chef server processes..."
chef-server-ctl stop
 
ETC_OPSCODE_BACKUP="/etc/opscode"
VAR_OPT_OPSCODE_BACKUP="/var/opt/opscode"
FULL_BACKUP="/tmp/chef-server-backup-${TIMESTAMP}.tar.gz"
SHORT_BACKUP=$(basename "${FULL_BACKUP}")
STORAGE_LOCATION="${STORAGE_PREFIX}${CHEF_BACKUP_BUCKET}/${SHORT_BACKUP}"

echo "Backing up all Chef server assets..."
"${TAR_BIN}" cvfzp "${FULL_BACKUP}" "${ETC_OPSCODE_BACKUP}" "${VAR_OPT_OPSCODE_BACKUP}" "${PG_DUMP_FILE}"
 
echo "Removing extra files..."
rm -f "${PG_DUMP_FILE}"
 
echo "Starting all Chef server processes..."
chef-server-ctl start

if [ "${STORAGE_PROVIDER}" == "AWS" ]; then
  aws s3 cp "${FULL_BACKUP}" "${STORAGE_LOCATION}" || exit 1
else
  gsutil cp "${FULL_BACKUP}" "${STORAGE_LOCATION}" || exit 1
fi

rm -f "${FULL_BACKUP}"

echo "Backup complete!"
echo "Backup located at: ${STORAGE_LOCATION}"
