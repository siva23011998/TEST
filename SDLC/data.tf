data "aws_caller_identity" "current" {}

data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    region = var.aws_region
    bucket = join("-", [local.mhe_account_id, "remote-state", var.application, local.account_type])
    key    = "env:/${local.account_type}/${var.application}-./shared.state.json"
  }
}
# TODO: CHECK POTENTIAL DUPLICATE WITH MAIN.TF LOCAL
locals {
  resource_prefix = join("-", [module.aws_resource_tags.account, module.aws_resource_tags.application, module.aws_resource_tags.environment])
}
