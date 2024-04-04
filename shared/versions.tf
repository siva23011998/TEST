terraform {
  # https://www.terraform.io/docs/language/expressions/version-constraints.html
  required_version = "~> 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }

    # OpenSearch provider which supports additional features that the aws does not
    # Originally added to create snapshots for individual indexes.
    # Override default opensearch provider settings with settings set in this context
    opensearch = {
      /* source  = "opensearch-project/opensearch"
      version = "2.0.0" */
      source  = "jamesanto/opensearch"
      version = "2.0.3"
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
