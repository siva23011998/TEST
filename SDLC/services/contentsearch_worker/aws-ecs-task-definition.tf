locals {
  awslogs_group = local.service_full_name

  worker_environment_data = {
    PORT                    = local.container_port
    DEPLOYMENT_ENVIRONMENT  = var.DEPLOYMENT_ENVIRONMENT
    OPENSEARCH_INDEX_PREFIX = terraform.workspace == "prod" ? "" : "${var.DEPLOYMENT_ENVIRONMENT}-"
    GA_PROPERTY_ID          = terraform.workspace == "prod" ? "UA-1233815-17" : "UA-1233815-19"
    SQS_QUEUE_URL           = var.sqs_queue_url
    SQS_QUEUE_NAME          = var.sqs_queue_name
  }
  /* worker_efs_data = {
    name = "efs-worker"
    efsVolumeConfiguration = {
      "fileSystemId" : data.terraform_remote_state.shared.outputs.aws_efs_id_worker.id,
      "transitEncryption" : "ENABLED"
    }
  } */

  worker_secrets_data = {
    NEW_RELIC_LICENSE_KEY      = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/global/infra/newrelic/default"
    DD_API_KEY                  = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/global/infra/datadog/default/org"
    LOG_LEVEL                  = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/${local.function}/LOG_LEVEL"
    LOG_FILE                   = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/${local.function}/LOG_FILE"
    LOG_APPENDER               = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${terraform.workspace}/${local.function}/LOG_APPENDER"
    OPENSEARCH_MASTER_USERNAME = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${local.account_type}/opensearch/OPENSEARCH_MASTER_USERNAME"
    OPENSEARCH_MASTER_PASSWORD = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${local.account_type}/opensearch/OPENSEARCH_MASTER_PASSWORD"
    OPENSEARCH_DOMAIN_URL      = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/${local.application}/${local.account_type}/opensearch/OPENSEARCH_DOMAIN_URL"
    AWS_ACCESS_KEY_ID          = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/global/infrastructure/CONTENT_SEARCH_SVC_USER_ACCESS_KEY_ID"
    AWS_SECRET_ACCESS_KEY      = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/global/infrastructure/CONTENT_SEARCH_SVC_USER_SECRET_KEY"

    // The following variables will be discontinued after deployments have gone out due to confusion between METADATA_API_HOST vs DB_METADATA_API_HOST.
    // We are not using METADATA_API_HOST or BENTO_API_HOST APIs, but the DB directly. 
    METADATA_API_HOST   = terraform.workspace != "prod" ? "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/metadata-api/${terraform.workspace}/DB_METADATA_API_HOST" : data.aws_ssm_parameter.DB_METADATA_API_READER_HOST[0].arn
    METADATA_API_USER   = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/metadata-api/${terraform.workspace}/DB_METADATA_API_USER"
    METADATA_API_PASS   = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/metadata-api/${terraform.workspace}/DB_METADATA_API_PASS"
    METADATA_API_SCHEMA = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/metadata-api/${terraform.workspace}/DB_METADATA_API_SCHEMA"
    BENTO_API_HOST      = terraform.workspace != "prod" ? "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/bento-api/${terraform.workspace}/DB_HOST" : data.aws_ssm_parameter.DB_BENTO_API_READER_HOST[0].arn
    BENTO_API_USER      = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/bento-api/${terraform.workspace}/DB_USER"
    BENTO_API_PASS      = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/bento-api/${terraform.workspace}/DB_PASS"
    BENTO_API_SCHEMA    = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/bento-api/${terraform.workspace}/DB_SCHEMA"

    // This is the default and it is the writer instance
    DB_METADATA_API_HOST = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/metadata-api/${terraform.workspace}/DB_METADATA_API_HOST"

    # LIMITED ACCESS USER IMPLEMENTATION FOR METADATA API READER/WRITER FOR NOW. IN THE FUTURE, THE SAME WILL APPLY TO BENTO API DB.
    # /metadata-api/nonprod/application/DB_CONTENT_SEARCH_WRITE_ACCESS_USER
    # /metadata-api/nonprod/application/DB_CONTENT_SEARCH_WRITE_ACCESS_PASS
    # /metadata-api/prod/application/DB_CONTENT_SEARCH_WRITE_ACCESS_USER
    # /metadata-api/prod/application/DB_CONTENT_SEARCH_WRITE_ACCESS_PASS
    DB_METADATA_API_USER   = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/metadata-api/${local.account_type}/application/DB_CONTENT_SEARCH_WRITE_ACCESS_USER"
    DB_METADATA_API_PASS   = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/metadata-api/${local.account_type}/application/DB_CONTENT_SEARCH_WRITE_ACCESS_PASS"
    DB_METADATA_API_SCHEMA = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/metadata-api/${terraform.workspace}/DB_METADATA_API_SCHEMA"

    // This is same as writer in lowers (nonprod), but different in prod. Worker needs access to both for metadata. The events will be cleared via writer
    // and they will be read via the reader instance.
    DB_METADATA_API_HOST_READER = terraform.workspace != "prod" ? "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/metadata-api/${terraform.workspace}/DB_METADATA_API_HOST" : data.aws_ssm_parameter.DB_METADATA_API_READER_HOST[0].arn


    // We do not need the writer instance for Bento so we can be ok with the ternary clause below given that a single instance will always be used
    DB_BENTO_API_HOST   = terraform.workspace != "prod" ? "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/bento-api/${terraform.workspace}/DB_HOST" : data.aws_ssm_parameter.DB_BENTO_API_READER_HOST[0].arn
    DB_BENTO_API_USER   = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/bento-api/${terraform.workspace}/DB_USER"
    DB_BENTO_API_PASS   = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/bento-api/${terraform.workspace}/DB_PASS"
    DB_BENTO_API_SCHEMA = "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/bento-api/${terraform.workspace}/DB_SCHEMA"

    // This is same as writer in lowers (nonprod), but different in prod. Worker needs access to both for metadata. The events will be cleared via writer
    // and they will be read via the reader instance.
    DB_BENTO_API_HOST_READER = terraform.workspace != "prod" ? "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/bento-api/${terraform.workspace}/DB_HOST" : data.aws_ssm_parameter.DB_BENTO_API_READER_HOST[0].arn
  }

  templateFolder = "${path.cwd}/services/contentsearch_worker/templates"

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
        fluent_bit_config = "'${replace(local.fluent_bit_config, "'", "'\\''")}'"
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

  datadog-container-definition = jsonencode([
    {
      name      = "${local.fluentbit_datadog_container_definition.name}"
      image     = "${local.fluentbit_datadog_container_definition.image}"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 81
        }
      ]
      logConfiguration = local.service_container_definition_log_configuration
      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:80/ || exit 1"]
        interval    = 40
        timeout     = 10
        retries     = 3
        startPeriod = 15
      }
      dependsOn = local.service_container_definition_depends_on
    },
    local.fluentbit_datadog_container_definition
  ])

  env_data_map = {
    worker : [for k, v in local.worker_environment_data : { name = tostring(k), value = tostring(v) }]
  }
  secrets_map = {
    worker : [for k, v in local.worker_secrets_data : { name = tostring(k), valueFrom = tostring(v) }]
  }
}

