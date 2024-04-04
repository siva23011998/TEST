variable "alb_deletion_protection_config_map" {
  default = {
    nonprod = true
    prod    = true
  }
  description = "Enable deletion protection for the load balancer"
  type        = map(bool)
}

variable "alb_logging_enabled_config_map" {
  default = {
    nonprod = true
    prod    = true
  }
  description = "Pipe load balancer access logs to s3"
  type        = map(bool)
}

variable "alb_logging_bucket_config_map" {
  default = {
    # nonprod = "" // Provide any value to override default naming
    # prod    = "" // Provide any value to override default naming
  }
  description = "Name of the S3 bucket to store load balancer access logs"
  type        = map(string)
}

variable "alb_logging_subdirectory_config_map" {
  default = {
    nonprod = ""
    prod    = ""
  }
  description = "S3 key prefix (directory) to store load balancer access logs"
  type        = map(string)
}

variable "alb_healthcheck_path_config_map" {
  default = {
    nonprod = "/v1"
    prod    = "/v1"
  }
  description = "URL path the load balancer should use to check the health of an instance"
  type        = map(string)
}

# "traffic-port"
variable "alb_healthcheck_port_config_map" {
  default = {
    nonprod = "traffic-port"
    prod    = "traffic-port"
  }
  description = "Port the load balancer should use to check the health of an instance"
  type        = any
}

variable "alb_healthcheck_protocol_config_map" {
  default = {
    nonprod = "HTTP"
    prod    = "HTTP"
  }
  description = "Protocol the load balancer should use to check the health of an instance"
  type        = map(string)
}

variable "alb_deregistration_delay_seconds_config_map" {
  default = {
    nonprod = 20
    prod    = 60
  }
  description = "How many seconds to wait for deregistration of targets."
  type        = map(number)
}

locals {
  alb_deletion_protection  = var.alb_deletion_protection_config_map[local.environment]
  alb_logging_enabled      = var.alb_logging_enabled_config_map[local.environment]
  alb_logging_bucket       = lookup(var.alb_logging_bucket_config_map, local.environment, join("-", [local.resource_prefix, "alb-logs"]))
  alb_logging_subdirectory = var.alb_logging_subdirectory_config_map[local.environment]
  alb_healthcheck_path     = var.alb_healthcheck_path_config_map[local.environment]
  alb_healthcheck_port     = var.alb_healthcheck_port_config_map[local.environment]
  alb_healthcheck_protocol = var.alb_healthcheck_protocol_config_map[local.environment]
  alb_deregistration_delay_seconds = var.alb_deregistration_delay_seconds_config_map[local.environment]
  alb_default_cert_name    = "default-cert.${local.aws_route53_zone_name}"
  alb_worker_default_cert_name    = "default-worker-cert.${local.aws_route53_zone_name}"
  target_group_suffix      = var.target_group_suffix_name_map[terraform.workspace]
}
