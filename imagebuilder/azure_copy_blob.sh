#! /bin/bash
# ---
# RightScript Name: Azure RM Copy Image
# Description: Copy Azure Image from one storage account to another
# Inputs:
#   IMAGE_NAME:
#     Category: Cloud
#     Input Type: single
#     Required: true
#     Advanced: false
#   AZURERM_STORAGE_ACCOUNT:
#     Category: AzureRM
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_STORAGE_ACCOUNT_KEY:
#     Category: AzureRM
#     Description: Azure storage access key - Source
#     Input Type: single
#     Required: false
#     Advanced: true
#   AZURERM_CLIENT_ID:
#     Category: AzureRM
#     Input Type: single
#     Required: true
#     Advanced: true
#   AZURERM_CLIENT_SECRET:
#     Category: AzureRM
#     Input Type: single
#     Required: true
#     Advanced: true
#   AZURERM_TENANT_ID:
#     Category: AzureRM
#     Input Type: single
#     Required: true
#     Advanced: true
# Attachments: []
# ...

# Original image name to copy

azure config mode arm
azure login --service-principal -u $AZURERM_CLIENT_ID -p $AZURERM_CLIENT_SECRET --tenant $AZURERM_TENANT_ID
vhd_uri_vhd=`sudo grep -o "\".*\.vhd\"" /root/rightimage_id_list | sed 's/"//g' | cut -d/ -f8`
vhd_uri_json=`sudo grep -o "\".*\.json\"" /root/rightimage_id_list | sed 's/"//g' | cut -d/ -f8`
final_image_vhd="${IMAGE_NAME}-save-osDisk.vhd"
final_image_json="${IMAGE_NAME}-save-vmTemplate.json"
echo $vhd_uri_vhd
echo $vhd_uri_json
echo $final_image_vhd
echo $final_image_json

function blob_copy_status {
  # Just because the blob exists doesn't mean it's finished yet
  res=`azure storage blob copy show --container system --account-name "$AZURERM_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_ACCOUNT_KEY" --blob Microsoft.Compute/Images/vhds/"${final_image_vhd}"`
  # Piping azure command through grep causes a broken pipe error.
  [[ $res =~ "success" ]]
}

function blob_list {
  res=`azure storage blob list --container system --account-name "$AZURERM_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_ACCOUNT_KEY" *"${final_image_vhd}"`
  [[ $res =~ ${IMAGE_NAME} ]]
}

function wait_for_blob {
  i=0
  while [ $i -lt 60 ]; do
    blob_copy_status && break
    sleep 60
    i=$[$i+1]
  done
}

set -ex

if blob_list; then
  echo "Blob already exists in destination location"
  wait_for_blob
else
  azure storage blob copy start --account-name "$AZURERM_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_ACCOUNT_KEY" \
  https://armwestus.blob.core.windows.net/system/Microsoft.Compute/Images/vhds/${vhd_uri_vhd} system --dest-blob Microsoft.Compute/Images/vhds/$final_image_vhd
  azure storage blob copy start --account-name "$AZURERM_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_ACCOUNT_KEY" \
  https://armwestus.blob.core.windows.net/system/Microsoft.Compute/Images/vhds/${vhd_uri_json} system --dest-blob Microsoft.Compute/Images/vhds/$final_image_json
  wait_for_blob
  echo "{\"https://armwestus.blob.core.windows.net/system/Microsoft.Compute/Images/vhds/${final_image_vhd}\": {}}" | sudo tee /root/rightimage_id_list >/dev/null
fi

if [ "${vhd_image_vhd}" == "${final_image_vhd}" ]; then
  echo "Protecting against script re-run. Skipping image deletion."
else
  azure storage blob delete --account-name "$AZURERM_STORAGE_ACCOUNT" --account-key "$AZURERM_STORAGE_ACCOUNT_KEY" system Microsoft.Compute/Images/vhds/${vhd_uri_vhd}
  azure storage blob delete --account-name "$AZURERM_STORAGE_ACCOUNT" --account-key "$AZURERM_STORAGE_ACCOUNT_KEY" system Microsoft.Compute/Images/vhds/${vhd_uri_json}
fi
