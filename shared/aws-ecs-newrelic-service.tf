# Sets up the NewRelic agent container as a daemon-mode ECS Task.
# https://github.mheducation.com/terraform-incubator/aws-ecs-newrelic-service
module "aws_ecs_newrelic_service" {
  source = "git@github.mheducation.com:terraform/aws-ecs-newrelic-service.git?ref=2.6.1"

  # See https://hub.docker.com/r/newrelic/infrastructure/tags?page=1&ordering=last_updated
  # agent_version = "1.17.1"

  # Cluster
  ecs_cluster_arn = module.aws_ecs_asg_cluster.ecs_cluster.arn

  # Max verbosing in nonprod to help debug issues with newrelic infrastructure agent, process reporting, low instance count query
  verbose = 3

  cpu = 20

  tags = local.filtered_common_tags
}
