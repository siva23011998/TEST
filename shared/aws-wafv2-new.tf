# Creates IPsets, regex and rule groups based on scope (REGIONAL | GLOBAL)
# Attaches the rule group to FWManaged baseline WebACL

module "wafv2_regional" {
  source = "git@github.mheducation.com:terraform-incubator/aws-wafv2.git?ref=0.1.0"

  ## Set default SQLi and XSS actions.
  default_sql_injection_rule_action = "COUNT" # COUNT, ALLOW or BLOCK
  default_xss_rule_action           = "COUNT" # COUNT, ALLOW or BLOCK

  # IPs & Domains
  /* deny_addresses_ipv4  = ["99.99.99.99/32", "88.88.88.88/32"]
  allow_addresses_ipv4 = ["10.10.10.10/32", "136.136.136.136/32"]
  allow_domain = ["allowdomain.com"]
  deny_domain  = ["denydomain.com"] */

  rate_rule_config = local.rate_rule_config
  scope            = "REGIONAL"

  tags = module.aws_resource_tags.common_tags
}
module "wafv2_global" {
  source = "git@github.mheducation.com:terraform-incubator/aws-wafv2.git?ref=0.1.0"

  ## Set default SQLi and XSS actions.
  default_sql_injection_rule_action = "COUNT" # COUNT, ALLOW or BLOCK
  default_xss_rule_action           = "COUNT" # COUNT, ALLOW or BLOCK

  # IPs & Domains
  /* deny_addresses_ipv4  = ["99.99.99.99/32", "88.88.88.88/32"]
  allow_addresses_ipv4 = ["10.10.10.10/32", "136.136.136.136/32"]
  allow_domain = ["allowdomain.com"]
  deny_domain  = ["denydomain.com"] */

  rate_rule_config = local.rate_rule_config
  scope            = "CLOUDFRONT"

  tags = module.aws_resource_tags.common_tags
}

locals {
  rate_rule_config = [
    # Example rule 1: Global rate limiting rule
    {
      action : "COUNT"
      aggregate_key_type = "IP" # FORWARDED_IP or IP. Default: IP.
      name : "${module.aws_resource_tags.account}-rate-counter"
      limit : 100 # per 5-minute interval. Too little for production
    },
    // Add more rules as needed.
  ]

}
