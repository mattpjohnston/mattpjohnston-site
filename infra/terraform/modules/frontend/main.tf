terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.use1]
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  root_domain = lower(var.domain_name)
  www_domain  = "www.${local.root_domain}"
  bucket_name = "${replace(local.root_domain, ".", "-")}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_acm_certificate" "site" {
  provider                  = aws.use1
  domain_name               = local.root_domain
  subject_alternative_names = [local.www_domain]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_acm_certificate_validation" "site" {
  count    = var.validate_certificate ? 1 : 0
  provider = aws.use1

  certificate_arn = aws_acm_certificate.site.arn
  validation_record_fqdns = [
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.resource_record_name
  ]
}

resource "aws_cloudfront_origin_access_control" "site" {
  count = var.create_distribution ? 1 : 0

  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "rewrite" {
  count   = var.create_distribution ? 1 : 0
  name    = "${var.project_name}-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/cloudfront-function.js")
}

resource "aws_cloudfront_distribution" "site" {
  count      = var.create_distribution ? 1 : 0
  depends_on = [aws_acm_certificate_validation.site]

  enabled             = true
  is_ipv6_enabled     = true
  aliases             = [local.root_domain, local.www_domain]
  default_root_object = "index.html"
  price_class         = var.price_class

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-site-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.site[0].id
  }

  default_cache_behavior {
    target_origin_id       = "s3-site-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite[0].arn
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  lifecycle {
    precondition {
      condition     = var.validate_certificate
      error_message = "Set validate_certificate=true before create_distribution=true."
    }
  }

  tags = var.tags
}

data "aws_iam_policy_document" "site_bucket_policy" {
  count = var.create_distribution ? 1 : 0

  statement {
    sid = "AllowCloudFrontReadOnly"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.site.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  count  = var.create_distribution ? 1 : 0
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_bucket_policy[0].json
}
