#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Update R53 A Record
# Description: Updates an R53 A record
# Inputs:
#   R53_HOSTED_ZONE_ID:
#     Category: R53
#     Description: Hosted Zone ID
#     Input Type: single
#     Required: true
#     Advanced: false
#   R53_TTL:
#     Category: R53
#     Description: A record TTL
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:60
#   FQDN:
#     Category: R53
#     Description: FQDN of the instance. (e.g. myserver.example.tld)
#     Input Type: single
#     Required: true
#     Advanced: false
#   IPADDRESS:
#     Category: R53
#     Description: IP Address of the instance.
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: env:PRIVATE_IP
# Attachments: []
# ...
echo "Installing awscli"
apt-get install -y awscli

cat << EOF > /tmp/r53.json
{
  "Comment": "optional comment about the changes in this change batch request",
  "Changes": [
              {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                  "Name": "$FQDN",
                  "Type": "A",
                  "TTL": $R53_TTL,
                  "ResourceRecords": [
                    {
                      "Value": "$IPADDRESS"
                    }
                  ]
                }
              }
  ]
}
EOF

aws route53 --region us-west-2 change-resource-record-sets --hosted-zone-id $R53_HOSTED_ZONE_ID --change-batch file:///tmp/r53.json
if [ $? -eq 0 ]; then
  echo "$FQDN A record set to $IPADDRESS"
else
  echo "Error setting $FQDN"
  exit 1
fi
rm -rf /tmp/r53.json
