# For reusing the same set of NS servers after recreation of Route53 zone.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_delegation_set
resource "aws_route53_delegation_set" "main" {
  reference_name = local.deprecated_resource_name_prefix
  lifecycle {
    # This flag will cause Terraform to reject with an error any plan 
    # that would destroy the infrastructure object associated with the resource, 
    # as long as the argument remains present in the configuration.
    prevent_destroy = true
  }
}
