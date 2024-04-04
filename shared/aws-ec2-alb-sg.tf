
# Security groups for dynamic port mapping, ALB and Launch Template.
# https://github.mheducation.com/terraform-incubator/aws-ec2-alb-sg
module "aws_ec2_alb_sg" {
  source = "git@github.mheducation.com:terraform/aws-ec2-alb-sg.git?ref=2.4.0"

  vpc_id = module.turbot-network.vpc_id
  tags   = local.filtered_common_tags
}
