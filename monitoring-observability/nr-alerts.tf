module "aws_resource_tags" {
  source             = "git::ssh://git@github.mheducation.com/terraform/aws-resource-tags?ref=2.1.0"
  account            = var.aws_account
  application        = var.application
  environment        = terraform.workspace
  function           = ""
  platform           = var.platform
  propagate_asg_tags = false
}

module "cinch_nri_alerts" {

  source = "git::ssh://git@github.mheducation.com/monitoring-as-code/newrelic-alerts-rackspace-monitorkit.git?ref=02b9aea72baf51d7654fcc407cc9de75e2476f42"

  maintainer                            = "MH" # Who owns/maintains these alerts?
  prepend_policy_name_to_condition_name = false

  custom_alert_definitions = [
    {
      extends                        = "" # MUST be defined, even if empty
      id                             = "cond_rds_avg_cpu_used"
      name                           = "RDS CPU Used (%)"
      create                         = true
      enabled                        = var.NR_ALERT_COND_FLAG
      description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND." # Use this field to overwrite default description. If the field isn't provided, mac will add default description
      nrql_query                     = "FROM DatastoreSample SELECT average(provider.cpuUtilization.Average) AS 'CPU %% Used' WHERE (provider = 'RdsDbInstance' OR provider = 'RdsDbCluster') AND (provider.engine like '%%oracle-ee%%') AND label.Platform='${var.platform}' FACET displayName%s"
      append_to_where                = ""
      eval_offset                    = 15
      operator                       = "above"
      crit                           = 90
      warn                           = 80
      in_state_before_trigger        = "all"
      over_minutes                   = 5
      value_function                 = "single_value"
      autoclose_after                = 3600
      expiration_duration_seconds    = 900
      open_violation_on_expiration   = false
      close_violations_on_expiration = false
      fill_option                    = "last_value"
      fill_value                     = 0

      runbook_url = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
    },

    {
      extends                        = "" # MUST be defined, even if empty
      id                             = "cond_rds_max_conns_used"
      name                           = "RDS Max Connections Used (%)"
      create                         = true
      enabled                        = var.NR_ALERT_COND_FLAG
      description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND." # Use this field to overwrite default description. If the field isn't provided, mac will add default description
      nrql_query                     = "FROM DatastoreSample SELECT 100*(latest(provider.databaseConnections.Maximum)/1365) AS 'Max Conns %% Used' WHERE (provider = 'RdsDbCluster' OR provider = 'RdsDbInstance') AND (provider.engine like '%%oracle-ee%%') AND label.Platform='${var.platform}' FACET displayName%s"
      append_to_where                = ""
      eval_offset                    = 15
      operator                       = "above"
      crit                           = 80
      warn                           = 70
      in_state_before_trigger        = "at_least_once"
      over_minutes                   = 5
      value_function                 = "single_value"
      autoclose_after                = 3600
      expiration_duration_seconds    = 900
      open_violation_on_expiration   = false
      close_violations_on_expiration = false
      fill_option                    = "last_value"
      fill_value                     = 0
      runbook_url                    = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"

    },
    {
      extends                        = ""
      id                             = "cond_ecs_tasks_running"
      name                           = "ECS Tasks Running"
      create                         = true
      enabled                        = var.NR_ALERT_COND_FLAG
      nrql_query                     = "FROM ComputeSample SELECT average(`provider.runningTasksCount`) WHERE provider='EcsCluster' AND label.Account = '${var.aws_account}' AND label.Application = '${var.application}' FACET displayName%s"
      eval_offset                    = 15
      append_to_where                = ""
      description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND."
      operator                       = "below"
      crit                           = 2
      warn                           = 2
      in_state_before_trigger        = "all"
      over_minutes                   = 2
      value_function                 = "single_value"
      autoclose_after                = 3600
      expiration_duration_seconds    = 900
      open_violation_on_expiration   = false
      close_violations_on_expiration = false
      fill_option                    = "last_value"
      fill_value                     = 0

      runbook_url = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
    },
    # {
    #   extends                        = ""
    #   id                             = "cond_target_4xx_errors"
    #   name                           = "ALB Target 4XX Errors"
    #   create                         = true
    #   enabled                        = var.NR_ALERT_COND_FLAG
    #   nrql_query                     = "SELECT sum(`aws.applicationelb.HTTPCode_Target_4XX_Count`) FROM Metric FACET `tags.Application` WHERE `tags.Application` = '${var.application}'%s"
    #   eval_offset                    = 15
    #   append_to_where                = ""
    #   description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND."
    #   operator                       = "above"
    #   crit                           = 10
    #   warn                           = 5
    #   in_state_before_trigger        = "all"
    #   over_minutes                   = 5
    #   value_function                 = "single_value"
    #   autoclose_after                = 43200
    #   expiration_duration_seconds    = 900
    #   open_violation_on_expiration   = false
    #   close_violations_on_expiration = false
    #   fill_option                    = "none"
    #   fill_value                     = 0
    #   runbook_url                    = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
    # },
    {
      extends                        = ""
      id                             = "cond_synthetic_ping01"
      name                           = "Cinch Prod Ping Check (>2 fails in 5mins)"
      create                         = true
      enabled                        = var.NR_ALERT_COND_FLAG
      description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND."
      nrql_query                     = "SELECT count(*) FROM SyntheticCheck where monitorName = 'URL-www.cinchlearning.com_SS2NR' where result!='SUCCESS' %s"
      append_to_where                = ""
      value_function                 = "sum"
      operator                       = "above"
      crit                           = 2.0
      warn                           = 2.0
      in_state_before_trigger        = "at_least_once"
      over_minutes                   = 5
      runbook_url                    = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
      expiration_duration_seconds    = 300
      open_violation_on_expiration   = false
      close_violations_on_expiration = false
      autoclose_after                = 7200
      autoclose_after_seconds        = 7200
      aggregation_window             = 60
      eval_offset                    = 15
      fill_option                    = "static"
      fill_value                     = 0
    },

    {
      extends                        = ""
      id                             = "cond_synthetic_ping02"
      name                           = "Cinch Prod efs static content Ping Check (>2 fails in 5mins)"
      create                         = true
      enabled                        = var.NR_ALERT_COND_FLAG
      description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND."
      nrql_query                     = "SELECT count(*) FROM SyntheticCheck where monitorName = 'URL-cinch-efs-static-resource-ping-prod' where result!='SUCCESS' %s"
      append_to_where                = ""
      value_function                 = "sum"
      operator                       = "above"
      crit                           = 2.0
      warn                           = 2.0
      in_state_before_trigger        = "at_least_once"
      over_minutes                   = 5
      runbook_url                    = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
      expiration_duration_seconds    = 300
      open_violation_on_expiration   = false
      close_violations_on_expiration = false
      autoclose_after                = 7200
      autoclose_after_seconds        = 7200
      aggregation_window             = 60
      eval_offset                    = 15
      fill_option                    = "static"
      fill_value                     = 0
    },

    {
      extends                        = ""
      id                             = "cond_synthetic_ping03"
      name                           = "Cinch Prod tx science domain Ping Check (>2 fails in 5mins)"
      create                         = true
      enabled                        = var.NR_ALERT_COND_FLAG
      description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND."
      nrql_query                     = "SELECT count(*) FROM SyntheticCheck where monitorName = 'URL-tx-science.cinchlearning.com_SS2NR' where result!='SUCCESS' %s"
      append_to_where                = ""
      value_function                 = "sum"
      operator                       = "above"
      crit                           = 2.0
      warn                           = 2.0
      in_state_before_trigger        = "at_least_once"
      over_minutes                   = 5
      runbook_url                    = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
      expiration_duration_seconds    = 300
      open_violation_on_expiration   = false
      close_violations_on_expiration = false
      autoclose_after                = 7200
      autoclose_after_seconds        = 7200
      aggregation_window             = 60
      eval_offset                    = 15
      fill_option                    = "static"
      fill_value                     = 0
    },

    {
      extends                        = ""
      id                             = "cond_synthetic_scripted01"
      name                           = "Cinch Prod standalone scripted monitor sheck (>4 fails in 10mins)"
      create                         = true
      enabled                        = var.NR_ALERT_COND_FLAG
      description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND."
      nrql_query                     = "SELECT count(*) FROM SyntheticCheck where monitorName = 'BP72-cinch-standalone-test-prod' where result!='SUCCESS' %s"
      append_to_where                = ""
      value_function                 = "sum"
      operator                       = "above"
      crit                           = 1.0
      warn                           = 1.0
      in_state_before_trigger        = "at_least_once"
      over_minutes                   = 15
      runbook_url                    = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
      expiration_duration_seconds    = 300
      open_violation_on_expiration   = false
      close_violations_on_expiration = false
      autoclose_after                = 7200
      autoclose_after_seconds        = 7200
      aggregation_window             = 60
      eval_offset                    = 15
      fill_option                    = "static"
      fill_value                     = 0
    },
    {
      extends                        = ""
      id                             = "cond_synthetic_scripted02"
      name                           = "Cinch Prod CED integration scripted monitor sheck (>4 fails in 10mins)"
      create                         = true
      enabled                        = var.NR_ALERT_COND_FLAG
      description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND."
      nrql_query                     = "SELECT count(*) FROM SyntheticCheck where monitorName = 'BP73-ced-cinch-test-prod' where result!='SUCCESS' %s"
      append_to_where                = ""
      value_function                 = "sum"
      operator                       = "above"
      crit                           = 1.0
      warn                           = 1.0
      in_state_before_trigger        = "at_least_once"
      over_minutes                   = 15
      runbook_url                    = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
      expiration_duration_seconds    = 300
      open_violation_on_expiration   = false
      close_violations_on_expiration = false
      autoclose_after                = 7200
      autoclose_after_seconds        = 7200
      aggregation_window             = 60
      eval_offset                    = 15
      fill_option                    = "static"
      fill_value                     = 0
    },

    {
      extends                        = ""
      id                             = "cond_Responsetimes"
      name                           = "Cinch - Response time (web) > 5s for 10m"
      create                         = true
      enabled                        = var.NR_ALERT_COND_FLAG
      description                    = "From newrelic-alerts-monitorkit module. DO NOT EDIT BY HAND."
      nrql_query                     = "SELECT latest(duration) FROM Transaction WHERE appName='cinch-cinchlearning-prod' %s"
      append_to_where                = ""
      value_function                 = "single_value"
      operator                       = "above"
      crit                           = 5
      warn                           = 5
      in_state_before_trigger        = "all"
      over_minutes                   = 10
      runbook_url                    = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
      expiration_duration_seconds    = 300
      open_violation_on_expiration   = false
      close_violations_on_expiration = false
      autoclose_after                = 7200
      autoclose_after_seconds        = 7200
      aggregation_window             = 60
      eval_offset                    = 15
      fill_option                    = "static"
      fill_value                     = 0
    }

  ]


