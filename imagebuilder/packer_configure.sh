#! /bin/bash -e

# ---
# RightScript Name: Packer Configure
# Description: |
#   Create the Packer JSON file.
# Attachments:
#   - azure.json
#   - azure.sh
#   - cleanup.sh
#   - cloudinit.sh
#   - ec2.json
#   - google.json
#   - openstack.json
#   - rightlink.ps1
#   - rightlink.sh
#   - rs-cloudinit.sh
#   - scriptpolicy.ps1
#   - setup_winrm.txt
#   - softlayer.json
# Inputs:
#   CLOUD:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      Select the cloud you are launching in
#     Required: true
#     Advanced: false
#     Possible Values:
#       - text:ec2
#       - text:google
#       - text:openstack
#   DATACENTER:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      Enter the Cloud Datacenter or availablity zone where you want to build the image
#     Required: true
#     Advanced: false
#   IMAGE_NAME:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      Enter the name of the new image to be created.
#     Required: true
#     Advanced: false
#   PLATFORM:
#     Input Type: single
#     Category: Cloud
#     Description: |
#       Select the platform of the Image you are building.
#     Required: true
#     Advanced: false
#     Possible Values:
#       - text:Linux
#       - text:Windows
#   SOURCE_IMAGE:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      Enter the Name or Resource ID of the base image to use.
#     Required: true
#     Advanced: false
#   AZURE_PUBLISHSETTINGS:
#     Input Type: single
#     Category: Azure
#     Description: |
#      The Azure Publishing settings
#     Required: false
#     Advanced: true
#   GOOGLE_ACCOUNT:
#     Input Type: single
#     Category: Google
#     Description: |
#      The Google Service Account JSON file.  This is best placed in a Credential
#     Required: false
#     Advanced: true
#   INSTANCE_TYPE:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      The cloud instance type to use to build the image
#     Required: true
#     Advanced: false
#   GOOGLE_PROJECT:
#     Input Type: single
#     Category: Google
#     Description: |
#      The Google project where to build the image.
#     Required: false
#     Advanced: true
#   GOOGLE_NETWORK:
#     Input Type: single
#     Category: Google
#     Description: |
#       The Google Compute network to use for the launched instance. Defaults to "default".
#     Required: false
#     Advanced: true
#   GOOGLE_SUBNETWORK:
#     Input Type: single
#     Category: Google
#     Description: |
#       The Google Compute subnetwork to use for the launced instance. Only required if the network has been created with custom subnetting. Note, the region of the subnetwork must match the region or zone in which the VM is launched.
#     Required: false
#     Advanced: true
#   RIGHTLINK_VERSION:
#     Input Type: single
#     Category: RightLink
#     Description: |
#       RightLink version number or branch name to install.  Leave blank to NOT bundle RightLink in the image
#     Required: false
#     Advanced: true
#   AZURE_STORAGE_ACCOUNT:
#     Input Type: single
#     Category: Azure
#     Description: |
#      Azure storage account used for images
#     Required: false
#     Advanced: true
#   AZURE_STORAGE_ACCOUNT_CONTAINER:
#     Input Type: single
#     Category: Azure
#     Description: |
#      Azure storage account container used for images
#     Required: false
#     Advanced: true
#   SSH_USERNAME:
#     Input Type: single
#     Category: Misc
#     Description: |
#      The user packer will use to SSH into the instance.  Examples: ubuntu, centos, ec2-user, root
#     Required: true
#     Advanced: true
#     Default: text:ubuntu
#   AWS_SUBNET_ID:
#     Input Type: single
#     Category: AWS
#     Description: |
#      The vpc subnet resource id to build image in.Enter a value if use a AWS VPC vs EC2-Classic
#     Required: false
#     Advanced: true
#   AWS_VPC_ID:
#     Input Type: single
#     Category: AWS
#     Description: |
#      The vpc resource id to build image in.  Enter a value if use a AWS VPC vs EC2-Classic
#     Required: false
#     Advanced: true
#   IMAGE_PASSWORD:
#     Input Type: single
#     Category: Misc
#     Description: |
#      Enter the Windows Administrator password to add to the Image.
#     Required: false
#     Advanced: true
#   OPENSTACK_USERNAME:
#     Input Type: single
#     Category: Openstack
#     Description: |
#      Enter the openstack username (required)
#     Required: false
#     Advanced: true
#   OPENSTACK_PASSWORD:
#     Input Type: single
#     Category: Openstack
#     Description: |
#      Enter the openstack password (required)
#     Required: false
#     Advanced: true
#   OPENSTACK_API_KEY:
#     Input Type: single
#     Category: Openstack
#     Description: |
#      The API key used to access OpenStack. Some OpenStack installations require this. (optional)
#     Required: false
#     Advanced: true
#   OPENSTACK_DOMAIN_NAME:
#     Input Type: single
#     Category: Openstack
#     Description: |
#      The Domain name you are authenticating with. OpenStack installations require this if identity v3 is used
#     Required: false
#     Advanced: true
#   OPENSTACK_ENDPOINT_TYPE:
#     Input Type: single
#     Category: Openstack
#     Description: |
#      The endpoint type to use. Can be any of "internal", "internalURL", "admin", "adminURL", "public", and "publicURL". By default this is "public".
#     Required: false
#     Advanced: true
#   OPENSTACK_REGION:
#     Input Type: single
#     Category: Openstack
#     Description: |
#      The name of the region, such as "DFW", in which to launch the server to create the image.  This is only used for Rackspace openstack cloud.
#     Required: false
#     Advanced: true
#   OPENSTACK_PROJECT_ID:
#     Input Type: single
#     Category: Openstack
#     Description: |
#      The Project ID to boot the instance into. Some OpenStack installations require this.
#     Required: false
#     Advanced: true
#   OPENSTACK_IDENTITY_ENDPOINT:
#     Input Type: single
#     Category: Openstack
#     Description: |
#      The URL to the OpenStack Identity service.
#     Required: false
#     Advanced: true
# ...

