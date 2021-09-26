# --- root/outputs.tf ---

output "lambda_bucket_name" {
  value = aws_s3_bucket.lambda_bucket.id
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.hello_world.function_name
}