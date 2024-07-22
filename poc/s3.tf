# Lambda Layer
resource "aws_s3_bucket" "lambda_layers" {
  bucket = "${var.env}-${var.project}-lambda-layer"
}

resource "aws_s3_bucket_public_access_block" "lambda_layers" {
  bucket                  = aws_s3_bucket.lambda_layers.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_layers" {
  bucket = aws_s3_bucket.lambda_layers.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# Lambda functions
resource "aws_s3_bucket" "lambda_functions" {
  bucket = "${var.env}-${var.project}-lambda-functions"
}

resource "aws_s3_bucket_public_access_block" "lambda_functions" {
  bucket                  = aws_s3_bucket.lambda_functions.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_functions" {
  bucket = aws_s3_bucket.lambda_functions.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
