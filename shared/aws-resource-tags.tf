# Automatically generate tags for your AWS resources. https://confluence.mheducation.com/x/1CMFBw
# https://github.mheducation.com/terraform/aws-resource-tags
module "aws_resource_tags" {
  source = "git@github.mheducation.com:terraform/aws-resource-tags.git?ref=4.2.0"

  # account   = data.aws_caller_identity.current.account_id
  account     = local.mhe_account_id
  application = var.application
  environment = local.environment
  function    = var.function
  platform    = var.platform
  runteam     = var.runteam
}
locals {
  filtered_common_tags = {
    for key, value in module.aws_resource_tags.common_tags : key => value if value != ""
  }
  worker_filtered_common_tags = {
    for key, value in module.aws_resource_tags_worker.common_tags : key => value if value != ""
  }
}
module "aws_resource_tags_worker" {
  source      = "git@github.mheducation.com:terraform/aws-resource-tags.git?ref=4.2.0"
  account     = local.mhe_account_id
  application = "contentsearch-worker"
  environment = local.environment
  function    = "worker"
  platform    = var.platform
  runteam     = var.runteam
}
output "common_tags_worker" {
  value = module.aws_resource_tags_worker.common_tags
}

# Variables for the `aws-resource-tags` module.

variable "application" {
  description = "See https://confluence.mheducation.com/pages/viewpage.action?pageId=117777364"
  type        = string
}

variable "platform" {
  description = "NextGenAuthoring, connect, openlearning, connected, etc.. See https://confluence.mheducation.com/pages/viewpage.action?pageId=117777364"
  type        = string
}

variable "function" {
  description = "See https://confluence.mheducation.com/pages/viewpage.action?pageId=117777364"
  type        = string
  default     = ""
}

variable "runteam" {
  description = "See https://confluence.mheducation.com/pages/viewpage.action?pageId=117777364"
  type        = string
}
