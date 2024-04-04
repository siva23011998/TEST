# Drains instances during rotation or scale in
# https://github.mheducation.com/denis-vishniakov/aws-ecs-instance-drain
# module "aws_ecs_instance_drain" {
#   source                 = "git::ssh://git@github.mheducation.com/denis-vishniakov/aws-ecs-instance-drain.git?ref=vdv-v2"
#   account                = module.aws_resource_tags.account
#   dead_letter_target_arn = aws_sns_topic.dead_letter.arn
#   # TODO: fix the module to allow empty Function
#   tags = merge(local.filtered_common_tags, { "Function" = "" })
# }
