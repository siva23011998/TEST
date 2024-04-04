terraform {

  required_version = "0.14.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 2.12"
    }
  }
}

# https://registry.terraform.io/providers/newrelic/newrelic/latest/docs
provider "newrelic" {
  region = "US"
  # Your New Relic account ID. The NEW_RELIC_ACCOUNT_ID environment variable can also be used.
  account_id = var.NR_ACCOUNT_ID
  # api_key - Your New Relic Personal API key (usually prefixed with NRAK). The NEW_RELIC_API_KEY environment variable can also be used.
  api_key = var.NR_API_KEY
}

provider "aws" {
  region = "us-east-1"
}