resource "aws_s3_bucket" "remote_state" {
  # Restrictions apply for names: http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
  bucket = var.TF_STATE_BUCKET_NAME

  # Disallow destroying of remote state bucket when it's not empty
  force_destroy = false

  # logging {
  #   target_bucket = "${module.configurator.terraform-management-bucket}"
  #   target_prefix = "log-${var.application}/"
  # }

  lifecycle {
    # This flag will cause Terraform to reject with an error any plan 
    # that would destroy the infrastructure object associated with the resource, 
    # as long as the argument remains present in the configuration.
    prevent_destroy = true
  }

  tags = local.filtered_common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remote_state_enc" {
  bucket = aws_s3_bucket.remote_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "remote_state_versioning" {
  bucket = aws_s3_bucket.remote_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  count  = terraform.workspace == "nonprod" ? 1 : 0
  bucket = aws_s3_bucket.remote_state.id
  acl    = "private"
}

# MustBeEncryptedInTransit SID is managed by Turbot with eventual consistency.
resource "aws_s3_bucket_policy" "remote_state_bucket_policy" {
  bucket = aws_s3_bucket.remote_state.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "MustBeEncryptedInTransit",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.remote_state.id}",
        "arn:aws:s3:::${aws_s3_bucket.remote_state.id}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
