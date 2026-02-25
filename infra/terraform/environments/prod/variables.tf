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

variable "enable_frontend_ci_role" {
  type        = bool
  description = "Create GitHub Actions deploy role"
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
