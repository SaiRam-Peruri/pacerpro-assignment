# PacerPro Assignment - Automated EC2 Remediation

An automated remediation system that monitors application latency using Sumo Logic and automatically restarts EC2 instances when high latency is detected, with email notifications via SNS and Sumo logic Email notification.

## Overview

This project implements an **auto-remediation workflow** that:

1. **Monitors** application performance metrics (latency, response times) using Sumo Logic
2. **Detects** high latency events through a Sumo Logic webhook
3. **Triggers** an AWS Lambda function to automatically restart the problematic EC2 instance
4. **Notifies** administrators via SNS email when remediation occurs

## Architecture

```
Sumo Logic (Monitoring)
        ↓
   Webhook Event
        ↓
AWS Lambda Function (Remediation)
        ↓
   ┌────────────┬──────────────┐
   ↓            ↓              ↓
EC2 Reboot   SNS Topic      CloudWatch Logs
   (Auto-fix) (Email Alert)  (Audit Trail)
```

## Components

### Lambda Function (`lambda_function/lambda_function.py`)

- **Runtime**: Python 3.13
- **Trigger**: Sumo Logic Webhook (HTTP POST)
- **Actions**:
  - Receives high latency alert from Sumo Logic
  - Reboots the EC2 instance specified in the alert
  - Publishes notification to SNS topic
  - Logs all actions to CloudWatch

### Infrastructure (Terraform)

#### AWS Resources Provisioned:

1. **EC2 Instance** (`ec2.tf`)
   - Sample EC2 instance for remediation testing
   - Security group allowing SSH and application traffic

2. **IAM Role & Policy** (`iam-role.tf`)
   - Lambda execution role with permissions to:
     - Reboot EC2 instances
     - Publish to SNS
     - Write logs to CloudWatch

3. **Lambda Function** (`lambda.tf`)
   - Lambda function with HTTP URL endpoint for Sumo Logic webhook
   - Environment variables for instance ID and SNS topic ARN

4. **SNS Topic** (`sns.tf`)
   - Topic for sending email alerts
   - Email subscription for notifications

5. **VPC** (`vpc.tf`)
   - Virtual Private Cloud setup
   - Subnets and routing configuration

6. **Provider & Variables** (`provider.tf`, `variable.tf`)
   - AWS provider configuration
   - Input variables for customization

7. **Outputs** (`outputs.tf`)
   - Lambda function URL (webhook endpoint for Sumo Logic)
   - SNS topic ARN
   - EC2 instance ID

## Prerequisites

- **AWS Account** with appropriate permissions
- **Terraform** >= 1.0
- **AWS CLI** configured with valid credentials
- **Sumo Logic Account** for log monitoring
- **Python 3.13+** (for local testing)

## Setup & Deployment

### 1. Configure AWS Credentials

```powershell
aws configure
# Enter your AWS Access Key ID and Secret Access Key
```

### 2. Navigate to Terraform Directory

```powershell
cd terraform
```

### 3. Initialize Terraform

```powershell
terraform init
```

### 4. Review the Plan

```powershell
terraform plan
```

### 5. Deploy Infrastructure

```powershell
terraform apply
```

When prompted, review and confirm the changes. Terraform will create:
- EC2 instance
- Lambda function with webhook URL
- SNS topic with email subscription
- IAM roles and policies

### 6. Configure Sumo Logic Webhook

1. Log in to Sumo Logic Console
2. Create/edit a monitor for high latency detection
3. Add a webhook notification with the Lambda Function URL:
   - Get the URL from Terraform outputs: `terraform output lambda_url`
   - URL format: `https://<function-url-id>.lambda-url.us-east-1.on.aws/`
4. Configure the webhook payload to include `instance_id`

### 7. Confirm SNS Email Subscription

- Check your email for SNS subscription confirmation
- Click the confirmation link to enable email notifications

## Usage

### Testing the System

**Trigger Lambda manually:**
```powershell
curl -X POST https://<your-lambda-url> -H "Content-Type: application/json" -d '{"instance_id": "i-xxxxx"}'
```

