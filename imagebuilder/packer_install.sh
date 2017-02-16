#! /bin/bash -ex

# ---
# RightScript Name: Packer Install
# Description: |
#   Install Packer
# Inputs:
#   CLOUD:
#     Category: Cloud
#     Description: |
#       Select the cloud you are launching in
#     Input Type: single
#     Required: true
#     Advanced: false
#     Possible Values:
#     - text:ec2
#     - text:google
#     - text:azurerm
# Attachments: []
# ...

PACKER_DIR=/tmp/packer
PACKER_VERSION=0.10.2

mkdir -p ${PACKER_DIR}

# Softlayer plugin requires Packer installation via source
[ "$CLOUD" == "softlayer" ] && exit 0

sudo apt-get -y update
sudo apt-get -y install unzip

cd ${PACKER_DIR}

packer_zip="packer_${PACKER_VERSION}_linux_amd64.zip"
wget -N -c -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/${packer_zip}
unzip $packer_zip -d ${PACKER_DIR}
