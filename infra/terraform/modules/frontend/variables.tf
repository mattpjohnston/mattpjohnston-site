variable "project_name" {
  description = "Logical project name used for resource naming"
  type        = string
}

variable "domain_name" {
  description = "Primary domain, e.g. mattpjohnston.com"
  type        = string
}

variable "validate_certificate" {
  description = "Create ACM certificate validation resource once DNS records are in place"
  type        = bool
  default     = false
}

variable "create_distribution" {
  description = "Create CloudFront distribution after ACM certificate validates"
  type        = bool
  default     = false
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
