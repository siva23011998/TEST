# Look up the right AMI ID
# Lookup latest Base AMI releases: https://github.mheducation.com/base-amis/amazon-linux-ecs-optimized/releases
module "al2_ecs_ami" {
  source      = "git::ssh://git@github.mheducation.com/terraform/aws-base-ami.git?ref=3.2.1"
  ami_os      = "al2"
  ami_app     = "ecs"
  ami_version = "1.6.1_3"
  # Default value is 64-bit Intel/AMD
}

# ECS Cluster with ASG, Launch Templates, and modern scaling practices like capacity providers.
# https://github.mheducation.com/terraform-incubator/aws-ecs-asg-cluster
module "aws_ecs_asg_cluster" {
  source = "git@github.mheducation.com:terraform/aws-ecs-asg-cluster.git?ref=5.5.1"


  # General configuration
  ami_id        = module.al2_ecs_ami.ami_id
  instance_type = local.instance_type

  root_volume_size = 50
  #root_volume_type = "gp3"

  # Cluster size
  cluster_desired_size = local.cluster_min_size # Let the service determine how many instances to run
  cluster_min_size     = local.cluster_min_size
  cluster_max_size     = local.cluster_max_size
  target_capacity      = local.target_capacity

  # Network/VPC configuration
  #subnets = module.turbot-network.internal_subnet_ids # all internal subnets
  subnets = local.account_type == "prod" ? module.turbot-network.internal_subnet_ids : [module.turbot-network.internal_subnet_1_id, module.turbot-network.internal_subnet_2_id] #Using subnet 1 and 2 since "subnet-a0cfc4f8" is out of IPs.
  security_groups = [
    module.turbot-network.default_security_group_id,
    module.turbot-network.web_dma_security_group_id,
    module.aws_ec2_alb_sg.launch_template_security_group.id
  ]

  /* additional_user_data = replace(file("${path.module}/custom_additional_user_data.sh"),
  "$${efs_id}", aws_efs_file_system.worker.id) */


  #additional_user_data = data.template_file.user_data.rendered

  tags = local.filtered_common_tags

}

#data "template_file" "user_data" {
#  template = file("${path.module}/custom_additional_user_data.sh")
#  vars = {
#    efs_volume_id = aws_efs_file_system.worker.id
#  }
#}
