terraform {
  required_version = "~> 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    # template = {
    #   source  = "hashicorp/template"
    #   version = "~> 2.2"
    # }
  }

  backend "s3" {
    encrypt = true # this is required when server-side encryption at rest is enabled on bucket
  }
}

provider "aws" {
  region = var.aws_region
}

provider "archive" {
}

# provider "template" {
# }

provider "null" {
}
