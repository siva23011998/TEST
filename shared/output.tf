#
# Modules
#

output "aws-alb-http" {
  description = "Output of the `aws_alb_http` module."
  value       = module.aws_alb_http
  sensitive   = true
}
output "aws-alb-http-worker" {
  description = "Output of the `aws_alb_http` module for worker service."
  value       = module.aws_alb_http_worker
  sensitive   = true
}


output "aws-ecs-asg-cluster" {
  description = "Output of the `aws_ecs_asg_cluster` module."
  value       = module.aws_ecs_asg_cluster
  sensitive   = false
}

output "aws_alb_http_target_group" {
  description = "ARN of the target group."
  value       = module.aws_alb_http.target_group.arn
  sensitive   = false
}

output "aws_alb_http_target_group_worker" {
  description = "ARN of the target group."
  value       = module.aws_alb_http_worker.target_group.arn
  sensitive   = false
}

output "turbot-network" {
  description = "Output of the `turbot-network` module."
  value       = module.turbot-network
  sensitive   = false
}

output "aws-dns-public-zone" {
  description = "Public zone object for the main Route 53 zone."
  # mimicking output of aws-dns-public-zone module interface
  sensitive = false
  value = {
    hosted_zone = merge({ "name_trimmed" = trimsuffix(aws_route53_zone.main.name, ".") }, aws_route53_zone.main)
  }
}
/* output "aws-dns-public-zone_worker" {
  description = "Public zone object for the main Route 53 zone."
  # mimicking output of aws-dns-public-zone module interface
  sensitive = false
  value = {
    hosted_zone = merge({ "name_trimmed" = trimsuffix(aws_route53_zone.worker.name, ".") }, aws_route53_zone.worker)
  }
} */


output "aws_ecr_repository_api" {
  description = "Information about ECR repo for images"
  value       = aws_ecr_repository.api.repository_url
}

output "aws_ecr_repository_worker" {
  description = "Information about ECR repo for images"
  value       = aws_ecr_repository.worker.repository_url
}

# This allows sharing of the efs file system used by worker across the different SDLCs
output "aws_efs_id_worker" {
  description = "EFS File System to be used by worker"
  value       = aws_efs_file_system.worker
}

# This allows sharing of the efs access point which defines the subfolder which gives ownership to the logstash user
output "aws_efs_lastruns_access_point" {
  description = "Access point to be used by worker to store just lastruns"
  value       = aws_efs_access_point.worker_lastruns_access_point
}

# output "aws-dns-public-zone-amt" {
#   description = "Public zone object for the AMT Route 53 zone."
#   # mimicking output of aws-dns-public-zone module interface
#   sensitive = false
#   value = {
#     hosted_zone = merge({ "name_trimmed" = trimsuffix(aws_route53_zone.amt.name, ".") }, aws_route53_zone.amt)
#   }
# }

# output "aws_elasticache_cluster_nodes" {
#   description = "List the memcached nodes"
#   value       = aws_elasticache_cluster.cinch-memcached.cache_nodes.*.address
# }

#
# Data and Resources
#
output "subnet_1" {
  value = module.turbot-network.internal_subnet_1_id
}
output "subnet_2" {
  value = module.turbot-network.internal_subnet_2_id
}
output "subnet_3" {
  value = module.turbot-network.internal_subnet_3_id
}


###
### OpenSearch Configs
###
output "index_snapshot_bucket_name" {
  value = aws_s3_bucket.index_snapshot_bucket.id
}
