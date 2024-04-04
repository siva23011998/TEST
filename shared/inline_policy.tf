##############################################################
######## ECS Register containers Inline policy
##############################################################
resource "aws_iam_policy" "inline-policy" {
    name = "ecs-container-inline-policy"
    count = length(var.inline_policy)
    policy = file("./${element(var.inline_policy, count.index)}")
}

resource "aws_iam_role_policy_attachment" "inline-policy-attach" {
    count = length(var.inline_policy)
    role = module.aws_ecs_asg_cluster.iam_role.name
    policy_arn = aws_iam_policy.inline-policy.*.arn[count.index]
}

data "aws_iam_policy" "ssm_policy" {
  name = "mh-ssm-managed-instance-policy"
}
  
resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role = module.aws_ecs_asg_cluster.iam_role.name
  policy_arn = data.aws_iam_policy.ssm_policy.arn
}