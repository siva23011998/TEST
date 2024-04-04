locals {

  opensearch_snapshot_repository = [
    "${aws_s3_bucket.index_snapshot_bucket.id}",
    "backup_snapshot_repo_index_1",
    "backup_snapshot_repo_index_2"
  ]

  opensearch_snapshot_repository_map = {
    for idx, key in local.opensearch_snapshot_repository :
    idx => key
  }

  snapshot_resource_name = "${var.application}-opensearch-snapshot"

  #assumed_role_credentials = jsondecode(data.external.assume_role.result)

}