**Monitor CloudWatch Logs:**
```powershell
aws logs tail /aws/lambda/PacerPro_Remediation_Function --follow
```

**Check EC2 Instance Status:**
```powershell
aws ec2 describe-instances --instance-ids <instance-id> --query 'Reservations[0].Instances[0].State'
```

## Configuration

### Environment Variables (Set by Terraform)

The Lambda function uses these environment variables:
- `INSTANCE_ID`: EC2 instance to reboot
- `SNS_TOPIC_ARN`: SNS topic for notifications

To modify these, update `terraform/lambda.tf`:
```terraform
environment {
  variables = {
    INSTANCE_ID    = aws_instance.sample_instance.id
    SNS_TOPIC_ARN  = aws_sns_topic.remediation_alerts.arn
  }
}
```

## Monitoring & Logs

### CloudWatch Logs

View Lambda execution logs:
```powershell
aws logs describe-log-groups --log-group-name-prefix /aws/lambda
aws logs tail /aws/lambda/PacerPro_Remediation_Function --follow
```

### Sumo Logic Query

The `sumo_logic_query.json` file contains sample query data showing:
- API endpoint latency metrics
- Response times (in seconds)
- HTTP status codes
- Source EC2 instance IDs

**Example query for high latency detection:**
```
_sourceHost = "i-05311dc6d84b80b50" AND response_time > 3.0
| stats avg(response_time) as avg_latency by url
```

## Security Considerations

1. **Principle of Least Privilege**: Lambda role has minimal required permissions
2. **No Public Data Exposure**: Lambda function doesn't expose sensitive EC2 data
3. **Email Notifications**: Only subscribed emails receive alerts
4. **VPC Isolation**: EC2 instance runs in private VPC (optional enhancement)

## Cleanup

To remove all AWS resources and avoid charges:

```powershell
cd terraform
terraform destroy
```

Type `yes` when prompted to confirm deletion.

## Troubleshooting

### Lambda Function Shows Errors

Check CloudWatch logs:
```powershell
aws logs tail /aws/lambda/PacerPro_Remediation_Function
```

### EC2 Instance Not Rebooting

1. Verify Lambda has EC2 reboot permissions in IAM policy
2. Confirm `INSTANCE_ID` environment variable is set correctly
3. Check EC2 instance state in AWS Console

### SNS Emails Not Received

1. Confirm email subscription in SNS console
2. Check email spam folder
3. Verify SNS topic ARN is correct in Lambda environment

### Terraform Plan Fails with Invalid Credentials

```powershell
aws sts get-caller-identity
```

If this fails, reconfigure AWS credentials:
```powershell
aws configure
```

## Files & Structure

```
pacerpro-assignment/
├── README.md                          # This file
├── sumo_logic_query.json             # Sample Sumo Logic query data
├── lambda_function/
│   └── lambda_function.py            # Lambda handler code
└── terraform/
    ├── provider.tf                   # AWS provider configuration
    ├── variable.tf                   # Input variables
    ├── ec2.tf                        # EC2 instance definition
    ├── iam-role.tf                   # IAM role & policy
    ├── lambda.tf                     # Lambda function & URL
    ├── sns.tf                        # SNS topic & subscriptions
    ├── vpc.tf                        # VPC configuration
    └── outputs.tf                    # Output values
```

## Future Enhancements

- [ ] Support multiple EC2 instances
- [ ] Add metrics-based thresholds (configurable latency limits)
- [ ] Implement cooldown period to prevent frequent reboots
- [ ] Add Slack notifications alongside email
- [ ] Create API to manage monitored instances
- [ ] Add rollback mechanism if reboot fails
- [ ] Implement auto-scaling based on latency

## Contributing

To contribute improvements:

1. Create a feature branch
2. Make changes and test thoroughly
3. Submit a pull request with description

## License

This project is provided as-is for educational and operational purposes.

## Support

For issues or questions:
1. Check CloudWatch logs for error details
2. Review Terraform output for resource details
3. Verify AWS permissions and credentials
4. Consult AWS Lambda and EC2 documentation
