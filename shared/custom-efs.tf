# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system
resource "aws_efs_file_system" "worker" {
  creation_token   = local.name_prefix
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = merge(local.filtered_common_tags, {
    Name      = "${local.mhe_account_id}-${var.platform}-contentsearch-worker"
    awsbackup = "true" # For MHE-approved automatic backup system
  })


  ## transition_to_ia is set to "AFTER_14_DAYS", which means that after 14 days,
  ## the file system will transition data to the Infrequent Access (IA) storage class.
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [creation_token]
  }

}

resource "aws_efs_mount_target" "mt_worker" {
  for_each       = toset(module.turbot-network.internal_subnet_ids)
  file_system_id = aws_efs_file_system.worker.id
  subnet_id      = each.key
}

# Create a new access point for worker to store last run. If this works as expected, this comment and permissions 777 below can be removed as the owner would be logstash.
# If this access point is mounted in the host instead, the owner will be ec2-user 
resource "aws_efs_access_point" "worker_lastruns_access_point" {
  file_system_id = aws_efs_file_system.worker.id 

  # We are making a subdirectory `lastruns` to be the root directory of this access point. This will just be a sub folder within the file system
  root_directory {
    path = "/lastruns"

    # This should be the posix ids for logstash user when mounted to the container
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "777"
    }
  }

  # This should be the posix ids for logstash user when mounted to the container
  posix_user {
    gid = 1000
    uid = 1000
  }
}

