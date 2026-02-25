output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "certificate_arn" {
  value = aws_acm_certificate.site.arn
}

output "acm_validation_records" {
  value = [
    for dvo in aws_acm_certificate.site.domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ]
}

output "distribution_id" {
  value = try(aws_cloudfront_distribution.site[0].id, null)
}

output "distribution_domain_name" {
  value = try(aws_cloudfront_distribution.site[0].domain_name, null)
}

output "distribution_hosted_zone_id" {
  value = try(aws_cloudfront_distribution.site[0].hosted_zone_id, null)
}
