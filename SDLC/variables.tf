variable "aws_region" {
  description = "AWS Region to manage resources in."
  type        = string
  default     = "us-east-1"
}

variable "zone_name" {
  description = "Map of zone names for environments"
  type        = map(string)
}

variable "log_level" {
  type = string
  default = "warn"
}

variable "log_file" {
  type = string
  default = "application.log"
}
variable "log_appender" {
  type = string
  default = "console"
}
