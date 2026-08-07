output "table_name" {
  value = aws_dynamodb_table.counter.name
}

output "lambda_function_name" {
  value = aws_lambda_function.counter.function_name
}

output "api_id" {
  value = aws_apigatewayv2_api.counter.id
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.counter.api_endpoint
}

output "counter_url" {
  value = "${aws_apigatewayv2_api.counter.api_endpoint}/counter"
}
