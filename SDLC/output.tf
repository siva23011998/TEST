output "sdlc_fqdn_api" {
  description = "FQDN to access services."
  value = {
    "contentsearch-api" = local.contentsearch_sdlc_fqdn_api
  }
}
output "sdlc_fqdn_api_dark" {
  description = "FQDN to access services."
  value = {
    "contentsearch-api-dark" = local.contentsearch_dark_sdlc_fqdn_api
  }
}

output "sdlc_fqdn_worker" {
  description = "FQDN to access services."
  value = {
    "contentsearch-worker" = local.contentsearch_sdlc_fqdn_worker
  }
}
output "sdlc_fqdn_worker_dark" {
  description = "FQDN to access services."
  value = {
    "contentsearch-worker-dark" = local.contentsearch_dark_sdlc_fqdn_worker
  }
}
