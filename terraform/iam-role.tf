
# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "pacerpro_lambda_remediation_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}


# IAM Policy (Least Privilege)
resource "aws_iam_policy" "lambda_policy" {
  name        = "pacerpro_lambda_policy"
  description = "Permissions to reboot specific EC2 and publish to SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = "ec2:RebootInstances"
        # Restrict permission to ONLY the specific instance created above
        Resource = aws_instance.web_server.arn 
      },
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts_topic.arn
      }
    ]
  })
}