PACKER_DIR=/tmp/packer
PACKER_CONF=${PACKER_DIR}/packer.json

echo "Copying cloud config"
cp ${RS_ATTACH_DIR}/${CLOUD}.json ${PACKER_CONF}

# Common variables
echo "Configuring common variables"
sed -i "s#%%DATACENTER%%#$DATACENTER#g" ${PACKER_CONF}
sed -i "s#%%INSTANCE_TYPE%%#$INSTANCE_TYPE#g" ${PACKER_CONF}
sed -i "s#%%SSH_USERNAME%%#$SSH_USERNAME#g" ${PACKER_CONF}
sed -i "s#%%IMAGE_NAME%%#$IMAGE_NAME#g" ${PACKER_CONF}
sed -i "s#%%SOURCE_IMAGE%%#$SOURCE_IMAGE#g" ${PACKER_CONF}
sed -i "s#%%RIGHTLINK_VERSION%%#$RIGHTLINK_VERSION#g" rightlink.*

# Copy config files
echo "Copying scripts"
for file in *.sh *.ps1 *.txt; do
  cp ${RS_ATTACH_DIR}/${file} ${PACKER_DIR}
done

# Cloud-specific configuration
echo "Cloud-specific configuration"
case "$CLOUD" in
"azure")
  account_file=${PACKER_DIR}/publishsettings
  echo "$AZURE_PUBLISHSETTINGS" > $account_file

  shopt -s nocasematch
  if [[ $PLATFORM == "Windows" ]]; then
    os_type="Windows"
    provisioner='"type": "azure-custom-script-extension", "script_path": "rightlink.ps1"'
  else
    os_type="Linux"
    provisioner='"type": "shell", "scripts": [ "cloudinit.sh", "rightlink.sh", "azure.sh", "cleanup.sh" ]'
  fi
  sed -i "s#%%OS_TYPE%%#$os_type#g" ${PACKER_CONF}
  sed -i "s#%%PROVISIONER%%#$provisioner#g" ${PACKER_CONF}
  sed -i "s#%%STORAGE_ACCOUNT%%#$AZURE_STORAGE_ACCOUNT#g" ${PACKER_CONF}
  sed -i "s#%%CLIENT_ID%%#$CLIENT_ID#g" ${PACKER_CONF}
  sed -i "s#%%CLIENT_SECRET%%#$CLIENT_SECRET#g" ${PACKER_CONF}
  sed -i "s#%%SUBSCRIPTION_ID%%#$SUBSCRIPTION_ID#g" ${PACKER_CONF}
  sed -i "s#%%TENANT_ID%%#$TENANT_ID#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_PUBLISHER%%#$IMAGE_PUBLISHER#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_OFFER%%#$IMAGE_OFFER#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_SKU%%#$IMAGE_SKU#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_PREFIX%%#$IMAGE_PREFIX#g" ${PACKER_CONF}
  sed -i "s#%%SSH_USERNAME%%#$SSH_USERNAME#g" ${PACKER_CONF}
  sed -i "s#%%SSH_PASSWORD%%#$SSH_PASSWORD#g" ${PACKER_CONF}

  # Azure plugin requires this directory
  home=${HOME}
  user=${USER}
  dir=$home/.packer_azure
  sudo mkdir -p $dir && sudo chown $user $dir
  ;;
