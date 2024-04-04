# Default VPC is Amazon's. Non-default is usually provisioned for us
data "aws_vpc" "non-default" {
  # searching for the only provisioned VPC
  filter {
    name   = "tag-key"
    values = ["aws:cloudformation:logical-id"]
  }

  filter {
    name   = "tag-value"
    values = ["Vpc"]
  }
  # default = false # doesn't work for some reason. finds multiple VPCs
  # Another working option, just for reference in case something will be changed in VPC setup
  # filter {
  #   name   = "isDefault"
  #   values = ["false"]
  # }
}
