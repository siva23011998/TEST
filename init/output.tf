output "aws_route53_delegation_set" {
  description = "Delegation set object to pin NS servers for using in Route53 zones."
  value       = aws_route53_delegation_set.main
}

output "all_managed_policies_arns" {
  value = local.all_managed_policies_arns
}
output "manually_managed_policy" {
  value = aws_iam_policy.manually_managed_policy.arn
}

output "infra_iam_role_arn" {
  value = module.infra_role.iam_role_arn
}