# # This file configures AWS SES resources in order to pass DKIM verification.
# #   SPF & DMARC verification for mheducation.com is already established in the mheducation.com zone
# # Additional pre-requisites:
# # - Set up SMTP settings in AWS SES and obtain credentials
# # - Minimal IAM permissions required for the service users (or personal user) could be found in ./init/user.tf in SIDs starting with "SES"

# locals {
#   ses_sending_domain = "mheducation.com"
#   ses_sending_email  = "no-reply-cinchlearning@mheducation.com"
# }

# # For the MAIL FROM domain to be fully usable, this resource should be paired with the aws_ses_domain_identity resource.
# # + To validate the MAIL FROM domain, a DNS MX record is required. See below for `mx_mail_from`
# # + To pass SPF checks, a DNS TXT record may also be required. See below for `txt_spf`
# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_mail_from
# resource "aws_ses_domain_mail_from" "cinch" {
#   # (Required) Verified domain name to generate DKIM tokens for.
#   # Could be mheudcation.com
#   domain = aws_ses_domain_identity.mhe_default.domain

#   # This one seems to be the same across all MHE.
#   # (Required) Subdomain (of above domain) which is to be used as MAIL FROM address (Required for DMARC validation)
#   mail_from_domain = "amazon.${aws_ses_domain_identity.mhe_default.domain}"

#   behavior_on_mx_failure = "UseDefaultValue" # or "RejectMessage"
# }

# # This resource seem to produce the same output after recreation.
# # At least in the same AWS account within short period of time.
# # DKIM for amazon.mheducation.com is already added to the mheducation.com DNS zone
# resource "aws_ses_domain_dkim" "mheducation_com" {
#   domain = aws_ses_domain_identity.mhe_default.domain
# }

# # This domain seems to be the same across most of MHE.
# # Without it created in your account, you'll get this error for mail_from resource: 
# #  "Error setting MAIL FROM domain: InvalidParameterValue: Identity <mheducation.com> does not exist."
# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity
# resource "aws_ses_domain_identity" "mhe_default" {
#   domain = local.ses_sending_domain
# }

# # Send notifications
# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_identity_notification_topic
# resource "aws_ses_identity_notification_topic" "cinch" {
#   for_each = toset(["Bounce", "Complaint"]) # Valid Values: Bounce, Complaint or Delivery.

#   notification_type        = each.value
#   topic_arn                = aws_sns_topic.dead_letter.arn
#   identity                 = aws_ses_domain_identity.mhe_default.domain
#   include_original_headers = true
# }

# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_email_identity
# resource "aws_ses_email_identity" "default" {
#   for_each = toset([
#     local.ses_sending_email
#   ])
#   email = each.value
# }

# resource "aws_ses_identity_policy" "cinch" {
#   identity = aws_ses_domain_identity.mhe_default.domain
#   name     = "cinch"
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "AuthorizeAWS",
#         "Effect" : "Allow",
#         "Resource" : "arn:aws:ses:us-east-1:${data.aws_caller_identity.current.account_id}:identity/${local.ses_sending_domain}",
#         "Principal" : {
#           "AWS" : [
#             tostring(data.aws_caller_identity.current.account_id)
#           ]
#         },
#         "Action" : [
#           "SES:SendEmail",
#           "SES:SendRawEmail"
#         ],
#         "Condition" : {
#           "StringLike" : {
#             "ses:FromAddress" : local.ses_sending_email
#           }
#         }
#       }
#     ]
#   })
# }

# # Resources for verifying domain, for DKIM tokens, for MX, for SPF are managed manually for mheducation.com
