# --- root/main.tf ---
# ===========================================================
# PROVIDERS
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
# --- locals ---
locals {
  mime_types = {
    "css"  = "text/css"
    "html" = "text/html"
    "ico"  = "image/vnd.microsoft.icon"
    "js"   = "application/javascript"
    "json" = "application/json"
    "map"  = "application/json"
    "png"  = "image/png"
    "svg"  = "image/svg+xml"
    "txt"  = "text/plain"
  }
}
# ===========================================================
# LAMBDA CODE AND S3 BUCKET
# --- lambda s3 bucket ---

resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = "codebucket-quote-app-1111"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "QuoteAppCode"
  }
}
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
# LAMBDA FUNCTION
# --- lambda function ---
resource "aws_lambda_function" "myfunc" {
  function_name    = "MyFunc"
  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_bucket_object.lambda_code_file.key
  runtime          = "python3.8"
  handler          = "lambda_function.lambda_handler"
  timeout          = 300
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
# --- cloud watch policy for the lambda execution role---
data "aws_iam_policy_document" "lambda_cw_policy_doc" {
  statement {
    sid = "1"
    effect ="Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "lambda_cw_policy" {
  name   = "lambda_cw_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_cw_policy_doc.json
}

# --- dynamo db policy for the lambda execution role ---
data "aws_iam_policy_document" "ddb_policy_doc" {
  statement {
    sid = "2"
    effect ="Allow"
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:DescribeTable",
    ]

    resources = [
      "${aws_dynamodb_table.ddb_table.arn}",
    ]
  }
}

resource "aws_iam_policy" "ddb_policy" {
  name   = "ddb_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ddb_policy_doc.json
}

# --- attach policies to execution role ---
resource "aws_iam_role_policy_attachment" "lambda_cw_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_cw_policy.arn
}
resource "aws_iam_role_policy_attachment" "lambda_ddb_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.ddb_policy.arn
}
# ===========================================================
# API GATEWAY
# --- api gateway ---
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_headers     = ["*"]
    allow_methods     = ["POST","GET"]
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
# ===========================================================
# S3 WEBSITE
# --- s3 static site ---
resource "aws_s3_bucket" "website_bucket" {
  bucket = "website-code-quote-app-1111"
  acl = "public-read"
  website {
    index_document = "index.html"
    error_document = "error.html"
   }
}
# --- upload files to s3 site ---
resource "aws_s3_bucket_object" "website_files" {
  for_each = fileset("${path.module}/WEBSITE", "**/*.*")
  bucket       = aws_s3_bucket.website_bucket.id
  key          = each.key
  acl          = "public-read"
  source       = "${path.module}/WEBSITE/${each.key}"
  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1))
  etag         = filemd5("${path.module}/WEBSITE/${each.key}")
}
# ===========================================================
# DYNAMO DB TABLE
# --- database ---
resource "aws_dynamodb_table" "ddb_table" {
  name        = "MyTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "quotetype"
  attribute {
    name = "id"
    type = "N"
  }
  attribute {
    name = "quotetype"
    type = "S"
  }

  provisioner "local-exec" {
    command = "bash DATABASE/populate_db.sh"
  }
}