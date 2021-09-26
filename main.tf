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
# --- lambda function ---
resource "aws_lambda_function" "myfunc" {
  function_name    = "MyFunc"
  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_bucket_object.lambda_code_file.key
  runtime          = "nodejs12.x"
  handler          = "hello.handler"
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