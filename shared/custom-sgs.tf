# locals {
#   reaper_monitoring_ips = [
#     "10.213.6.136/32",
#     "10.212.6.174/32"
#   ]
# }

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# resource "aws_security_group" "rds_monitoring" {
#   name        = "Reaper_RDS_Monitoring"
#   description = "Reaper RDS monitoring for DBA team"
#   tags        = local.filtered_common_tags
#   vpc_id      = module.turbot-network.vpc_id
# }

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# resource "aws_security_group_rule" "reaper_ingress_mysql" {
#   description       = "Reaper monitoring for RDS MySQL"
#   type              = "ingress"
#   from_port         = 3306
#   to_port           = 3306
#   protocol          = "tcp"
#   cidr_blocks       = local.reaper_monitoring_ips
#   security_group_id = aws_security_group.rds_monitoring.id
# }

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# resource "aws_security_group_rule" "reaper_ingress_oracle" {
#   description       = "Reaper monitoring for RDS Oracle"
#   type              = "ingress"
#   from_port         = 1521
#   to_port           = 1521
#   protocol          = "tcp"
#   cidr_blocks       = local.reaper_monitoring_ips
#   security_group_id = aws_security_group.rds_monitoring.id
# }

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# resource "aws_security_group_rule" "reaper_ingress_postgres" {
#   description       = "Reaper monitoring for RDS PostgreSQL"
#   type              = "ingress"
#   from_port         = 5432
#   to_port           = 5432
#   protocol          = "tcp"
#   cidr_blocks       = local.reaper_monitoring_ips
#   security_group_id = aws_security_group.rds_monitoring.id
# }

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# resource "aws_security_group_rule" "reaper_ingress_mssql" {
#   description       = "Reaper monitoring for RDS MSSQL"
#   type              = "ingress"
#   from_port         = 1433
#   to_port           = 1433
#   protocol          = "tcp"
#   cidr_blocks       = local.reaper_monitoring_ips
#   security_group_id = aws_security_group.rds_monitoring.id
# }

# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# resource "aws_security_group_rule" "reaper_egress" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "all"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.rds_monitoring.id
# }


resource "aws_security_group" "opensearch" {
  name        = join("-", [ local.mhe_account_id, local.filtered_common_tags.Application, local.filtered_common_tags.Environment, "opensearch" ])
  description = "Managed by Terraform"
  vpc_id      = data.aws_vpc.non-default.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = ["10.233.13.0/24"]
  }
  lifecycle {
    ignore_changes = [ingress]
  }
}

resource "aws_security_group_rule" "zscalar" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.opensearch.id
  cidr_blocks       = ["10.236.16.0/23", "10.233.62.0/23"]
  description       = "ZPA"
}
