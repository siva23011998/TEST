# Introspect a Turbot account and retrieve network information.
# https://github.mheducation.com/terraform/turbot-network
module "turbot-network" {
  source = "git@github.mheducation.com:terraform/turbot-network.git?ref=4.0.0"
  # source      = "./turbot-network"
  tags                = module.aws_resource_tags.common_tags


  # vpc_filter_name = "Name"
  # vpc_filter_value = "MHE Non-Production VPC"
}
