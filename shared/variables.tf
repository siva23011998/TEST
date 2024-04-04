variable "aws_region" {
  description = "AWS region to put resources in."
  type        = string
  default     = "us-east-1"
}

variable "zone_name" {
  description = "Fully qualified zone name, such as 'mysubdomain.nonprod.mheducation.com'"
  type        = map(string)
}

variable "dead_letter_email_list" {
  description = "List of emails to subscribe to the dead letter SNS topic to receive various errors"
  type        = list(string)
  default     = []
}

# variable "elasticache_node_params" {
#   description = "Configuration for memcached resources. TODO: move to -config file similar to other resources."
#   type        = map(any)
#   default = {
#     node_type = {
#       nonprod = "cache.t3.small"
#       prod    = "cache.t3.medium"
#     }
#     num_cache_nodes = {
#       nonprod = "1"
#       prod    = "1"
#     }
#     engine_version = {
#       nonprod = "1.4.14"
#       prod    = "1.4.14"
#     }
#     parameter_group_name = {
#       nonprod = "default.memcached1.4"
#       prod    = "default.memcached1.4"
#     }
#   }
# }


# some WAFv2 vars
variable "scope" {
  description = "Scope for WAF v2, REGIONAL or global Cloudfront"
  type        = string
  default     = "REGIONAL"
}

variable "default_rule_action" {
  description = "Default action for rules. True is block, false is allow."
  type        = string
  default     = "COUNT"
}

variable "waf_acl_default_action_block" {
  description = "Block by default?"
  type        = bool
  default     = false
}

variable "target_group_suffix_name_map" {
  description = "Target group suffix name for ECS services in SDLC layer"
  type        = map(list(string))
  default = {
    nonprod = ["dev", "qastg", "qalv", "qastg", "pqa", "demo"]
    prod    = ["blue", "green"]
  }
}

variable "aliases" {
  type = map(object({
    dns_name = string
  }))
}
variable "aliases_worker" {
  type = map(object({
    dns_name = string
  }))
}
variable "aliases_api_prod" {
  type = map(object({
    dns_name = string
  }))
}
variable "aliases_worker_prod" {
  type = map(object({
    dns_name = string
  }))
}

# OpenSearch vars
variable "opensearch_version" {
  description = "Version of OpenSearch to use"
  default     = "OpenSearch_2.11"
}

variable "opensearch_instance_type" {
  default = {
    nonprod = "r6g.4xlarge.search"
    prod    = "r6g.4xlarge.search"

  }
  type = map(string)
}

variable "opensearch_number_of_instances" {
  default = {
    nonprod = 3
    prod    = 3

  }
  type = map(number)
}

variable "opensearch_masternode_enabled" {
  default = {
    nonprod = false
    prod    = true
  }
  type = map(bool)
}


variable "opensearch_masternode_type" {
  default = {
    nonprod = "t3.small.search"
    prod    = "r6g.large.search"
  }
  type = map(string)
}


variable "opensearch_masternode_count" {
  default = {
    nonprod = 0
    prod    = 3
  }
  type = map(number)
}

variable "opensearch_ebs_volume_size" {
  default = {
    nonprod = 500
    prod    = 500
  }
  type = map(number)
}

variable "opensearch_ebs_volume_type" {
  default = {
    nonprod = "gp3"
    prod    = "gp3"
  }
  type = map(string)
}


variable "warm_enabled_map" {
  default = {
    nonprod = false
    prod    = false
  }
  type = map(bool)
}

variable "warm_count_map" {
  default = {
    nonprod = 3
    prod    = 3
  }
  type = map(number)
}

variable "warm_type_map" {
  default = {
    nonprod = "ultrawarm1.medium.search"
    prod    = "ultrawarm1.medium.search"
  }
  type = map(string)
}

variable "master_user_name_map" {
  description = "OpenSearch master username mapping for dfa OpenSearch Auth."
  type        = map(string)
  default = {
    nonprod = "dummy_replace_with_actual"
    pqa     = "dummy_replace_with_actual"
    prod    = "dummy_replace_with_actual"
  }
}
variable "opensearch_masteruser_name" {
  description = "OpenSearch master username mapping."
  type        = map(string)
  default = {
    nonprod = "dummy_replace_with_actual"
    pqa     = "dummy_replace_with_actual"
    prod    = "dummy_replace_with_actual"
  }
}
variable "advance_security_enabled" {
  default = {
    nonprod = true
    pqa     = true
    prod    = true
  }
  type = map(bool)
}
variable "internal_user_database_enabled" {
  default = {
    nonprod = true
    pqa     = true
    prod    = true
  }
  type = map(bool)
}
variable "master_user_arn" {
  type        = string
  description = "ARN for the main user. Only specify if internal_user_database_enabled is not set or set to false"
  default     = null
}
