terraform {
  required_version = "~> 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
  }

  backend "s3" {
    encrypt = true # this is required when server-side encryption at rest is enabled on bucket
  }
}

provider "aws" {
  region = var.aws_region
}

provider "null" {
}
