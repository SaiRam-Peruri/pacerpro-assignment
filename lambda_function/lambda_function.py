import boto3
import os
import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
ec2 = boto3.client('ec2')
sns = boto3.client('sns')

def lambda_handler(event, context):
    """
    Triggered by Sumo Logic Webhook.
    Restarts the EC2 instance and sends an SNS notification.
    """
    
    # 1. Retrieve Environment Variables (Set by Terraform)
    instance_id = os.environ.get('INSTANCE_ID')
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')

    logger.info(f"Received event: {json.dumps(event)}")
    
    if not instance_id or not sns_topic_arn:
        logger.error("Missing environment variables: INSTANCE_ID or SNS_TOPIC_ARN")
        return {"statusCode": 500, "body": "Configuration Error"}

    try:
        # 2. Reboot the EC2 Instance
        logger.info(f"Initiating reboot for instance: {instance_id}")
        ec2.reboot_instances(InstanceIds=[instance_id])
        
        # 3. Construct the Notification Message
        message = (
            f"ALERT: High Latency Detected via Sumo Logic.\n"
            f"ACTION: Automated Remediation Triggered.\n"
            f"DETAILS: Successfully sent reboot command to EC2 Instance: {instance_id}.\n"
            f"Please verify application health in 5 minutes."
        )
        
        # 4. Send Notification to SNS (Email)
        logger.info(f"Publishing notification to SNS: {sns_topic_arn}")
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject="[Auto-Remediation] EC2 Instance Rebooted",
            Message=message
        )
        
        return {
            "statusCode": 200,
            "body": json.dumps("Reboot initiated and notification sent.")
        }

    except Exception as e:
        logger.error(f"Error executing remediation: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error: {str(e)}")
        }