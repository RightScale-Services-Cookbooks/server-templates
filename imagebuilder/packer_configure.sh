#! /bin/bash -e

# ---
# RightScript Name: SPOM - Packer Configure
# Description: |
#   Create the Packer JSON file.
# Inputs:
#   SSH_USERNAME:
#     Category: Misc
#     Description: |
#       The user packer will use to SSH into the instance.  Examples: ubuntu, centos, ec2-user, root
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:ubuntu
#   CLOUD:
#     Category: Cloud
#     Description: Select the cloud you are launching in
#     Input Type: single
#     Required: true
#     Advanced: false
#     Possible Values:
#     - text:ec2
#     - text:google
#     - text:azurerm
#   DATACENTER:
#     Category: Cloud
#     Description: Enter the Cloud Datacenter or availablity zone where you want to
#       build the image
#     Input Type: single
#     Required: true
#     Advanced: false
#   IMAGE_NAME:
#     Category: Cloud
#     Description: Enter the name of the new image to be created.
#     Input Type: single
#     Required: true
#     Advanced: false
#   GOOGLE_ACCOUNT:
#     Category: Google
#     Description: The Google Service Account JSON file.  This is best placed in a Credential
#     Input Type: single
#     Required: false
#     Advanced: true
#   INSTANCE_TYPE:
#     Category: Cloud
#     Description: The cloud instance type to use to build the image
#     Input Type: single
#     Required: true
#     Advanced: false
#   GOOGLE_PROJECT:
#     Category: Google
#     Description: The Google project where to build the image.
#     Input Type: single
#     Required: false
#     Advanced: true
#   IMAGE_PASSWORD:
#     Category: Misc
#     Description: Enter a password on the image
#     Input Type: single
#     Required: false
#     Advanced: true
#   RIGHTLINK_VERSION:
#     Category: RightLink
#     Description: RightLink version number or branch name to install.  Leave blank
#       to NOT bundle RightLink in the image
#     Input Type: single
#     Required: false
#     Advanced: true
#   GOOGLE_NETWORK:
#     Category: Google
#     Description: The Google Compute network to use for the launched instance. Defaults
#       to "default".
#     Input Type: single
#     Required: false
#     Advanced: true
#   GOOGLE_SUBNETWORK:
#     Category: Google
#     Description: The Google Compute subnetwork to use for the launced instance. Only
#       required if the network has been created with custom subnetting. Note, the region
#       of the subnetwork must match the region or zone in which the VM is launched.
#     Input Type: single
#     Required: false
#     Advanced: true
#   AWS_SUBNET_ID:
#     Category: AWS
#     Description: The vpc subnet resource id to build image in.Enter a value if use
#       a AWS VPC vs EC2-Classic
#     Input Type: single
#     Required: false
#     Advanced: true
#   AWS_VPC_ID:
#     Category: AWS
#     Description: The vpc resource id to build image in.  Enter a value if use a AWS
#       VPC vs EC2-Classic
#     Input Type: single
#     Required: false
#     Advanced: true
#   PLATFORM:
#     Category: Cloud
#     Description: Select the platform of the Image you are building.
#     Input Type: single
#     Required: true
#     Advanced: false
#     Possible Values:
#     - text:Linux
#     - text:Windows
#   AZURERM_CLIENT_ID:
#     Category: AzureRM
#     Description: Azure client id
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_CLIENT_SECRET:
#     Category: AzureRM
#     Description: Azure client secret
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_SUBSCRIPTION_ID:
#     Category: AzureRM
#     Description: Azure subscription id
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_TENANT_ID:
#     Category: AzureRM
#     Description: Azure tenant id
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_IMAGE_PUBLISHER:
#     Category: AzureRM
#     Description: The Azure Image Publisher name
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_IMAGE_OFFER:
#     Category: AzureRM
#     Description: The Azure Image Offer name
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_IMAGE_SKU:
#     Category: AzureRM
#     Description: The Azure Image SKU name
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_RESOURCE_GROUP:
#     Category: AzureRM
#     Description: Azure resource group where the artifact will be stored
#     Input Type: single
#     Required: false
#     Advanced: true
#   SOURCE_IMAGE:
#     Category: Cloud
#     Description: Enter the Name or Resource ID of the base image to use. For AzureRM,
#       this value is ignored.
#     Input Type: single
#     Required: true
#     Advanced: false
#   AZURERM_STORAGE_ACCOUNT:
#     Category: AzureRM
#     Description: Azure storage account where the artifact will be stored. Shoule be
#       within the AZURERM_RESOURCE_GROUP.
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_SPN_OBJECT_ID:
#     Category: AzureRM
#     Description: Azure Service Principal ID
#     Input Type: single
#     Required: false
#     Advanced: true
# Attachments:
# - azure.sh
# - ec2.json
# - rightlink.ps1
# - rs-cloudinit.sh
# - scriptpolicy.ps1
# - cleanup.sh
# - cloudinit.sh
# - rightlink.sh
# - softlayer.json
# - google.json
# - setup_winrm.txt
# - azurerm.json
# - azuresm.json
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
sed -i "s#%%RIGHTLINK_VERSION%%#$RIGHTLINK_VERSION#g" rightlink.*

