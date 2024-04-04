# https://www.terraform.io/docs/providers/aws/r/route53_zone.html
# https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-public-considerations.html
### API
resource "aws_route53_zone" "main" {
  comment           = "Managed by Terraform"
  delegation_set_id = data.terraform_remote_state.init.outputs.aws_route53_delegation_set.id
  force_destroy     = false
  name              = var.zone_name[local.account_type]
  tags              = local.filtered_common_tags
}


# https://www.terraform.io/docs/providers/aws/r/route53_record.html
### API
resource "aws_route53_record" "a_record_alias" {
  #for_each = var.aliases
  for_each = local.account_type == "prod" ? var.aliases_api_prod : var.aliases

  name    = each.key
  type    = "A"
  zone_id = aws_route53_zone.main.zone_id


  alias {
    evaluate_target_health = false
    name                   = module.aws_alb_http.load_balancer.dns_name
    zone_id                = module.aws_alb_http.load_balancer.zone_id
  }
}
/* resource "aws_route53_zone" "worker" {
  comment           = "Managed by Terraform"
  delegation_set_id = data.terraform_remote_state.init.outputs.aws_route53_delegation_set.id
  force_destroy     = false
  name              = var.zone_name[local.account_type]
  tags              = local.worker_filtered_common_tags
} */



# https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "a_record_worker_alias" {
  #for_each = var.aliases_worker
  for_each = local.account_type == "prod" ? var.aliases_worker_prod : var.aliases_worker
  type     = "A"
  name     = each.key
  zone_id  = aws_route53_zone.main.zone_id

  alias {
    name                   = module.aws_alb_http_worker.load_balancer.dns_name
    zone_id                = module.aws_alb_http_worker.load_balancer.zone_id
    evaluate_target_health = false
  }
}
locals {
  aws_route53_zone_id = aws_route53_zone.main.zone_id
  # Trimming trailing dot from the zone name for convenience of other resources.
  aws_route53_zone_name = trimsuffix(aws_route53_zone.main.name, ".")

  /* 
  aws_route53_zone_id_worker = aws_route53_zone.worker.zone_id
  # Trimming trailing dot from the zone name for convenience of other resources.
  aws_route53_zone_name_worker = trimsuffix(aws_route53_zone.worker.name, ".") */
}
