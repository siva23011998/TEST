/****************************************************************
# PURPOSE: 
Process requests that are intended to represent asset groups or documents that
need to be indexed.

# CURRENT USE CASE
For simplicity, for now, this will receive messages that are deleted from the
existing `aam-metadata-api-search-indexing` queue. This is to be able to compare documents 
ingested to both databases and eventually do comparisons among both.

# GOAL
Eventually this will replace `aam-metadata-api-search-indexing`.

# OVERVIEW
We are creating two resources here: A SQS service and a SSM Parameter. All existing SQS resources have a corresponding SSM parameter.

# REQUIREMENTS
The local variable service._full_name has to be set properly to name the service below. It is constructed by using the following variables from the variables.tf file:
  join("-", [var.common_tags.Account, var.common_tags.Application, var.common_tags.Environment, var.service_name]
*****************************************************************/

resource "aws_sqs_queue" "content-search-indexing" {
  name = local.indexing_sqs_service_name
  // default value is 30 seconds, if workers may take longer to process, use ChangeMessageVisibility: 
  // https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_ChangeMessageVisibility.html
  visibility_timeout_seconds = 30
  tags = var.common_tags
}