  cond_ec2_inst_disk_usage = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    crit                    = 85
    over_minutes            = 10
    in_state_before_trigger = "all"
    append_to_where         = "label.Application = '${var.application}'"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }

  cond_ec2_inst_mem = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    crit                    = 80
    over_minutes            = 10
    in_state_before_trigger = "all"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }
  cond_ec2_inst_cpu = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    crit                    = 90
    over_minutes            = 10
    in_state_before_trigger = "all"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }

  cond_ecs_cluster_cpu_utilization = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    in_state_before_trigger = "all"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }
  cond_ecs_cluster_cpu_reservation = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    in_state_before_trigger = "all"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }
  cond_ecs_cluster_mem_utilization = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    in_state_before_trigger = "all"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }
  cond_ecs_cluster_mem_reservation = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    in_state_before_trigger = "all"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }
  cond_ecs_tasks_pending = {
    create                      = true
    enabled                     = var.NR_ALERT_COND_FLAG
    crit                        = 0
    over_minutes                = 10
    expiration_duration_seconds = 900
    in_state_before_trigger     = "all"
    runbook_url                 = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }

  #ECS Service Alerts
  cond_ecs_service_cpu_utilization = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    in_state_before_trigger = "all"
    append_to_where         = "label.Platform = '${var.platform}'"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }
  cond_ecs_service_mem_utilization = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    in_state_before_trigger = "all"
    append_to_where         = "label.Platform = '${var.platform}'"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }

  #
  #ALB Alerts
  #

  # On 09/28, there were 2 minutes of just above 10 errors per minutes without no visible customer impact.
  cond_alb_balancer_5xx_errors = {
    create                  = true
    enabled                 = var.NR_ALERT_COND_FLAG
    crit                    = 15
    in_state_before_trigger = "all"
    over_minutes            = 2
    eval_offset             = 15
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }

  cond_alb_target_5xx_errors = {
    "create"                = true
    enabled                 = var.NR_ALERT_COND_FLAG
    in_state_before_trigger = "all"
    runbook_url             = "https://confluence.mheducation.com/display/EPS/Cinch+Runbook"
  }

  extra_notification_channels = ["4840300", "5202250", "5194047", "5234873"]
  tags                        = module.aws_resource_tags.common_tags
}
