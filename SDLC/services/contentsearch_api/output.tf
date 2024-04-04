output "service_full_name" {
  description = "Full name of this service."
  value       = local.service_full_name
}

output "aws_cloudwatch_log_group" {
  description = "CloudWatch group object for the service."
  value       = aws_cloudwatch_log_group.default
}
output "dark_enabled" {
  description = "Dark enable variable to use in a condition."
  value       = var.dark_enabled
}
