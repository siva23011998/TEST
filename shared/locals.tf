locals {
  effective_alb_name = local.account_type == "prod" ? "contentsearch-prod-alb" : "contentsearch-nonprod-alb"
  effective_alb_endpoint = local.account_type == "prod" ? "contentsearch.mheducation.com" : "contentsearch.nonprod.mheducation.com"
  index_snapshot_bucket = "opensearch-index-backups"
}