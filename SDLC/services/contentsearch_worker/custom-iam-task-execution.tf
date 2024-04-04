# Team/Application/Service-specific modifications

# TODO: Add a comment to highlight where this policy is used. During container run? During contaienr start by ECS agent?

# Additional permissions for the service
data "aws_iam_policy_document" "ecs_task_execution" {
  statement {
    sid    = "PullEcrImage"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages",
    ]
    resources = ["*"]
  }

  # Allow the ECS deployment process to read the list of keys from Parameter Store.
  statement {
    sid       = "SsmDescribeParameters"
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  # Allow the ECS deployment process to read the value of the specified keys from Parameter Store.
  statement {
    sid    = "SsmPsAccessToSpecificKeys"
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/global/infra/newrelic/*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/global/infra/datadog/*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/global/infra/ses/smtp/*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/global/infrastructure/CONTENT_SEARCH_SVC_USER_SECRET_KEY",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/global/infrastructure/CONTENT_SEARCH_SVC_USER_ACCESS_KEY_ID",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/global/infra/rds/cinch*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/contentsearch*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/bento-api/*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/metadata-api/*",
    ]
  }

  # Allow the New Relic Infrastructure ECS task perform these actions with CloudWatch Logs.
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

}

# The policy definition above gets added to the "IAM policy" here.
# https://www.terraform.io/docs/providers/aws/r/iam_policy.html
resource "aws_iam_policy" "ecs_task_execution" {
  # Apply the name based on an existing pattern
  name_prefix = join("-", [local.service_full_name, "custom-policy", var.common_tags.Environment])
  path        = local.iam_path_prefix

  description = "Custom policy for ${local.service_full_name} service in ${var.common_tags.Environment} environment."

  # The IAM policy from above.
  policy = data.aws_iam_policy_document.ecs_task_execution.json
  tags   = var.common_tags
}

# # Binds the policy (we just defined in the above two blocks) to the IAM role we
# # created above.
# #
# # https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
# resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
#   role       = data.terraform_remote_state.shared.outputs.aws-ecs-asg-cluster.iam_role.name
#   policy_arn = aws_iam_policy.ecs_task_execution.arn
# }

# This is the policy which defines the trust relationship between the ECS task
# and the ECS service. This policy is applied to the IAM role.
#
# https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html
# https://learn.hashicorp.com/terraform/aws/iam-policy
# https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_understand.html
data "aws_iam_policy_document" "ecs_task_execution_trust" {
  # Allow the ECS task to assume the role of the ECS service.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# The IAM role allows the Docker Agent to fetch image and secrets
# https://www.terraform.io/docs/providers/aws/r/iam_role.html
resource "aws_iam_role" "ecs_task_execution" {
  # length of name_prefix to be in the range (1 - 32)
  # name_prefix        = local.service_full_name_without_account
  path               = local.iam_path_prefix
  description        = "The task execution role for the ${local.service_full_name} service in ${var.common_tags.Environment} environment."
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_trust.json
  tags               = var.common_tags
}

# Binds the policy (we just defined in the above two blocks) to the IAM role we
# created above.
#
# https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}
