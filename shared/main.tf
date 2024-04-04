locals {
  account_type    = local.environment == "prod" ? "prod" : "nonprod"
  aws_account_id  = data.aws_caller_identity.current.account_id
  environment     = terraform.workspace
  iam_path_prefix = join("/", ["", module.aws_resource_tags.account, local.filtered_common_tags.Application, ""])
  name_prefix     = join("-", compact([module.aws_resource_tags.account, local.filtered_common_tags.Application, lookup(local.filtered_common_tags, "Function", ""), local.filtered_common_tags.Environment]))
  #all_managed_policies_arns = join(", ", data.terraform_remote_state.init.outputs.all_managed_policies_arns)
  #manually_managed_policy = data.terraform_remote_state.init.outputs.manually_managed_policy
}
