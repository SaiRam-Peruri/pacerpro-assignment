data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda_function"
  output_path = "${path.module}/lambda_payload.zip"
}


# 1. Create the Function URL
resource "aws_lambda_function_url" "remediation_url" {
  function_name      = aws_lambda_function.remediation_function.function_name
  authorization_type = "NONE"
}


resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# The Lambda Function itself
resource "aws_lambda_function" "remediation_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "PacerPro_Remediation_Function"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID   = aws_instance.web_server.id
      SNS_TOPIC_ARN = aws_sns_topic.alerts_topic.arn
    }
  }
}