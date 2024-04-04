# API PARAMS
resource "aws_ssm_parameter" "bento_public_key" {
  name      = "/${local.application}/${local.environment}/BENTO_PUBLIC_KEY"
  type      = "String"
  value     = "set manually"
  overwrite = false
  tags      = var.tags
  count     = local.function == "api" ? 1 : 0

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

# WORKER & API SEPARATE PARAMS
resource "aws_ssm_parameter" "log_level" {
  name  = "/${local.application}/${local.environment}/${local.function}/LOG_LEVEL"
  type  = "String"
  value = var.log_level
  tags  = var.tags
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
resource "aws_ssm_parameter" "log_file" {
  name  = "/${local.application}/${local.environment}/${local.function}/LOG_FILE"
  type  = "String"
  value = var.log_file
  tags  = var.tags
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
resource "aws_ssm_parameter" "log_appender" {
  name  = "/${local.application}/${local.environment}/${local.function}/LOG_APPENDER"
  type  = "String"
  value = var.log_appender
  tags  = var.tags
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
/*
SHARED PARAMS
Count is used here to only create one instance of each shared param because this module is referenced twice
from services.tf
*/
resource "aws_ssm_parameter" "scout_service_host" {
  name  = "/${local.application}/${local.environment}/SCOUT_SERVICE_HOST"
  type  = "String"
  value = "https://scout-${local.environment}.redbird.${local.account_type}.mheducation.com"
  tags  = local.function_filtered_tags
  count = local.count
}

resource "aws_ssm_parameter" "token_service_host" {
  name  = "/${local.application}/${local.environment}/TOKEN_SERVICE_HOST"
  type  = "String"
  value = local.tass_host[local.environment]
  tags  = local.function_filtered_tags
  count = local.count

}

resource "aws_ssm_parameter" "token_service_client_id" {
  name  = "/${local.application}/${local.environment}/TOKEN_SERVICE_CLIENT_ID"
  type  = "String"
  value = var.token_service_client_id
  tags  = local.function_filtered_tags
  count = local.count

}

resource "aws_ssm_parameter" "token_service_client_secret" {
  name      = "/${local.application}/${local.environment}/TOKEN_SERVICE_CLIENT_SECRET"
  type      = "SecureString"
  value     = "set this outside of tf"
  tags      = local.function_filtered_tags
  overwrite = false
  count     = local.count

  lifecycle {
    ignore_changes = [
      value
    ]

  }
}

/* ## SSM Param Sotre for Metadata and Bento API Reader instances for prod
resource "aws_ssm_parameter" "DB_METADATA_API_READER_HOST" {
  count     = terraform.workspace == "prod" && ? 1 : 0
  name      = "/contentsearch/prod/DB_METADATA_API_READER_HOST"
  type      = "SecureString"
  value     = "set this outside of tf"
  tags      = local.function_filtered_tags
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]

  }
}
resource "aws_ssm_parameter" "DB_BENTO_API_READER_HOST" {
  count     = terraform.workspace == "prod" ? 1 : 0
  name      = "/contentsearch/prod/DB_BENTO_API_READER_HOST"
  type      = "SecureString"
  value     = "set this outside of tf"
  tags      = local.function_filtered_tags
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]

  }
} */
