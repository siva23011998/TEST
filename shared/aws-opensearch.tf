resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "opensearchservice.amazonaws.com"
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "${module.aws_resource_tags.account}-${var.application}-${local.environment}"
  retention_in_days = 30
}
resource "aws_cloudwatch_log_resource_policy" "opensearch_logs" {
  policy_name = "${module.aws_resource_tags.account}-${var.application}-${local.environment}-cloudwatch-logging-policy"

  policy_document = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "opensearchservice.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ],
      "Resource": "${aws_cloudwatch_log_group.main.arn}*"
    }
  ]
}
CONFIG
}


resource "aws_opensearch_domain" "opensearch" {
  domain_name    = join("-", [local.mhe_account_id, local.filtered_common_tags.Application, local.filtered_common_tags.Environment])
  engine_version = var.opensearch_version

  cluster_config {
    instance_type          = var.opensearch_instance_type[terraform.workspace]
    instance_count         = var.opensearch_number_of_instances[terraform.workspace]
    zone_awareness_enabled = length(module.turbot-network.availability_zones) > 1
    dynamic "zone_awareness_config" {
      for_each = length(module.turbot-network.availability_zones) > 1 ? [1] : []
      content {
        availability_zone_count = length(module.turbot-network.availability_zones)
      }
    }
    ## Dedicated Master Nodes
    dedicated_master_enabled = var.opensearch_masternode_enabled[terraform.workspace]
    dedicated_master_type    = var.opensearch_masternode_type[terraform.workspace]
    dedicated_master_count   = var.opensearch_masternode_count[terraform.workspace]

    ## Warm and cold storage
    warm_enabled = var.warm_enabled_map[terraform.workspace]
    warm_count   = var.warm_count_map[terraform.workspace]
    warm_type    = var.warm_type_map[terraform.workspace]

    ## Note: Master and ultrawarm nodes must be enable for cold storage.
    cold_storage_options {
      enabled = false
    }

  }
  auto_tune_options {
    desired_state       = "ENABLED"
    rollback_on_disable = "NO_ROLLBACK"
  }
  ebs_options {
    ebs_enabled = true
    volume_size = var.opensearch_ebs_volume_size[terraform.workspace]
    volume_type = var.opensearch_ebs_volume_type[terraform.workspace]
  }

  ### Network setup
  vpc_options {
    subnet_ids         = module.turbot-network.internal_subnet_ids
    security_group_ids = [aws_security_group.opensearch.id]
  }

  ## Encryption of traffic between nodes
  node_to_node_encryption {
    enabled = true
  }

  ## Encrypt data at rest
  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      #master_user_arn = aws_iam_role.masterUser_role.arn
      master_user_name     = data.aws_ssm_parameter.opensearch_masteruser.value
      master_user_password = data.aws_ssm_parameter.opensearch_masteruser_passwd.value
    }
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.main.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.main.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.main.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  tags = local.filtered_common_tags

  depends_on = [aws_iam_service_linked_role.opensearch]
}

data "aws_region" "current" {}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name = aws_opensearch_domain.opensearch.domain_name

  access_policies = <<POLICIES
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "es:*",
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${aws_opensearch_domain.opensearch.domain_name}/*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.index_snapshot_role.name}"
      ]
    }
  ]
}
POLICIES
}



output "opensearch_endpoint" {
  value = aws_opensearch_domain.opensearch.endpoint
}

output "opensearch_kibana_endpoint" {
  value = aws_opensearch_domain.opensearch.kibana_endpoint
}

resource "aws_ssm_parameter" "opensearch_domain_url" {
  name  = "/${var.application}/${local.account_type}/opensearch/OPENSEARCH_DOMAIN_URL"
  type  = "String"
  value = "https://${aws_opensearch_domain.opensearch.endpoint}"
  tags  = local.filtered_common_tags
}


# Create the new s3 bucket for snapshots backups as required by the next resource further down
resource "aws_s3_bucket" "index_snapshot_bucket" {
  bucket = "${module.aws_resource_tags.account}-${var.application}-${local.environment}-${local.index_snapshot_bucket}"
  tags   = local.filtered_common_tags
}

/* resource "aws_iam_role" "index_snapshot_role" {
  name = "${module.aws_resource_tags.account}-${var.application}-index-snapshot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "${aws_s3_bucket.index_snapshot_bucket.arn}"
      },
      {
        "Effect" : "Allow",
        "Action" : "es:ESHttpPut",
        "Resource" : "${aws_s3_bucket.index_snapshot_bucket.arn}/*"
      },
      {
        "Action" : [
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "${aws_s3_bucket.index_snapshot_bucket.arn}"
        ]
      },
      {
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "${aws_s3_bucket.index_snapshot_bucket.arn}/*"
        ]
      }
    ]
  })

  tags = local.filtered_common_tags
} */



