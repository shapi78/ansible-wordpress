#!/bin/bash


ZONE_NAME="aws.cts.care."
TTL=300


IP=$(curl -s http://checkip.amazonaws.com)
if [[ -z "$IP" ]]; then
    echo "Could not retrieve public IP."
    exit 1
fi
echo "Current public IP: $IP"

ROUTE53_ZONE_ID=$(/usr/local/bin/aws route53 list-hosted-zones \
  --query "HostedZones[?Name == '$ZONE_NAME'].Id" \
  --output text)

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

if [[ -z "$TOKEN" ]]; then
    echo "Could not get IMDSv2 token."
    exit 1
fi


INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

if [[ -z "$INSTANCE_ID" ]]; then
    echo "Could not retrieve instance ID."
    exit 1
fi
echo "Instance ID: $INSTANCE_ID"

RECORD_NAME=$(aws ec2 describe-tags \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" \
  --query "Tags[0].Value" --output text)

if [[ -z "$RECORD_NAME" ]]; then
    echo "Could not retrieve Name tag from EC2."
    exit 1
fi


RECORD_NAME="${RECORD_NAME}.${ZONE_NAME}"
echo "Dynamic DNS Name: $RECORD_NAME"


CHANGE_BATCH=$(cat <<EOF
{
  "Comment": "Auto-updated A record from EC2 instance",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "A",
        "TTL": $TTL,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}
EOF
)


aws route53 change-resource-record-sets \
  --hosted-zone-id "$ROUTE53_ZONE_ID" \
  --change-batch "$CHANGE_BATCH"

if [[ $? -eq 0 ]]; then
    echo " Route 53 record updated "
else
    echo  "Failed to update Route 53 record."
fi