resource "aws_sns_topic" "alerts_topic" {
  name = "high-latency-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol  = "email"
  endpoint  = "sairam.peruri.work@gmail.com"  # Replace with your email address
}