resource "aws_iam_role" "index_snapshot_role" {
  name = "${module.aws_resource_tags.account}-${var.application}-index-snapshot-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "es.amazonaws.com"
          AWS     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${module.aws_resource_tags.account}/contentsearch/${module.aws_resource_tags.account}-contentsearch-${module.aws_resource_tags.environment}-svc-user"
        }
      },
    ]
  })

  tags = local.filtered_common_tags
}

# data "aws_iam_policy_document" "index_snapshot_policy_doc" {
#   # Allow the ECS task to assume the role of the ECS service.
#   Statement = [
#     {
#       "Effect" : "Allow",
#       "Action" : "iam:PassRole",
#       "Resource" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.index_snapshot_role.name}"
#     },
#     {
#       "Effect" : "Allow",
#       "Action" : "es:ESHttpPut",
#       "Resource" : "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${aws_opensearch_domain.opensearch.domain_name}/*"

#     },
#     {
#       "Action" : [
#         "s3:ListBucket"
#       ],
#       "Effect" : "Allow",
#       "Resource" : [
#         "${aws_s3_bucket.index_snapshot_bucket.arn}"
#       ]
#     },
#     {
#       "Action" : [
#         "s3:GetObject",
#         "s3:PutObject",
#         "s3:DeleteObject"
#       ],
#       "Effect" : "Allow",
#       "Resource" : [
#         "${aws_s3_bucket.index_snapshot_bucket.arn}/*"
#       ]
#     },
#     {
#       "Effect" : "Allow",
#       "Action" : [
#         "opensearch:PutSnapshotRepository"
#       ],
#       "Resource" : [
#         "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${aws_opensearch_domain.opensearch.domain_name}/*"
#       ]
#     },
#   ]
# }

resource "aws_iam_policy" "index_snapshot_policy" {
  name = "S3_OpenSearch_Snapshot_Management_Policy"
  #role = aws_iam_role.index_snapshot_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax. 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.index_snapshot_role.name}"
      },
      {
        "Effect" : "Allow",
        "Action" : "es:ESHttpPut",
        "Resource" : "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${aws_opensearch_domain.opensearch.domain_name}/*"

      },
      {
        "Action" : [
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "${aws_s3_bucket.index_snapshot_bucket.arn}"
        ]
      },
      {
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "iam:PassRole"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "${aws_s3_bucket.index_snapshot_bucket.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "opensearch:PutSnapshotRepository"
        ],
        "Resource" : [
          "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${aws_opensearch_domain.opensearch.domain_name}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "index_snapshot_attach" {
  role       = aws_iam_role.index_snapshot_role.name
  policy_arn = aws_iam_policy.index_snapshot_policy.arn
}

/*
# provider "opensearch" {
#   # Configuration options
#   url                 = "https://vpc-aam-contentsearch-nonprod-qa4cf3bqjxx4fevi4ecanevdde.us-east-1.es.amazonaws.com/"
#   aws_assume_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.index_snapshot_role.name}"
#   healthcheck         = false
#   /* aws_access_key      = jsondecode(local.assumed_role_credentials.Credentials.AccessKeyId)
#   aws_secret_key      = jsondecode(local.assumed_role_credentials.Credentials.SecretAccessKey)
#   aws_token           = jsondecode(local.assumed_role_credentials.Credentials.SessionToken) */

