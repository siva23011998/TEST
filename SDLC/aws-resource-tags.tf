# Automatically generate tags for your AWS resources. https://confluence.mheducation.com/x/1CMFBw
# https://github.mheducation.com/terraform/aws-resource-tags

module "aws_resource_tags" {
  source      = "git@github.mheducation.com:terraform/aws-resource-tags.git?ref=4.2.0"
  account     = local.mhe_account_id
  application = var.application
  environment = local.environment
  function    = var.function
  platform    = var.platform
  runteam     = var.runteam
}

module "aws_resource_tags_api" {
  source      = "git@github.mheducation.com:terraform/aws-resource-tags.git?ref=4.2.0"
  account     = local.mhe_account_id
  application = var.application
  environment = local.environment
  function    = "api"
  platform    = var.platform
  runteam     = var.runteam
}

module "aws_resource_dark_tags_api" {
  source      = "git@github.mheducation.com:terraform/aws-resource-tags.git?ref=4.2.0"
  account     = local.mhe_account_id
  application = "dark-${var.application}"
  environment = local.environment
  function    = "api"
  platform    = var.platform
  runteam     = var.runteam
}

module "aws_resource_tags_worker" {
  source      = "git@github.mheducation.com:terraform/aws-resource-tags.git?ref=4.2.0"
  account     = local.mhe_account_id
  application = var.application
  environment = local.environment
  function    = "worker"
  platform    = var.platform
  runteam     = var.runteam
}


module "aws_resource_dark_tags_worker" {
  source      = "git@github.mheducation.com:terraform/aws-resource-tags.git?ref=4.2.0"
  account     = local.mhe_account_id
  application = "dark-${var.application}"
  environment = local.environment
  function    = "worker"
  platform    = var.platform
  runteam     = var.runteam
}

module "aws_resource_tags_sqs" {
  source      = "git@github.mheducation.com:terraform/aws-resource-tags.git?ref=4.2.0"
  account     = local.mhe_account_id
  application = var.application
  environment = local.environment
  function    = "sqs"
  platform    = var.platform
  runteam     = var.runteam
}
/* module "aws_resource_dark_tags_worker_deployment" {
  source      = "git@github.mheducation.com:terraform/aws-resource-tags.git?ref=4.2.0"
  account     = local.mhe_account_id
  application = "dark-${var.application}"
  environment = local.environment
  function    = "worker"
  platform    = var.platform
  runteam     = var.runteam
} */
locals {
  filtered_common_tags = {
    for key, value in module.aws_resource_tags.common_tags : key => value if value != ""
  }
  filtered_common_tags_api = {
    for key, value in module.aws_resource_tags_api.common_tags : key => value if value != ""
  }
  filtered_common_dark_tags_api = {
    for key, value in module.aws_resource_dark_tags_api.common_tags : key => value if value != ""
  }
  filtered_common_tags_worker = {
    for key, value in module.aws_resource_tags_worker.common_tags : key => value if value != ""
  }
  filtered_common_dark_tags_worker = {
    for key, value in module.aws_resource_dark_tags_worker.common_tags : key => value if value != ""
  }
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
