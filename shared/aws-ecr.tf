# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
resource "aws_ecr_repository" "api" {
  name = "${local.filtered_common_tags.Account}-${local.filtered_common_tags.Application}-${local.filtered_common_tags.Environment}-api"
  tags = local.filtered_common_tags
    image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "worker" {
  name = "${local.filtered_common_tags.Account}-${local.filtered_common_tags.Application}-${local.filtered_common_tags.Environment}-worker"
  tags = local.filtered_common_tags
    image_scanning_configuration {
    scan_on_push = true
  }
}