#   #aws_access_key = data.external.assume_role.result["AccessKeyId"]
#   #aws_secret_key = data.external.assume_role.result["SecretAccessKey"]
#   #aws_token      = data.external.assume_role.result["SessionToken"]

#   aws_access_key = data.external.session_token.result["AccessKeyId"]
#   aws_secret_key = data.external.session_token.result["SecretAccessKey"]
#   aws_token      = data.external.session_token.result["SessionToken"]
# }


# Create a snapshot repository for backing up individual indexes
# resource "opensearch_snapshot_repository" "repo" {
#   for_each = local.opensearch_snapshot_repository_map
#   #provider = opensearch.with_url
#   #name     = aws_s3_bucket.index_snapshot_bucket.id
#   name = each.value
#   type = "s3"
#   settings = {
#     bucket   = aws_s3_bucket.index_snapshot_bucket.id
#     region   = data.aws_region.current.name
#     role_arn = aws_iam_role.index_snapshot_role.arn
#   }
# }


# Create a role mapping
# resource "opensearch_roles_mapping" "snapshot_mapper" {
#   role_name   = "manage_snapshots"
#   description = "Mapping AWS IAM roles to OpenSearch role"
#   backend_roles = [
#     "${aws_iam_role.index_snapshot_role.arn}"
#   ]
# }



# Null Resource to Create OpenSearch Snapshot Repository
# resource "null_resource" "opensearch_snapshot_repository" {
#   triggers = {
#     opensearch_snapshot_policy_name = null_resource.opensearch_snapshot_policy.triggers["opensearch_snapshot_role_name"]
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       aws opensearch create-snapshot-repository --domain-name ${data.aws_opensearch_domain.existing_opensearch_domain.domain_name} --repository-name your-snapshot-repo --repository-type s3 --s3-bucket ${data.aws_s3_bucket.existing_s3_bucket.bucket} --s3-role-arn ${aws_iam_role.opensearch_snapshot_role.arn}
#     EOT
#   }
# }


# Null Resource to Create OpenSearch Snapshot Repository
# resource "null_resource" "opensearch_snapshot_repository" {
#   # triggers = {
#   #   opensearch_snapshot_policy_name = null_resource.opensearch_snapshot_policy.triggers["opensearch_snapshot_role_name"]
#   # }

#   provisioner "local-exec" {
#     command = <<-EOT
#       aws opensearch create-snapshot-repository --domain-name ${aws_opensearch_domain.opensearch.domain_name} --repository-name backup_snapshot_repo_index_1 --repository-type s3 --s3-bucket ${aws_s3_bucket.index_snapshot_bucket.bucket} --s3-role-arn ${aws_iam_role.index_snapshot_role.arn}
#     EOT
#   }
# }



/* module "opensearch-test" {
  source = "git@github.mheducation.com:udit-meghraj/aws-opensearch.git?ref=opensearch-initial"
  
  name           = "test-opensearch"
  ## Cluster Configuration
  instance_count = 3
  instance_type  = "t3.small.elasticsearch"
  ## EBS Setup
  volume_type = "gp3"
  volume_size    = 10
  ## Networking setup
  vpc_id  = module.turbot-network.vpc_id
  subnet_ids     = module.turbot-network.internal_subnet_ids
  ## Advance security option enabled/disabled
  security_enabled = true
  ## Internal database master user/password setup.
  ## Note: when internal user database is set to false, it will require to use master user arn instead. Line 212
  internal_user_database_enabled = var.internal_user_database_enabled[terraform.workspace]  
  master_user_arn      = var.internal_user_database_enabled == false ? var.master_user_arn : null
  master_user_name     = "admin"
  master_password      = "Admin1234$"

  ## Option to enabled OpenSearch backup to s3.
  s3_snapshots_enabled             = true
  tags = local.filtered_common_tags
}
resource "aws_elasticsearch_domain_policy" "opensearch" {
  domain_name = module.opensearch-test.domain_name

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
      {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${module.opensearch-test.domain_name}/*"
      }
    ]
}
POLICIES
} */