"ec2")
  shopt -s nocasematch
  if [[ $PLATFORM == "Windows" ]]; then
    communicator="winrm"
    provisioner='"type": "powershell", "scripts": ["rightlink.ps1"]'
    userdatafile='"user_data_file": "setup_winrm.txt",'
    winrmusername='"winrm_username": "Administrator",'
    sed -i "/\"ssh_pty\": true,/a $userdatafile" ${PACKER_CONF}
    sed -i "/\"ssh_pty\": true,/a $winrmusername" ${PACKER_CONF}
  else
    communicator="ssh"
    provisioner='"type": "shell", "scripts": [ "cloudinit.sh", "rightlink.sh", "cleanup.sh" ]'
  fi
  sed -i "s#%%BUILDER_TYPE%%#amazon-ebs#g" ${PACKER_CONF}
  sed -i "s#%%COMMUNICATOR%%#$communicator#g" ${PACKER_CONF}
  sed -i "s#%%PROVISIONER%%#$provisioner#g" ${PACKER_CONF}

  if [ ! -z "$AWS_VPC_ID" ]; then
    sed -i "s#%%VPC_ID%%#$AWS_VPC_ID#g" ${PACKER_CONF}
  else
    sed -i "/%%VPC_ID%%/d" ${PACKER_CONF}
  fi

  if [ ! -z "$AWS_SUBNET_ID" ]; then
    sed -i "s#%%SUBNET_ID%%#$AWS_SUBNET_ID#g" ${PACKER_CONF}
  else
    sed -i "/%%SUBNET_ID%%/d" ${PACKER_CONF}
  fi

  ;;
"google")
  shopt -s nocasematch
  if [[ $PLATFORM == "Windows" ]]; then
    communicator="winrm"
    disk_size="50"
    provisioner='"type": "powershell", "scripts": ["rightlink.ps1","scriptpolicy.ps1"]'
  else
    communicator="ssh"
    disk_size="10"
    provisioner='"type": "shell", "scripts": [ "cloudinit.sh", "rightlink.sh", "cleanup.sh" ]'
  fi
  sed -i "s#%%DISK_SIZE%%#$disk_size#g" ${PACKER_CONF}

  account_file=${PACKER_DIR}/account.json
  echo "$GOOGLE_ACCOUNT" > $account_file

  sed -i "s#%%ACCOUNT_FILE%%#$account_file#g" ${PACKER_CONF}
  sed -i "s#%%PROJECT%%#$GOOGLE_PROJECT#g" ${PACKER_CONF}
  sed -i "s#%%COMMUNICATOR%%#$communicator#g" ${PACKER_CONF}
  sed -i "s#%%PROVISIONER%%#$provisioner#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_PASSWORD%%#$IMAGE_PASSWORD#g" ${PACKER_CONF}
  sed -i "s#%%GOOGLE_NETWORK%%#$GOOGLE_NETWORK#g" ${PACKER_CONF}
  sed -i "s#%%GOOGLE_SUBNETWORK%%#$GOOGLE_SUBNETWORK#g" ${PACKER_CONF}

  SOURCE_IMAGE=`echo $SOURCE_IMAGE | rev | cut -d'/' -f1 | rev`
  ;;
  "openstack")
  shopt -s nocasematch
  if [[ $PLATFORM == "Windows" ]]; then
    communicator="winrm"
    provisioner='"type": "powershell", "scripts": ["rightlink.ps1"]'
    userdatafile='"user_data_file": "setup_winrm.txt",'
    sed -i "/\"ssh_pty\": true,/a $userdatafile" ${PACKER_CONF}
  else
    communicator="ssh"
    provisioner='"type": "shell", "scripts": [ "cloudinit.sh", "rightlink.sh", "cleanup.sh" ]'
  fi
  sed -i "s#%%COMMUNICATOR%%#$communicator#g" ${PACKER_CONF}
  sed -i "s#%%PROVISIONER%%#$provisioner#g" ${PACKER_CONF}
  sed -i "s#%%USERNAME%%#$OPENSTACK_USERNAME#g" ${PACKER_CONF}
  sed -i "s#%%PASSWORD%%#$OPENSTACK_PASSWORD#g" ${PACKER_CONF}
  sed -i "s#%%API_KEY%%#$OPENSTACK_API_KEY#g" ${PACKER_CONF}
  sed -i "s#%%DOMAIN_NAME%%#$OPENSTACK_DOMAIN_NAME#g" ${PACKER_CONF}
  sed -i "s#%%REGION%%#$OPENSTACK_REGION#g" ${PACKER_CONF}
  sed -i "s#%%TENANT_ID%%#$OPENSTACK_PROJECT_ID#g" ${PACKER_CONF}
  sed -i "s#%%IDENTITY_ENDPOINT%%#$OPENSTACK_IDENTITY_ENDPOINT#g" ${PACKER_CONF}
  sed -i "s#%%ENDPOINT_TYPE%%#$OPENSTACK_ENDPOINT_TYPE#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_PASSWORD%%#$IMAGE_PASSWORD#g" ${PACKER_CONF}
esac
