# resource "aws_elasticache_cluster" "cinch-memcached" {
#   cluster_id           = "${var.platform}-${var.application}-${local.environment}"
#   engine               = "memcached"
#   node_type            = var.elasticache_node_params["node_type"][local.environment]
#   num_cache_nodes      = var.elasticache_node_params["num_cache_nodes"][local.environment]
#   engine_version       = var.elasticache_node_params["engine_version"][local.environment]
#   parameter_group_name = var.elasticache_node_params["parameter_group_name"][local.environment]
#   port                 = 11211
#   security_group_ids   = [module.turbot-network.default_security_group_id]
#   subnet_group_name    = aws_elasticache_subnet_group.cinch.name

#   # Todo: refactor hardcoded values to configurable variables
#   tags = merge(local.filtered_common_tags, {
#     # AWS MAP documentation:
#     # https://confluence.mheducation.com/display/EPS/AWS+Migration+Acceleration+Program+MAP
#     aws-migration-project-id = "MPE03843",
#     map-migrated             = "d-server-01obeoaq2fo40j",
#   })

# }

# resource "aws_elasticache_subnet_group" "cinch" {
#   name       = "${var.platform}-${var.application}-${local.environment}-subnet-group"
#   subnet_ids = module.turbot-network.internal_subnet_ids
#   tags       = local.filtered_common_tags
# }
