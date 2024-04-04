locals {
  awslogs_group = local.service_full_name

  api_environment_data = {
    PORT                     = local.container_port
    DEPLOYMENT_ENVIRONMENT   = var.DEPLOYMENT_ENVIRONMENT
    GA_PROPERTY_ID           = terraform.workspace == "prod" ? "UA-1233815-17" : "UA-1233815-19"
    TOKEN_SERVICE_GRANT_TYPE = local.tass_grant_type
    TOKEN_SERVICE_SCOPE      = local.tass_scope
  }

  api_secrets_data = {
    NEW_RELIC_LICENSE_KEY       = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/global/infra/newrelic/default"
    DD_API_KEY                  = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/global/infra/datadog/default/org"
    TOKEN_SERVICE_HOST          = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/TOKEN_SERVICE_HOST"
    TOKEN_SERVICE_CLIENT_ID     = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/TOKEN_SERVICE_CLIENT_ID"
    TOKEN_SERVICE_CLIENT_SECRET = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/TOKEN_SERVICE_CLIENT_SECRET"
    SCOUT_SERVICE_HOST          = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/SCOUT_SERVICE_HOST"
    LOG_LEVEL                   = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/${local.function}/LOG_LEVEL"
    LOG_FILE                    = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/${local.function}/LOG_FILE"
    LOG_APPENDER                = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/${local.function}/LOG_APPENDER"
    OPENSEARCH_MASTER_USERNAME  = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${local.account_type}/opensearch/OPENSEARCH_MASTER_USERNAME"
    OPENSEARCH_MASTER_PASSWORD  = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${local.account_type}/opensearch/OPENSEARCH_MASTER_PASSWORD"
    OPENSEARCH_DOMAIN_URL       = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${local.account_type}/opensearch/OPENSEARCH_DOMAIN_URL"
    BENTO_PUBLIC_KEY            = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/BENTO_PUBLIC_KEY"
  }

  env_data_map = {
    api : [for k, v in local.api_environment_data : { name = tostring(k), value = tostring(v) }]
  }
  secrets_map = {
    api : [for k, v in local.api_secrets_data : { name = tostring(k), valueFrom = tostring(v) }]
  }

  ##################### DataDog Implementation #####################
    templateFolder = "${path.cwd}/services/contentsearch_api/templates"

  fluent_bit_config = templatefile("${local.templateFolder}/fluentbit-configuration.conf", {
    account      = var.common_tags.Account
    environment  = var.common_tags.Environment
    platform     = var.common_tags.Platform
    application  = var.common_tags.Application
    runteam      = var.common_tags.RunTeam
    service_name = local.service_full_name
    function     = "logging"
    pii          = "none"
    logtype      = "application"
  })

  fluentbit_datadog_container_definition = {
    command = [
      "bash",
      "-c", templatefile("${local.templateFolder}/fluentbit-entrypoint.sh", {
        fluent_bit_config  = "'${replace(local.fluent_bit_config, "'", "'\\''")}'"
      })
    ]
    cpu       = 60
    essential = true
    firelensConfiguration = {
      type = "fluentbit"
      options = {
        enable-ecs-log-metadata = "true"
      }
    }
    image             = local.datadog_container_image
    memoryReservation = 60
    name              = "${local.service_full_name}-log-router"
    secrets = [
      # TODO: Remove nr secret when datadog migration is complete
      {
        name      = "NEWRELIC_LICENSE_KEY"
        valueFrom = "/global/infra/newrelic/${local.account_type}"
      },
      {
        name      = "DD_API_KEY"
        valueFrom = "/global/infra/datadog/default/org"
      }
    ]
  }

  service_container_definition_depends_on = [
    {
      containerName = "${local.service_full_name}-log-router",
      condition     = "START"
    }
  ]

  service_container_definition_log_configuration = {
    logDriver = "awsfirelens"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition
resource "aws_ecs_task_definition" "task_definition" {
  family = local.service_full_name
  tags   = var.common_tags
  # network_mode =  "bridge"
  # requires_compatibilities =  []

  # Role that the Amazon ECS container agent and the Docker daemon can assume. For example to pull images and fetch secrets from PS/SSM.
  # Not to be confused with `task_role` (Task Role, Container role) - the role which running container could assume.
  # https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html#execution_role_arn
  # See https://dillonbeliveau.com/2018/12/08/aws-ecs-iam-roles-demystified.html
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  # Role of the container during run time.
  # Not to be confused with Task Execution Role that the Amazon ECS container agent and the Docker daemon can assume.
  # https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html#task_role_arn
  # See https://dillonbeliveau.com/2018/12/08/aws-ecs-iam-roles-demystified.html
  # Support for IAM roles for tasks was added to the AWS SDKs on July 13th, 2016 (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
  # task_role_arn = aws_iam_role.ecs_task.arn


  # readonlyRootFilesystem needs to be false for "skyzyx/nginx-hello-world" to avoid this error:
  #   mkdir() "/var/cache/nginx/client_temp" failed (30: Read-only file system)
  container_definitions = jsonencode([
    local.fluentbit_datadog_container_definition,
    {
      "name" : local.service_full_name,
      "image" : local.container_image,
      "essential" : true,
      "cpu" : 512,
      "memoryReservation" : 2048,
      "secrets" : local.secrets_map[local.function],
      "environment" : local.env_data_map[local.function]
      "portMappings" : [
        {
          "containerPort" : local.container_port,
          "hostPort" : 0,
          "protocol" : "tcp"
      }],
      "volumesFrom" : [],
      "logConfiguration" : local.service_container_definition_log_configuration,
      "dependsOn" : local.service_container_definition_depends_on,
      "readonlyRootFilesystem" : false
    },
  ])

  /* lifecycle {
    ignore_changes = [
      # Why is it here? For dark deploys?
      container_definitions,
    ]
  } */
}
