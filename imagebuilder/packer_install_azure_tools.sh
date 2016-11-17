#! /usr/bin/sudo /bin/bash

# ---
# RightScript Name: Packer Install Azure Tools
# Description: |
#   Install Azure tools for Packer
# Inputs:
#   AZURERM_CLIENT_ID:
#     Category: AzureRM
#     Description: |
#       The Active Directory service principal associated with your builder.
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_CLIENT_SECRET:
#     Category: AzureRM
#     Description: |
#       The password or secret for your service principal.
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
#   AZURERM_SUBSCRIPTION_ID:
#     Category: AzureRM
#     Description: |
#       Subscription under which the build will be performed. The service principal specified in client_id must have full access to this subscription.
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
