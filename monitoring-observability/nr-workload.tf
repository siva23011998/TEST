terraform {
  backend "s3" {
    bucket  = "var.TF_STATE_BUCKET_NAME"
    region  = "us-east-1"
    encrypt = true
  }
}
# This code assumes you will only need one workload per MaC instantiation. Otherwise you'll need to change the naming convention
# https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/workload
resource "newrelic_workload" "mhe_workload" {
  for_each   = local.mhe_workloads
  name       = "${var.aws_account}-${var.application}-${terraform.workspace}"
  account_id = var.NR_ACCOUNT_ID

  # https://www.terraform.io/docs/language/expressions/dynamic-blocks.html
  dynamic "entity_search_query" {
    for_each = var.workload_entity_search_queries
    content {
      query = entity_search_query.value
    }
  }
  scope_account_ids = [var.NR_ACCOUNT_ID]
}

locals {
  # Fake workloads object used to create one instance of workloads
  basic_workload = {
    basic_workload = "default-workload-value"
  }
  # If var.workload_entity_search_queries is not populated then don't create a workload object
  mhe_workloads = length(var.workload_entity_search_queries) != 0 ? local.basic_workload : {}
}