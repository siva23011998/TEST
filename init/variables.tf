variable "aws_region" {
  description = "AWS Region to operate within. May be obsolete?"
  type        = string
  default     = "us-east-1"
}

variable "TF_STATE_BUCKET_NAME" {
  description = "Name of the S3 bucket to create for storing state files."
  type        = string
}

variable "aws_account" {
  description = "Name of the aws account where the application is hosted (AAM|ACT)"
  type        = string
}
