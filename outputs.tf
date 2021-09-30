# --- root/outputs.tf ---

output "website_s3_url" {
  description = "Website endpoint"
  value       = "http://${aws_s3_bucket.website_bucket.website_endpoint}"
}

output "quote_api_url" {
  description = "Base URL for API Gateway stage."
  value       = "${aws_apigatewayv2_stage.prodstage.invoke_url}/quote"
}