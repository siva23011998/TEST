# Default SSL certificate for using in ALB's default HTTPS listener
# https://github.mheducation.com/terraform-incubator/aws-acm
module "aws_acm_default" {
  source = "git@github.mheducation.com:terraform/aws-acm.git?ref=3.3.0"


  # Max 64 characters for the first domain
  domain_name = local.alb_default_cert_name
  zone_id     = local.aws_route53_zone_id

  validation_force_overwrite = true
  wait_for_validation        = false

  tags = local.filtered_common_tags
}

locals {
  prod_dns_names = terraform.workspace == "nonprod" ? {} : {
    ### These were validated over email because DNS is misconfigured and breaks validation.
    # Mostly due to star records in the zones (both R53 and UltraDNS), but also about primary NS server in SOA record.
    "contentsearch.mheducation.com" = [
      "prod-api.contentsearch.mheducation.com",
      "prod-dark-api.contentsearch.mheducation.com",
      "prod-worker.contentsearch.mheducation.com",
      "prod-dark-worker.contentsearch.mheducation.com"
    ],
  }
}

# Additional SSL certificates for using in ALB's default HTTPS listener
# https://github.mheducation.com/terraform-incubator/aws-acm
module "production_certificates" {
  # Pinning to the current latest commit in master, since we haven't released a new version yet.
  source = "git@github.mheducation.com:terraform/aws-acm.git?ref=3.3.0"


  for_each = local.prod_dns_names
  # Max 64 characters for the first domain
  domain_name               = each.key
  zone_id                   = local.aws_route53_zone_id
  subject_alternative_names = each.value

  validation_force_overwrite = true
  wait_for_validation        = false

  tags = local.filtered_common_tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate
resource "aws_lb_listener_certificate" "certificate_attach" {
  for_each        = local.prod_dns_names
  listener_arn    = module.aws_alb_http.listener.arn
  certificate_arn = module.production_certificates[each.key].certificate.arn
}





