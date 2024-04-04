module "ecs_service" {
  source = "git@github.mheducation.com:terraform/aws-ecs-service.git?ref=eb7eb40445de6acdaafb0e8986938f7875964ece"

  # Naming
  container_name = local.service_full_name
  
  # Tags
  tags = var.common_tags

  # Capacity Provider
  capacity_provider_name = var.capacity_provider_name

    # ECS Cluster
  app_container_port          = local.container_port
  ecs_cluster_arn             = var.ecs_cluster_arn
  aws_ecs_task_definition_arn = aws_ecs_task_definition.task_definition.arn
  task_min_size               = local.task_min_count
  task_max_size               = local.task_max_count

  # Scaling Targets
  cpu_target_threshold             = local.task_cpu_target_percent
  cpu_scaleout_cooldown_seconds    = 120
  cpu_scalein_cooldown_seconds     = 300
  memory_target_threshold          = local.task_memory_target_percent
  memory_scaleout_cooldown_seconds = 120
  memory_scalein_cooldown_seconds  = 300

  # Deployment
  deploy_min_healthy_percent = var.deploy_min_healthy_percent
  deploy_max_healthy_percent = 200

# Dark Deployment
  enable_dark_deployment    = true
  enable_dark_listener_rule = true
  dark_alb_listener_arn     = var.alb_listener_arn
  dark_listener_rule_conditions = [
    {
        type   = "host_header"
        values = var.host_header
    }
  ]
  dark_vpc_id               = var.vpc_id

  # Health/ALB
  alb_target_group_arn = var.alb_target_group_arn
  dark_healthcheck_path = var.healthcheck_path
  healthcheck_grace_period_seconds = 300
}


# https://www.terraform.io/docs/providers/aws/r/cloudwatch_log_group.html
resource "aws_cloudwatch_log_group" "default" {
  name = local.service_full_name
  tags = var.common_tags

  # Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653.
  retention_in_days = 30
}