# Copy config files
echo "Copying scripts"
for file in *.sh *.ps1 *.txt; do
  cp ${RS_ATTACH_DIR}/${file} ${PACKER_DIR}
done

# Cloud-specific configuration
echo "Cloud-specific configuration"
case "$CLOUD" in
"azurerm")
  #Azure Resource Manager
  
  #Set specific Azure path so images are discovered by RS
  #AZURERM_CONTAINER_NAME='Microsoft.Compute/Images/vhds'
  AZURERM_CONTAINER_NAME='vhds'
  
  shopt -s nocasematch
  if [[ $PLATFORM == "Windows" ]]; then
    communicator="winrm"
    os_type="Windows"
    provisioner='"type": "powershell", "scripts": ["rightlink.ps1"]'
    sed -i "s#%%SPN_OBJECT_ID%%#$AZURERM_SPN_OBJECT_ID#g" ${PACKER_CONF}
    #provisioner='"type": "azure-custom-script-extension", "script_path": "rightlink.ps1"'
    #winrmusessl='"winrm_use_ssl": "true",'
    #winrminsecure='"winrm_insecure": "true",'
    #winrmtimeout='"winrm_timeout": "3m",'
    #winrmusername='"winrm_username": "Administrator",'
    #sed -i "/\"ssh_pty\": true,/a $winrmusessl" ${PACKER_CONF}
    #sed -i "/\"ssh_pty\": true,/a $winrminsecure" ${PACKER_CONF}
    #sed -i "/\"ssh_pty\": true,/a $winrmtimeout" ${PACKER_CONF}
    #sed -i "/\"ssh_pty\": true,/a $winrmusername" ${PACKER_CONF}
  else
    communicator="ssh"
    os_type="Linux"
    sed -i "/%%SPN_OBJECT_ID%%/d" ${PACKER_CONF}
    provisioner='"type": "shell", "scripts": [ "cloudinit.sh", "rightlink.sh", "azure.sh", "cleanup.sh" ]'
  fi
  sed -i "s#%%CLIENT_ID%%#$AZURERM_CLIENT_ID#g" ${PACKER_CONF}
  sed -i "s#%%CLIENT_SECRET%%#$AZURERM_CLIENT_SECRET#g" ${PACKER_CONF}
  sed -i "s#%%SUBSCRIPTION_ID%%#$AZURERM_SUBSCRIPTION_ID#g" ${PACKER_CONF}
  sed -i "s#%%TENANT_ID%%#$AZURERM_TENANT_ID#g" ${PACKER_CONF} #Still needed?
  sed -i "s#%%RESOURCE_GROUP_NAME%%#$AZURERM_RESOURCE_GROUP#g" ${PACKER_CONF}
  sed -i "s#%%STORAGE_ACCOUNT%%#$AZURERM_STORAGE_ACCOUNT#g" ${PACKER_CONF}
  sed -i "s#%%CAPTURE_CONTAINER_NAME%%#$AZURERM_CONTAINER_NAME#g" ${PACKER_CONF}
  #sed -i "s#%%CAPTURE_NAME_PREFIX%%#$IMAGE_PREFIX#g" ${PACKER_CONF}
  sed -i "s#%%OS_TYPE%%#$os_type#g" ${PACKER_CONF}
  #sed -i "s#%%LOCATION%%#$DATACENTER#g" ${PACKER_CONF}
  #sed -i "s#%%VM_SIZE%%#$INSTANCE_TYPE#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_PUBLISHER%%#$AZURERM_IMAGE_PUBLISHER#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_OFFER%%#$AZURERM_IMAGE_OFFER#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_SKU%%#$AZURERM_IMAGE_SKU#g" ${PACKER_CONF}
  sed -i "s#%%COMMUNICATOR%%#$communicator#g" ${PACKER_CONF}
  #sed -i "s#%%IMAGE_PASSWORD%%#$IMAGE_PASSWORD#g" ${PACKER_CONF}
  #sed -i "s#%%SSH_USERNAME%%#$SSH_USERNAME#g" ${PACKER_CONF}
  #sed -i "s#%%SSH_PASSWORD%%#$SSH_PASSWORD#g" ${PACKER_CONF}
  sed -i "s#%%PROVISIONER%%#$provisioner#g" ${PACKER_CONF}
  ;;
"ec2")
  shopt -s nocasematch
  if [[ $PLATFORM == "Windows" ]]; then
    communicator="winrm"
    provisioner='"type": "powershell", "scripts": ["rightlink.ps1"]'
    userdatafile='"user_data_file": "setup_winrm.txt",'
    winrmusername='"winrm_username": "Administrator",'
    #sed -i "/\"ssh_pty\": true,/a $userdatafile" ${PACKER_CONF}
    #sed -i "/\"ssh_pty\": true,/a $winrmusername" ${PACKER_CONF}
    sed -i "s#%%WINRMUSERNAME%%#$userdatafile#g" ${PACKER_CONF}
    sed -i "s#%%USERDATAFILE%%#$winrmusername#g" ${PACKER_CONF}
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
esac

sed -i "s#%%SOURCE_IMAGE%%#$SOURCE_IMAGE#g" ${PACKER_CONF}
