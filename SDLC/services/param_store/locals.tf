locals {
  environment = var.tags["Environment"]
  application = var.tags["Application"]
  function = var.tags["Function"]
  account_type = local.environment == "prod" ? "prod" : "nonprod"
  count = var.create_shared_params ? 1 : 0
  
  function_filtered_tags = { for k, v in var.tags: k => v if k != "Function" }
  tass_host = {
  dev = "https://token-dev.mheducation.com"
  demo = "https://token-demo.mheducation.com"
  pqa = "https://token-pqa.mheducation.com"
  qastg = "https://token-qastg.mheducation.com"
  qalv = "https://token-qalv.mheducation.com"
  prod = "https://token.mheducation.com"
  }

}