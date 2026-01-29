output "instance_id" {
  value = aws_instance.web_server.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts_topic.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.remediation_function.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.remediation_function.arn
}

# Output the URL so you can copy it easily
output "function_url" {
  value = aws_lambda_function_url.remediation_url.function_url
}