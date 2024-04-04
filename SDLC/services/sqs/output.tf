output "aws_sqs_content_search_indexing_url" {
  description = "Url of the content search indexing sqs"
  value = aws_sqs_queue.content-search-indexing.id
}

output "indexing_sqs_service_name" {
  description = "Name of the service applied to the indexing sqs"
  value = local.indexing_sqs_service_name
}