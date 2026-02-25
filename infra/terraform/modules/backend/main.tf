terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  root_domain = lower(var.domain_name)
  default_origins = [
    "https://${local.root_domain}",
    "https://www.${local.root_domain}",
    "http://localhost:4321",
  ]
  cors_origins       = length(var.allowed_origins) > 0 ? var.allowed_origins : local.default_origins
  lambda_output_path = "${path.root}/.terraform/backend-lambda.zip"
}

resource "random_password" "counter_ip_salt" {
  length  = 32
  special = false
}

resource "aws_dynamodb_table" "counter" {
  name         = "${var.project_name}-visitor-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = var.tags
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = local.lambda_output_path
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-counter-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
    ]

    resources = [
      aws_dynamodb_table.counter.arn,
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamodb" {
  name   = "${var.project_name}-counter-lambda-dynamodb"
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

resource "aws_lambda_function" "counter" {
  function_name = "${var.project_name}-visitor-counter"
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  handler       = "app.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  environment {
    variables = {
      TABLE_NAME       = aws_dynamodb_table.counter.name
      COUNTER_PK       = var.counter_pk
      COUNTER_IP_SALT  = random_password.counter_ip_salt.result
      SEEN_TTL_SECONDS = tostring(var.seen_ttl_seconds)
    }
  }

  tags = var.tags
}

resource "aws_apigatewayv2_api" "counter" {
  name          = "${var.project_name}-counter-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type"]
    allow_methods = ["GET", "OPTIONS"]
    allow_origins = local.cors_origins
    max_age       = 300
  }

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "counter" {
  api_id                 = aws_apigatewayv2_api.counter.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "counter" {
  api_id    = aws_apigatewayv2_api.counter.id
  route_key = "GET /counter"
  target    = "integrations/${aws_apigatewayv2_integration.counter.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.counter.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = var.apigw_throttling_burst_limit
    throttling_rate_limit  = var.apigw_throttling_rate_limit
  }

  tags = var.tags
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.counter.execution_arn}/*/*"
}
