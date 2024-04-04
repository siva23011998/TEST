locals {
  # ALB Listener rule priority ranges from 1 to 50000. See https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-listenerrule.html
  environment_priority = {
    sandbox = 7000
    dev     = 6000
    qastg   = 5000
    qalv    = 4000
    pqa     = 3000
    demo    = 2000
    prod    = 1000
  }
}

# Light API
module "service_contentsearch_api" {
  source = "./services/contentsearch_api"

  service_name = "api"

  # For dark tests
  # host_header  = [var.zone_name[terraform.workspace], "dark.${var.zone_name[terraform.workspace]}"]
  host_header = sort([
    local.contentsearch_sdlc_fqdn_api, # long name such as sdlc.app.prod/nonprod.mheducation.com
    # local.contentsearch_sdlc_fqdn_dark2test, # another name for dark test before prod cutover
    # "*.someprodname.com",
    # "someprodname.com",
    ],
  )

  # priority    = 100 + local.environment_priority[local.environment]

  # Common settings
  alb_listener_arn           = data.terraform_remote_state.shared.outputs.aws-alb-http.listener.arn
  aws_region                 = var.aws_region
  aws_account_id             = data.aws_caller_identity.current.account_id
  capacity_provider_name     = data.terraform_remote_state.shared.outputs.aws-ecs-asg-cluster.cluster_capacity_provider.name
  common_tags                = local.filtered_common_tags_api
  ecs_cluster_arn            = data.terraform_remote_state.shared.outputs.aws-ecs-asg-cluster.ecs_cluster.arn
  vpc_id                     = data.terraform_remote_state.shared.outputs.turbot-network.vpc_id
  internal_subnet_ids        = data.terraform_remote_state.shared.outputs.turbot-network.internal_subnet_ids
  default_security_group_id  = data.terraform_remote_state.shared.outputs.turbot-network.default_security_group_id
  alb_target_group_arn       = data.terraform_remote_state.shared.outputs.aws_alb_http_target_group
  image_repository           = data.terraform_remote_state.shared.outputs.aws_ecr_repository_api
  dark_enabled               = false
  deploy_min_healthy_percent = 75
  DEPLOYMENT_ENVIRONMENT     = module.service_contentsearch_api.dark_enabled == false ? terraform.workspace : "dark-${module.aws_resource_tags_api.environment}"
  healthcheck_path           = "/v1"
}

# Dark API
module "service_contentsearch_api_dark" {
  source = "./services/contentsearch_api"

  service_name = "api"

  # For dark tests
  # host_header  = [var.zone_name[terraform.workspace], "dark.${var.zone_name[terraform.workspace]}"]
  host_header = sort([
    local.contentsearch_dark_sdlc_fqdn_api, # long name such as sdlc.app.prod/nonprod.mheducation.com
    # local.contentsearch_sdlc_fqdn_dark2test, # another name for dark test before prod cutover
    # "*.cinchlearning.com",
    # "cinchlearning.com",
    # local.cinch_sdlc_fqdn_media_dark # Remove this header in prod or non-prod if you run into an issue with alb listener max headers limit or no longer needed.
    ],
  )

  # priority    = 100 + local.environment_priority[local.environment]

  # Common settings
  alb_listener_arn           = data.terraform_remote_state.shared.outputs.aws-alb-http.listener.arn
  aws_region                 = var.aws_region
  aws_account_id             = data.aws_caller_identity.current.account_id
  capacity_provider_name     = data.terraform_remote_state.shared.outputs.aws-ecs-asg-cluster.cluster_capacity_provider.name
  common_tags                = local.filtered_common_dark_tags_api
  ecs_cluster_arn            = data.terraform_remote_state.shared.outputs.aws-ecs-asg-cluster.ecs_cluster.arn
  vpc_id                     = data.terraform_remote_state.shared.outputs.turbot-network.vpc_id
  internal_subnet_ids        = data.terraform_remote_state.shared.outputs.turbot-network.internal_subnet_ids
  default_security_group_id  = data.terraform_remote_state.shared.outputs.turbot-network.default_security_group_id
  alb_target_group_arn       = data.terraform_remote_state.shared.outputs.aws_alb_http_target_group
  image_repository           = data.terraform_remote_state.shared.outputs.aws_ecr_repository_api
  dark_enabled               = true
  deploy_min_healthy_percent = 0
  DEPLOYMENT_ENVIRONMENT     = module.service_contentsearch_api_dark.dark_enabled == true ? "dark-${module.aws_resource_dark_tags_api.environment}" : terraform.workspace
  healthcheck_path           = "/v1"
}

# Light WORKER
module "service_contentsearch_worker" {
  source = "./services/contentsearch_worker"

  service_name = "worker"

  # For dark tests
  # host_header  = [var.zone_name[terraform.workspace], "dark.${var.zone_name[terraform.workspace]}"]
  host_header = sort([
    local.contentsearch_sdlc_fqdn_worker, # long name such as sdlc.app.prod/nonprod.mheducation.com
    # local.contentsearch_sdlc_fqdn_dark2test, # another name for dark test before prod cutover
    # "*.someprodname.com",
    # "someprodname.com",
    ],
  )

  # priority    = 100 + local.environment_priority[local.environment]

