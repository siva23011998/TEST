locals {
  account_type         = local.environment == "prod" ? "prod" : "nonprod"
  aws_account_id       = data.aws_caller_identity.current.account_id
  environment          = terraform.workspace
  iam_name_prefix      = join("-", [module.aws_resource_tags.account, local.filtered_common_tags.Application])
  iam_path_prefix      = join("/", ["", module.aws_resource_tags.account, local.filtered_common_tags.Application, ""])
  mhe_account_id    = substr(data.aws_vpc.non-default.tags["Name"], 0, 3)
  resource_name_prefix = join("-", compact([module.aws_resource_tags.account, local.filtered_common_tags.Application, lookup(local.filtered_common_tags, "Function", ""), local.filtered_common_tags.Environment]))
  open_search_iam_path_prefix = join("/", ["", module.aws_resource_tags.account, module.aws_resource_tags.application, "open-search", ""])
  deprecated_resource_name_prefix = join("-", [module.aws_resource_tags.account, local.filtered_common_tags.Platform, local.filtered_common_tags.Application])
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
