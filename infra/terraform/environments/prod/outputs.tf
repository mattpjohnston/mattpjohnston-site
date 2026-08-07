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

output "github_actions_frontend_role_arn" {
  value = aws_iam_role.github_actions_frontend.arn
}

output "github_repository_variables" {
  value = {
    AWS_DEPLOY_ROLE_ARN          = aws_iam_role.github_actions_frontend.arn
    S3_BUCKET                    = module.frontend.bucket_name
    CLOUDFRONT_DISTRIBUTION_ID   = module.frontend.distribution_id
    PUBLIC_COUNTER_API_URL       = module.backend.counter_url
    BACKEND_LAMBDA_FUNCTION_NAME = module.backend.lambda_function_name
  }
}

output "backend_table_name" {
  value = module.backend.table_name
}

output "backend_lambda_function_name" {
  value = module.backend.lambda_function_name
}

output "backend_api_endpoint" {
  value = module.backend.api_endpoint
}

output "backend_counter_url" {
  value = module.backend.counter_url
}
