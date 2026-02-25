module "frontend" {
  source = "../../modules/frontend"

  providers = {
    aws      = aws
    aws.use1 = aws.use1
  }

  project_name         = var.project_name
  domain_name          = var.domain_name
  validate_certificate = var.validate_certificate
  create_distribution  = var.create_distribution
  price_class          = var.price_class
  tags                 = var.tags
}

module "backend" {
  count  = var.enable_backend ? 1 : 0
  source = "../../modules/backend"

  project_name                 = var.project_name
  domain_name                  = var.domain_name
  lambda_source_dir            = "${path.root}/../../../../apps/api/lambda/src"
  allowed_origins              = var.backend_allowed_origins
  seen_ttl_seconds             = var.backend_seen_ttl_seconds
  apigw_throttling_burst_limit = var.backend_apigw_throttling_burst_limit
  apigw_throttling_rate_limit  = var.backend_apigw_throttling_rate_limit
  tags                         = var.tags
}
