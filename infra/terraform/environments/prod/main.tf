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
