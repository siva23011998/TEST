# TODO: CHECK POTENTIAL DUPLICATE WITH MAIN.TF LOCAL
locals {
  mhe_account_id = substr(data.aws_vpc.non-default.tags["Name"], 0, 3)
  resource_prefix   = join("-", [module.aws_resource_tags.account, module.aws_resource_tags.application, module.aws_resource_tags.environment])
}

data "aws_caller_identity" "current" {}

# Default VPC is Amazon's. Non-default is usually provisioned for us
data "aws_vpc" "non-default" {
  # searching for the only provisioned VPC
  filter {
    name   = "tag-key"
    values = ["aws:cloudformation:logical-id"]
  }

  filter {
    name   = "tag-value"
    values = ["Vpc"]
  }
  # default = false # doesn't work for some reason. finds multiple VPCs
  # Another working option, just for reference in case something will be changed in VPC setup
  # filter {
  #   name   = "isDefault"
  #   values = ["false"]
  # }
}

data "aws_ssm_parameter" "opensearch_masteruser" {
  name = "/${local.filtered_common_tags.Application}/${local.account_type}/opensearch/OPENSEARCH_MASTER_USERNAME"
}

data "aws_ssm_parameter" "opensearch_masteruser_passwd" {
  name = "/${local.filtered_common_tags.Application}/${local.account_type}/opensearch/OPENSEARCH_MASTER_PASSWORD"
}

data "aws_ssm_parameter" "ecs_ami_version" {
  name = "/global/infrastructure/ecs-ami-version"
}


data "terraform_remote_state" "init" {
  backend = "s3"

  config = {
    region = var.aws_region
    # TODO: check if variables are allowed
    bucket = join("-", [local.mhe_account_id, "remote-state", var.application , local.account_type])
    key    = "env:/${local.account_type}/${var.application}-./init.state.json"
  }
}
