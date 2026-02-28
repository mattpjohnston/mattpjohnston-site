variable "project_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "lambda_source_dir" {
  type = string
}

variable "allowed_origins" {
  type    = list(string)
  default = []
}

variable "counter_pk" {
  type    = string
  default = "site"
}

variable "seen_ttl_seconds" {
  type    = number
  default = 172800
}

variable "apigw_throttling_burst_limit" {
  type    = number
  default = 10
}

variable "apigw_throttling_rate_limit" {
  type    = number
  default = 5
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "lambda_timeout" {
  type    = number
  default = 5
}

variable "lambda_memory_size" {
  type    = number
  default = 512
}

variable "tags" {
  type    = map(string)
  default = {}
}