data "aws_efs_file_system" "worker_efs_file_system" {
  file_system_id = var.file_system_id
}

data "aws_efs_access_point" "worker_lastruns_access_point" {
  access_point_id = var.worker_accesspoint_id
}

## SSM Param Sotre for Metadata and Bento API Reader instances for prod
data "aws_ssm_parameter" "DB_METADATA_API_READER_HOST" {
  count = terraform.workspace == "prod" ? 1 : 0
  name  = "/contentsearch/prod/DB_METADATA_API_READER_HOST"
}

data "aws_ssm_parameter" "DB_BENTO_API_READER_HOST" {
  count = terraform.workspace == "prod" ? 1 : 0
  name  = "/contentsearch/prod/DB_BENTO_API_READER_HOST"
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
      "readonlyRootFilesystem" : false,
      "mountPoints" : [
        {
          "containerPath" : "/usr/share/logstash/lastruns"
          "sourceVolume" : "worker_lastruns_accesspoint"
        }
      ]
    },
  ])

  volume {
    name = "worker_lastruns_accesspoint"
    efs_volume_configuration {
      file_system_id = data.aws_efs_file_system.worker_efs_file_system.id
      root_directory = "/"

      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = data.aws_efs_access_point.worker_lastruns_access_point.id
      }
    }
  }

  volume {
    name      = "local-worker-efs-mount"
    host_path = "/local/worker"
  }

  # lifecycle {
  #   ignore_changes = [
  #     # Why is it here? For dark deploys?
  #     # container_definitions,
  #   ]
  # }

}
