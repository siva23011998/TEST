# https://github.mheducation.com/terraform-incubator/aws-iam-role-with-oidc/releases
module "infra_role" {
  source                 = "git@github.mheducation.com:terraform-incubator/aws-iam-role-with-oidc.git?ref=60eb8cee6d6560979d896755b96838503390385f" # PR #11
  
  role_path              = local.iam_path_prefix
  role_name_suffix       = "infra"
  provider_urls          = ["https://github.mheducation.com/_services/token"]
  iam_policies_to_attach = local.infra_custom_managed_policies
  github_repositoies     = ["content-authoring/content-search-infrastructure"]
  # Tags
  tags = module.aws_resource_tags.common_tags
}