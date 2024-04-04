# These zones are expected to be present and externally managed just for safety.
# TODO: MOVE THIS TO .env
zone_name = {
  "nonprod" = "contentsearch.nonprod.mheducation.com",
  "prod"    = "contentsearch.mheducation.com",
}

inline_policy = [
  "register_container.json"
]

dead_letter_email_list = [
  "deadletter@mheducation.com", #SRE
]

aliases = {
  dev-api = {
    dns_name = "dev.contentsearch.nonprod.mheducation.com"
  }
  qastg-api = {
    dns_name = "qastg.contentsearch.nonprod.mheducation.com"
  }
  qalv-api = {
    dns_name = "qalv.contentsearch.nonprod.mheducation.com"
  }
  pqa-api = {
    dns_name = "pqa.contentsearch.nonprod.mheducation.com"
  }
  demo-api = {
    dns_name = "demo.contentsearch.nonprod.mheducation.com"
  }

}

aliases_api_prod = {
  prod-api = {
    dns_name = "contentsearch.mheducation.com"
  }
}

aliases_worker = {
  dev-worker = {
    dns_name = "dev.contentsearch.nonprod.mheducation.com"
  }
  qastg-worker = {
    dns_name = "qastg.contentsearch.nonprod.mheducation.com"
  }
  qalv-worker = {
    dns_name = "qalv.contentsearch.nonprod.mheducation.com"
  }
  pqa-worker = {
    dns_name = "pqa.contentsearch.nonprod.mheducation.com"
  }
  demo-worker = {
    dns_name = "demo.contentsearch.nonprod.mheducation.com"
  }
}

aliases_worker_prod = {
  prod-worker = {
    dns_name = "contentsearch.mheducation.com"
  }
}
