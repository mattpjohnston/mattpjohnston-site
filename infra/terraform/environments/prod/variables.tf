variable "aws_profile" {
  type        = string
  description = "Named AWS CLI profile"
  default     = "crc"
}

variable "region" {
  type        = string
  description = "Primary AWS region for non-CloudFront resources"
  default     = "eu-west-1"
}

variable "domain_name" {
  type        = string
  description = "Primary domain"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "mattpjohnston-site"
}

variable "validate_certificate" {
  type        = bool
  description = "Enable ACM DNS validation resource"
  default     = false
}

variable "create_distribution" {
  type        = bool
  description = "Enable CloudFront distribution"
  default     = false
}

variable "price_class" {
  type        = string
  description = "CloudFront price class"
  default     = "PriceClass_100"
}

variable "enable_backend" {
  type        = bool
  description = "Enable visitor counter backend resources"
  default     = false
}

variable "backend_allowed_origins" {
  type        = list(string)
  description = "Allowed CORS origins for counter API"
  default     = []
}

variable "backend_seen_ttl_seconds" {
  type        = number
  description = "TTL in seconds for daily seen fingerprints"
  default     = 172800
}

variable "backend_apigw_throttling_burst_limit" {
  type        = number
  description = "API Gateway burst limit for counter endpoint"
  default     = 10
}

variable "backend_apigw_throttling_rate_limit" {
  type        = number
  description = "API Gateway steady-state rate limit for counter endpoint"
  default     = 5
}

variable "enable_frontend_ci_role" {
  type        = bool
  description = "Create GitHub Actions deploy role for frontend and backend workflows"
  default     = true
}

variable "create_github_oidc_provider" {
  type        = bool
  description = "Create GitHub OIDC provider in IAM"
  default     = true
}

variable "github_oidc_provider_arn" {
  type        = string
  description = "Existing GitHub OIDC provider ARN"
  default     = null

  validation {
    condition     = var.create_github_oidc_provider || var.github_oidc_provider_arn != null
    error_message = "Set github_oidc_provider_arn when create_github_oidc_provider is false."
  }
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user"
  default     = "mattpjohnston"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
  default     = "mattpjohnston-site"
}

variable "github_branch" {
  type        = string
  description = "GitHub branch allowed to deploy"
  default     = "main"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default = {
    ManagedBy   = "Terraform"
    Project     = "cloud-resume"
    Environment = "prod"
  }
}
