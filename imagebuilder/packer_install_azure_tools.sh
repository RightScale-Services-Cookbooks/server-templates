#! /usr/bin/sudo /bin/bash

# ---
# RightScript Name: Packer Install Azure Tools
# Description: |
#   Install Azure tools for Packer
# Inputs:
#   AZURERM_CLIENT_ID:
#     Category: AzureRM
#     Description: |
#       Azure username
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_CLIENT_SECRET:
#     Category: AzureRM
#     Description: |
#       Azure password
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_SUBSCRIPTION_ID:
#     Category: AzureRM
#     Description: |
#       Azure subscription id
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_TENANT_ID:
#     Category: AzureRM
#     Description: |
#       Azure subscription id
#     Input Type: single
#     Required: false
#     Advanced: true
# Attachments: []
# ...

set -ex

apt-get -y update
apt-get -y install nodejs-legacy npm
# 0.9.3-0.9.13 have various problems
npm install -g azure-cli@0.9.2

azure config mode arm
azure login --service-principal -u $AZURERM_CLIENT_ID -p $AZURERM_CLIENT_SECRET --tenant $TENANT_ID
azure account set $AZURE_SUBSCRIPTION_ID
