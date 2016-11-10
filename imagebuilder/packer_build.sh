#! /bin/bash -ex

# ---
# RightScript Name: Packer Build v1
# Description: |
#   Use Packer to build the image
# Inputs:
#   GOOGLE_PROJECT:
#     Category: Google
#     Description: |
#       The name of the Google project your Rightscale account is connected to.
#     Input Type: single
#     Required: false
#     Advanced: true
#   AWS_SECRET_KEY:
#     Category: AWS
#     Description: |
#       AWS Secret Key
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: cred:AWS_SECRET_ACCESS_KEY
#   AWS_ACCESS_KEY:
#     Category: AWS
#     Description: |
#       AWS Access Key
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: cred:AWS_ACCESS_KEY_ID
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
# Attachments: []
# ...

PACKER_DIR=/tmp/packer

cd ${PACKER_DIR}
./packer version
./packer validate packer.json
./packer build -machine-readable packer.json | tee build.log
image_id=""

case "$CLOUD" in
"googlecompute")
  image_id="projects/$GOOGLE_PROJECT/images/$image_id"
  ;;
"softlayer")
  image_id=`grep --binary-files=text 'artifact,0,string' build.log | cut -d, -f6 | grep -o -E "\(.*" | sed 's/(//' | sed 's/)//'`
  ;;
"azurerm")
  image_id=`grep --binary-files=text 'artifact,0,string' build.log | awk -F\\\\ '{ print $4 }' | cut -d\   -f2`
  image_json=`grep --binary-files=text 'artifact,0,string' build.log | awk -F\\\\ '{ print $6 }' | cut -d\   -f2`
  echo $image_id
  echo $image_json
  echo "{\"$image_json\": {}}" | sudo tee -a /root/rightimage_id_list >/dev/null  
  ;;
esac

test -z "$image_id" && echo "Build failed. See build log at ${PACKER_DIR}/build.log " && exit 1
echo "{\"$image_id\": {}}" | sudo tee /root/rightimage_id_list >/dev/null
