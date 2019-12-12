#!/bin/bash -ex
# ---
# RightScript Name: RL5/6/10 Setup Custom Logrotate Configs
# Inputs:
#   CONFIGS:
#     Category: Logging
#     Description: Space separated list of configurations to download from attachments.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:chef
# Attachments:
# - chef
# ...
# RL5/6/10 Setup Custom Logrotate Configs
# This script will copy the custom logrotate configs [attached to this RightScript] and change logrotate to run hourly versus daily.  It's currently designed for Ubuntu 12, but shouldn't require much modification for newer versions of Ubuntu or even CentOS as logrotate hasn't changed much recently.
#
# Written by: Bryan Karaffa [bryan.karaffa@rightscale.com]


# Operational Code
# This is where you put the steps for install for each version of RightLink.

# RL5 and RL6 share the same limitation.  Use the same code for both versions.
do_RL56 () {
  echo "Executed do_RL56()"
  # List Contents of attachments
  ls -al $RS_ATTACH_DIR/
  # Copy attachments containing custom logrotate configs
  for f in $CONFIGS; do
    cp -rf $RS_ATTACH_DIR/$f /etc/logrotate.d/
  done
  # Set Logrotate to run hourly versus daily
  if [ ! -f /etc/cron.hourly/logrotate ]; then cp -rf /etc/cron.daily/logrotate /etc/cron.hourly/logrotate; chmod +x /etc/cron.hourly/logrotate; fi
  # List Current Logrotate Config Files
  ls -al /etc/logrotate.d/  
}

do_RL10 () {
  echo "Executed do_RL10()"
  # List Contents of attachments
  ls -al $RS_ATTACH_DIR/
  # Copy attachments containing custom logrotate configs
  for f in $CONFIGS; do
    sudo cp -rf $RS_ATTACH_DIR/$f /etc/logrotate.d/
  done
# Cleanup the RightScript that may accidently get copied
  if [ -f /etc/logrotate.d/__script-0 ]; then sudo rm -f /etc/logrotate.d/__script-0; fi
  # Set Logrotate to run hourly versus daily
  if [ ! -f /etc/cron.hourly/logrotate ]; then sudo cp -rf /etc/cron.daily/logrotate /etc/cron.hourly/logrotate; sudo chmod +x /etc/cron.hourly/logrotate; fi
  # List Current Logrotate Config Files
  ls -al /etc/logrotate.d/
}



# Get the RightLink Version
if [ -f /etc/rightscale.d/rightscale-release ]; then

  if grep -q '6.*.*'  /etc/rightscale.d/rightscale-release; then rightlink_version=6; 
  elif grep -q '5.*.*'  /etc/rightscale.d/rightscale-release; then rightlink_version=5;
  fi
elif [ -f /var/lib/rightscale-identity ]; then rightlink_version=10; 
else
  echo "RightLink version could not be identified or is older than version 5."
  exit 1
fi
echo "This instance is running RightLink Version $rightlink_version"

# Run the function associated with the version of RightLink that is installed.
case $rightlink_version in
   5) do_RL56;;
   6) do_RL56;;
   10) do_RL10;;
esac
