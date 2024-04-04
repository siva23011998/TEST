variable "workload_entity_search_queries" {
  description = "<p>Workload Queries.</p>"
  type        = list(string)
  default = [
    "name like 'cinch'",
  ]
}

variable "platform" {
  description = "Name of the application platform"
  type        = string
}

variable "application" {
  description = "Name of the application"
  type        = string
}

variable "aws_account" {
  description = "Name of the aws account where the application is hosted (AEF|ACT)"
  type        = string
}

variable "NR_ACCOUNT_ID" {
  description = "Newrelic Account Numerical ID"
  type        = string
}

variable "NR_API_KEY" {
  description = "Newrelic API key"
  type        = string
}

variable "NR_ALERT_COND_FLAG" {
  description = "Newrelic Alert conditions flag to set enable or disable the condition (true or false)"
  type        = string
  default     = "true"
}




