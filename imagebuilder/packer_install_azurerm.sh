#! /bin/bash -ex

# ---
# RightScript Name: Packer Install tools for ARM
# Description: |
#   Install the tools for Packer and ARM
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
#       - text:azurerm
# ...

if [ "$CLOUD" == "azurerm" ];then
  PACKER_DIR=/tmp/packer
  PACKER_VERSION=0.9.0
  mkdir -p ${PACKER_DIR}
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get -y update
  sudo apt-get -y install unzip
  cd ${PACKER_DIR}
  packer_zip="packer_${PACKER_VERSION}_linux_amd64.zip"
  wget https://privatecloudtools.s3.amazonaws.com/packer
  chmod +x /tmp/packer/packer
fi
