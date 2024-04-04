variable "task_min_count_config_map" {
  default = {
    dev   = 2
    qastg = 2
    pqa   = 3
    qalv  = 2
    demo  = 2
    prod  = 3
  }
  description = "Minimum number of tasks to keep running when scaling in"
  type        = map(number)
}

variable "task_max_count_config_map" {
  default = {
    dev   = 5
    qastg = 5
    pqa   = 20
    qalv  = 5
    demo  = 5
    prod  = 20
  }
  description = "Maximum number of tasks to run when scaling out"
  type        = map(number)
}

variable "task_cpu_target_percent_config_map" {
  default = {
    dev   = 70
    qastg = 70
    pqa   = 70
    qalv  = 70
    demo  = 70
    prod  = 70
  }
  description = "CPU threshold used for auto-scaling in percent CPU available to the task"
  type        = map(number)
}

variable "task_memory_target_percent_config_map" {
  default = {
    dev   = 70
    qastg = 70
    pqa   = 70
    qalv  = 70
    demo  = 70
    prod  = 70
  }
  description = "Memory threshold used for auto-scaling in percent memory available to the task"
  type        = map(number)
}

variable "task_healthcheck_timeout_in_seconds_config_map" {
  default = {
    dev   = 10
    qastg = 10
    qalv  = 10
    demo  = 10
    prod  = 300
  }
  description = "Number of seconds the load balancer will wait for the task to become healthy"
  type        = map(number)
}

variable "deregistration_delay_seconds_config_map" {
  description = "Number of seconds to wait before changing the state of a deregistering target from _draining_ to _unused_. Range is `0`–`3600` seconds."
  default = {
    dev   = 5
    qastg = 5
    qalv  = 5
    demo  = 5
    prod  = 60
  }
  type = map(number)
}

variable "start_delay_seconds_config_map" {
  description = "Number of seconds for targets to warm-up before sending them a full share of requests. Range is `30`–`900` seconds or `0` to disable."
  default = {
    dev   = 30
    qastg = 30
    pqa   = 30
    qalv  = 30
    demo  = 30
    prod  = 30
  }
  type = map(number)
}
