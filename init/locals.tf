locals {
  role_prefix_name = join("-", [module.aws_resource_tags.account, local.filtered_common_tags.Application, local.account_type])
  role_infra_prefix_name = "${local.role_prefix_name}-infra"
  infra_custom_managed_policies = [
    "${local.iam_path_prefix}${aws_iam_policy.infra_custom_managed_policy_misc.name}",
    "${local.iam_path_prefix}${aws_iam_policy.infra_custom_managed_policy_iam.name}",
    "${local.iam_path_prefix}${aws_iam_policy.infra_custom_managed_policy_waf.name}",
    # these policies in prod doens't have the path turbot/
    "${local.account_type == "nonprod" ? "turbot/" : ""}ec2_operator",
    "${local.account_type == "nonprod" ? "turbot/" : ""}iam_operator",
    "${local.account_type == "nonprod" ? "turbot/" : ""}lambda_admin",
  ]
}