locals {
  // This is the name used by the specific service, please create a new name if creating another service
  indexing_sqs_service_name = join("-", [var.common_tags.Account, var.common_tags.Application, "indexing", var.common_tags.Environment])
}