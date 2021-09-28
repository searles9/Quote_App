# --- root/main.tf ---
# ===========================================================
#---providers---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.26.0"
    }
  }
  required_version = ">= 0.14"

  backend "remote" {
    organization = "dps-terraform"

    workspaces {
      name = "quote-app"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
# ===========================================================
# --- lambda s3 bucket ---

resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = "codebucket-quote-app-1111"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "QuoteAppCode"
  }
}
# ===========================================================
#--- zip code ---
data "archive_file" "lambda_code_file" {
  type        = "zip"
  source_dir  = "${path.module}/CODE"
  output_path = "${path.module}/CODE.zip"
}

# --- upload code to s3 ----
resource "aws_s3_bucket_object" "lambda_code_file" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "CODE.zip"
  source = data.archive_file.lambda_code_file.output_path
  etag   = filemd5(data.archive_file.lambda_code_file.output_path)
}
# ===========================================================
# python3.8
# --- lambda function ---
resource "aws_lambda_function" "myfunc" {
  function_name    = "MyFunc"
  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_bucket_object.lambda_code_file.key
  runtime          = "python3.8"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_code_file.output_base64sha256
  role             = aws_iam_role.lambda_exec_role.arn
}
# --- cloudwatch log group ---
resource "aws_cloudwatch_log_group" "myfunc" {
  name              = "/aws/lambda/${aws_lambda_function.myfunc.function_name}"
  retention_in_days = 30
}
# --- lambda execution role ---
resource "aws_iam_role" "lambda_exec_role" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}
# --- attach policy to execution role ---
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# ===========================================================
# --- api gateway ---
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    max_age           = 3600
  }
}
# ---api gateway stage ---
resource "aws_apigatewayv2_stage" "prodstage" {
  api_id = aws_apigatewayv2_api.lambda_api.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}
# --- api gateway lambda integration ---
resource "aws_apigatewayv2_integration" "myfunc_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id

  integration_uri    = aws_lambda_function.myfunc.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda_api_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id

  route_key = "GET /quote"
  target    = "integrations/${aws_apigatewayv2_integration.myfunc_integration.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda_api.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.myfunc.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}
