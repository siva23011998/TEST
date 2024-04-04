locals {
  container_image = "repo.mhe.io/docker/content-authoring/content-search-api:commit_8ac780d58b4b145de04ebb6148fd1c7866adb106"

  # container_port = 8080
  container_port = 80

  account_type    = terraform.workspace == "prod" ? "prod" : "nonprod"
  iam_path_prefix = join("/", ["", var.common_tags.Account, var.common_tags.Application, ""])
  # contentsearch_sdlc_fqdn = "blue-${local.environment}.${data.terraform_remote_state.shared.outputs.aws-dns-public-zone.hosted_zone.name_trimmed}"

  service_full_name                   = join("-", [var.common_tags.Account, var.common_tags.Application, var.common_tags.Environment, var.service_name])
  service_full_name_without_account   = join("-", [var.common_tags.Application, var.common_tags.Environment, var.service_name])
  task_min_count                      = var.dark_enabled ? 0 : var.task_min_count_config_map[terraform.workspace]
  task_max_count                      = var.dark_enabled ? 1 : var.task_max_count_config_map[terraform.workspace]
  task_cpu_target_percent             = var.dark_enabled ? 100 : var.task_cpu_target_percent_config_map[terraform.workspace]
  task_memory_target_percent          = var.dark_enabled ? 100 : var.task_memory_target_percent_config_map[terraform.workspace]
  task_healthcheck_timeout_in_seconds = var.task_healthcheck_timeout_in_seconds_config_map[terraform.workspace]
  deregistration_delay_seconds        = var.deregistration_delay_seconds_config_map[terraform.workspace]
  start_delay_seconds                 = var.start_delay_seconds_config_map[terraform.workspace]

  tass_grant_type = "client_credentials"
  tass_scope      = "auth"
  // Adding this to prevent task defintion from trying to reference dark-contentsearch
  application = "contentsearch"
  function    = var.common_tags["Function"]

  datadog_container_image = "repo.mhe.io/docker/amazon/aws-for-fluent-bit:2.31.12.20230727"
}
