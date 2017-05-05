#!/usr/bin/sudo /bin/bash
# ---
# RightScript Name: RL10 Chef Server Schedule Cron For Backups Via RightScripts 
# Description: "Creates a cron job that kicks off backups via RL_10_CHEF_SERVER_BACKUP_VIA_RIGHTSCRIPTS. NOTE: While this server is backing up (~70sec) chef will be stopped. Instances and Knife commands will fail during this time."
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

if [ -f /etc/cron.d/chef-backup ]; then
  rm -rf /etc/cron.d/chef-backup
fi
  
cat << EOF > /etc/cron.d/chef-backup
$SCHEDULE root /usr/local/bin/rsc rl10 run_right_script /rll/run/right_script right_script=RL-10-CHEF-SERVER-BACKUP-VIA-RIGHTSCRIPTS.sh

EOF
