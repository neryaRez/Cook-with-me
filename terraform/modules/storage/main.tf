data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.env_name}"
  bucket_name = "${local.name_prefix}-images-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

resource "aws_s3_bucket" "images" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Name    = local.bucket_name
    Purpose = "future-recipe-image-uploads"
  }
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
