output "bucket_name" {
  value = module.frontend.bucket_name
}

output "certificate_arn" {
  value = module.frontend.certificate_arn
}

output "acm_validation_records" {
  value = module.frontend.acm_validation_records
}

output "distribution_id" {
  value = module.frontend.distribution_id
}

output "distribution_domain_name" {
  value = module.frontend.distribution_domain_name
}

output "distribution_hosted_zone_id" {
  value = module.frontend.distribution_hosted_zone_id
}

output "github_actions_frontend_role_arn" {
  value = try(aws_iam_role.github_actions_frontend[0].arn, null)
}

output "github_repository_variables" {
  value = {
    AWS_DEPLOY_ROLE_ARN          = try(aws_iam_role.github_actions_frontend[0].arn, null)
    S3_BUCKET                    = module.frontend.bucket_name
    CLOUDFRONT_DISTRIBUTION_ID   = module.frontend.distribution_id
    PUBLIC_COUNTER_API_URL       = try(module.backend[0].counter_url, null)
    BACKEND_LAMBDA_FUNCTION_NAME = try(module.backend[0].lambda_function_name, null)
  }
}

output "backend_table_name" {
  value = try(module.backend[0].table_name, null)
}

output "backend_lambda_function_name" {
  value = try(module.backend[0].lambda_function_name, null)
}

output "backend_api_endpoint" {
  value = try(module.backend[0].api_endpoint, null)
}

output "backend_counter_url" {
  value = try(module.backend[0].counter_url, null)
}
