# SSL certificate for using in ALB for specific environment
# https://github.mheducation.com/terraform-incubator/aws-acm
module "aws_acm_env" {
  # Pinning to the current latest commit in master, since we haven't released a new version yet.
  source = "git@github.mheducation.com:terraform/aws-acm.git?ref=3.3.0"

  domain_name = local.contentsearch_sdlc_fqdn_api
  zone_id     = data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.zone_id

  subject_alternative_names = [local.contentsearch_dark_sdlc_fqdn_api,
    local.contentsearch_sdlc_fqdn_worker,
    local.contentsearch_dark_sdlc_fqdn_worker,
  ]

  validation_force_overwrite = true
  wait_for_validation        = true

  tags = local.filtered_common_tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate
resource "aws_lb_listener_certificate" "aws_acm_env" {
  listener_arn    = data.terraform_remote_state.shared.outputs.aws-alb-http.listener.arn
  certificate_arn = module.aws_acm_env.certificate.arn
  # depends_on here due to current implementation of AWS_ACM module which doesn't wait properly
  depends_on = [module.aws_acm_env.certificate_validation]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate
resource "aws_lb_listener_certificate" "aws_acm_env_worker" {
  listener_arn    = data.terraform_remote_state.shared.outputs.aws-alb-http-worker.listener.arn
  certificate_arn = module.aws_acm_env.certificate.arn
  # depends_on here due to current implementation of AWS_ACM module which doesn't wait properly
  depends_on = [module.aws_acm_env.certificate_validation]
}
