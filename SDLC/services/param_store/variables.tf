variable tags {
    type = map(string)
}

variable log_level {
    type = string
    default = "info"
}

variable log_file {
    type = string
    default = "application.log"
}

variable log_appender {
    type = string
    default = "console"
}

variable token_service_client_id {
    type = string
    default = "content_search"
}

variable create_shared_params {
    type = bool
    default = false
}