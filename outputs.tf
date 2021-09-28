# --- root/outputs.tf ---

output "lambda_bucket_name" {
  value = aws_s3_bucket.lambda_bucket.id
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.myfunc.function_name
}

output "base_api_url" {
  description = "Base URL for API Gateway stage."
  value       = aws_apigatewayv2_stage.prodstage.invoke_url
}

output "website_s3_url" {
  description = "Website endpoint"
  value       = aws_s3_bucket.website_bucket.website_endpoint
}