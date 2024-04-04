locals {
  account_type     = terraform.workspace == "prod" ? "prod" : "nonprod"
  environment      = terraform.workspace
  mhe_account_id   = substr(data.aws_vpc.non-default.tags["Name"], 0, 3)
  iam_path_prefix  = join("/", ["", module.aws_resource_tags.account, local.filtered_common_tags.Application, ""])
  contentsearch_sdlc_fqdn_api         = "${local.environment}-api.${data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.name_trimmed}"
  contentsearch_sdlc_fqdn_worker      = "${local.environment}-worker.${data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.name_trimmed}"
  contentsearch_dark_sdlc_fqdn_api    = "dark-${local.environment}-api.${data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.name_trimmed}"
  contentsearch_dark_sdlc_fqdn_worker = "dark-${local.environment}-worker.${data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.name_trimmed}"
  contentsearch_sdlc_fqdn_sqs        = "${local.environment}-sqs.${data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.name_trimmed}"
 }