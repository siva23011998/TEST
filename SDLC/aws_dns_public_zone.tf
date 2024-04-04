# https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "api_dark" {
  zone_id = data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.zone_id
  type    = "A"
  name    = local.contentsearch_dark_sdlc_fqdn_api

  alias {
    name                   = data.terraform_remote_state.shared.outputs.aws-alb-http.load_balancer.dns_name
    zone_id                = data.terraform_remote_state.shared.outputs.aws-alb-http.load_balancer.zone_id
    evaluate_target_health = false
  }
}

# https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "worker_dark" {
  #zone_id = data.terraform_remote_state.shared.outputs.aws-dns-public-zone_worker.hosted_zone.zone_id
  zone_id = data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.zone_id
  type    = "A"
  name    = local.contentsearch_dark_sdlc_fqdn_worker

  alias {
    name                   = data.terraform_remote_state.shared.outputs.aws-alb-http-worker.load_balancer.dns_name
    zone_id                = data.terraform_remote_state.shared.outputs.aws-alb-http-worker.load_balancer.zone_id
    evaluate_target_health = false
  }
}

### For testing new names ahead of prod cutover
# TODO: remove after cutover
# Creaing an alias for the current SDLC in the public zone created in shared layer
# https://www.terraform.io/docs/providers/aws/r/route53_record.html
# resource "aws_route53_record" "alb_cinch_dark2" {
#   zone_id = data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.zone_id
#   type    = "A"
#   name    = local.cinch_sdlc_fqdn_dark2test

#   alias {
#     name                   = data.terraform_remote_state.shared.outputs.aws-alb-http.load_balancer.dns_name
#     zone_id                = data.terraform_remote_state.shared.outputs.aws-alb-http.load_balancer.zone_id
#     evaluate_target_health = false
#   }
# }

# Creaing a dark alias for the media content migrated from legacy prod account for testing purpose.

# https://www.terraform.io/docs/providers/aws/r/route53_record.html
# resource "aws_route53_record" "alb_cinch_media" {
#   zone_id = data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.zone_id
#   type    = "A"
#   name    = local.cinch_sdlc_fqdn_media_dark

#   alias {
#     name                   = data.terraform_remote_state.shared.outputs.aws-alb-http.load_balancer.dns_name
#     zone_id                = data.terraform_remote_state.shared.outputs.aws-alb-http.load_balancer.zone_id
#     evaluate_target_health = false
#   }
# }


# Creaing an alias for the current SDLC in the public zone created in shared layer
# https://www.terraform.io/docs/providers/aws/r/route53_record.html
# resource "aws_route53_record" "alb_amt_dark2" {
#   zone_id = data.terraform_remote_state.shared.outputs.aws-dns-public-zone-amt.hosted_zone.zone_id
#   type    = "A"
#   name    = local.amt_sdlc_fqdn_dark2test

#   alias {
#     name                   = data.terraform_remote_state.shared.outputs.aws-alb-http.load_balancer.dns_name
#     zone_id                = data.terraform_remote_state.shared.outputs.aws-alb-http.load_balancer.zone_id
#     evaluate_target_health = false
#   }
# }
