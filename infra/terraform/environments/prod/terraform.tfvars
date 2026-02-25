aws_profile = "crc"
region      = "eu-west-1"
domain_name = "mattpjohnston.com"

validate_certificate = true
create_distribution  = true
price_class          = "PriceClass_100"

enable_backend = true
backend_allowed_origins = [
  "https://mattpjohnston.com",
  "https://www.mattpjohnston.com",
]
backend_seen_ttl_seconds             = 172800
backend_apigw_throttling_burst_limit = 10
backend_apigw_throttling_rate_limit  = 5
