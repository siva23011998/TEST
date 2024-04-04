# WARNING! DON'T ADD MORE CODE HERE.
# THIS FILE IS USED FOR BASE AMI ROTATION AND TO MAKE SURE NOTHING ELSE IS CHANGED
# SEE .github/workflows/infrastructure-ami.yml
locals {
  # Based on account type. See https://github.mheducation.com/base-amis/amazon-linux-ecs-optimized/releases
  # Intent of separate variables is to separate concerns:
  # - Update nonprod and let it cook for a few days before updating nonprod. Ideally most of the issues would have been caught.
  # - If there is any reason to quickly update or roll back prod infrastructure without also updating Base AMI. Such as hotfix.
  # - Automation workflow would update only cluster-related resources without touching RDS, ECS and such
  #ami_version_nonprod = "3.17.0"
  ami_version_nonprod = "3.30.0"
  ami_version_prod    = "3.30.0"
}
