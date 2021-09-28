# --- root/website.tf ---
# ===========================================================
resource "aws_s3_bucket" "website_bucket" {
  bucket = "website-code-quote-app-1111"
  acl = "public-read"
  website {
    index_document = "index.html"
    error_document = "error.html"
   }
}

resource "aws_s3_bucket_object" "website_files" {
  for_each = fileset("${path.module}/WEBSITE", "**/*.*")
  bucket       = aws_s3_bucket.website_bucket.id
  key          = each.key
  acl          = "public-read"
  source       = "${path.module}/WEBSITE/${each.key}"
  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1))
  etag         = filemd5("${path.module}/WEBSITE/${each.key}")
}