  # Common settings
  alb_listener_arn           = data.terraform_remote_state.shared.outputs.aws-alb-http-worker.listener.arn
  aws_region                 = var.aws_region
  aws_account_id             = data.aws_caller_identity.current.account_id
  capacity_provider_name     = data.terraform_remote_state.shared.outputs.aws-ecs-asg-cluster.cluster_capacity_provider.name
  common_tags                = local.filtered_common_tags_worker
  ecs_cluster_arn            = data.terraform_remote_state.shared.outputs.aws-ecs-asg-cluster.ecs_cluster.arn
  vpc_id                     = data.terraform_remote_state.shared.outputs.turbot-network.vpc_id
  internal_subnet_ids        = data.terraform_remote_state.shared.outputs.turbot-network.internal_subnet_ids
  default_security_group_id  = data.terraform_remote_state.shared.outputs.turbot-network.default_security_group_id
  alb_target_group_arn       = data.terraform_remote_state.shared.outputs.aws_alb_http_target_group_worker
  image_repository           = data.terraform_remote_state.shared.outputs.aws_ecr_repository_worker
  sqs_queue_url              = module.service_content-search-indexing.aws_sqs_content_search_indexing_url
  sqs_queue_name             = module.service_content-search-indexing.indexing_sqs_service_name
  dark_enabled               = false
  deploy_min_healthy_percent = 75
  file_system_id             = data.terraform_remote_state.shared.outputs.aws_efs_id_worker.id
  DEPLOYMENT_ENVIRONMENT     = terraform.workspace
  worker_accesspoint_id      = data.terraform_remote_state.shared.outputs.aws_efs_lastruns_access_point.id
}

# Dark WORKER
module "service_contentsearch_worker_dark" {

  source = "./services/contentsearch_worker"

  service_name = "worker"

  # For dark tests
  # host_header  = [var.zone_name[terraform.workspace], "dark.${var.zone_name[terraform.workspace]}"]
  host_header = sort([
    local.contentsearch_dark_sdlc_fqdn_worker, # long name such as sdlc.app.prod/nonprod.mheducation.com
    # local.contentsearch_sdlc_fqdn_dark2test, # another name for dark test before prod cutover
    # "*.cinchlearning.com",
    # "cinchlearning.com",
    # local.cinch_sdlc_fqdn_media_dark # Remove this header in prod or non-prod if you run into an issue with alb listener max headers limit or no longer needed.
    ],
  )

  # priority    = 100 + local.environment_priority[local.environment]

  # Common settings
  alb_listener_arn           = data.terraform_remote_state.shared.outputs.aws-alb-http-worker.listener.arn
  aws_region                 = var.aws_region
  aws_account_id             = data.aws_caller_identity.current.account_id
  capacity_provider_name     = data.terraform_remote_state.shared.outputs.aws-ecs-asg-cluster.cluster_capacity_provider.name
  common_tags                = local.filtered_common_dark_tags_worker
  ecs_cluster_arn            = data.terraform_remote_state.shared.outputs.aws-ecs-asg-cluster.ecs_cluster.arn
  vpc_id                     = data.terraform_remote_state.shared.outputs.turbot-network.vpc_id
  internal_subnet_ids        = data.terraform_remote_state.shared.outputs.turbot-network.internal_subnet_ids
  default_security_group_id  = data.terraform_remote_state.shared.outputs.turbot-network.default_security_group_id
  alb_target_group_arn       = data.terraform_remote_state.shared.outputs.aws_alb_http_target_group_worker
  image_repository           = data.terraform_remote_state.shared.outputs.aws_ecr_repository_worker
  sqs_queue_url              = module.service_content-search-indexing.aws_sqs_content_search_indexing_url
  sqs_queue_name             = module.service_content-search-indexing.indexing_sqs_service_name
  dark_enabled               = true
  deploy_min_healthy_percent = 0
  file_system_id             = data.terraform_remote_state.shared.outputs.aws_efs_id_worker.id
  #DEPLOYMENT_ENVIRONMENT     = contains([module.service_contentsearch_worker_dark.service_full_name], "dark") ? "dark-${module.aws_resource_dark_tags_worker.environment}-${module.aws_resource_dark_tags_worker.function}" : terraform.workspace
  DEPLOYMENT_ENVIRONMENT = "dark-${module.aws_resource_dark_tags_worker.environment}"
  worker_accesspoint_id  = data.terraform_remote_state.shared.outputs.aws_efs_lastruns_access_point.id
}

# Indexing SQS used to communicate assets that need to be indexed
module "service_content-search-indexing" {
  source      = "./services/sqs"
  common_tags = module.aws_resource_tags_sqs.common_tags
}

# Param store params
module "content_search_api_params" {
  source       = "./services/param_store"
  tags         = module.aws_resource_tags_api.common_tags
  log_level    = var.log_level
  log_file     = var.log_file
  log_appender = var.log_appender
  //Create shared ssm params
  create_shared_params = true
}
module "content_search_worker_params" {
  source       = "./services/param_store"
  tags         = module.aws_resource_tags_worker.common_tags
  log_level    = var.log_level
  log_file     = var.log_file
  log_appender = var.log_appender
}
