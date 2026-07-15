# KMS key -  dedicated CMK for S3 bucket encryption

resource "aws_kms_key" "s3" {
  description             = "CMK for ${var.name_prefix} S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-kms"
  })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.name_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# Creating unique names for the buckets globally
locals {
  buckets = {
    product_images = "${var.name_prefix}-product-images-${var.account_id}"
    invoices       = "${var.name_prefix}-invoices-${var.account_id}"
    logs           = "${var.name_prefix}-logs-${var.account_id}"
  }
}

# Product_images bucket 

resource "aws_s3_bucket" "product_images" {
  bucket        = local.buckets.product_images
  force_destroy = var.force_destroy
  tags = merge(var.tags, {
    Name = local.buckets.product_images
  })
}

resource "aws_s3_bucket_versioning" "product_images" {
  bucket = aws_s3_bucket.product_images.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "product_images" {
  bucket = aws_s3_bucket.product_images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
    # reduce KMS API costs by reducing the operational calls to KMS API by every bucket object. 
    # by enabling the s3 bucket key, s3 caches a bucket-level key which drastically reduce the KMS calls and 99% KMS costs. 
  }

}

resource "aws_s3_bucket_lifecycle_configuration" "product_images" {
  bucket = aws_s3_bucket.product_images.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {

    }
    noncurrent_version_expiration {
      noncurrent_days = 30 # delete old versions after 30 days
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7 # cleanup failed uploads
    }
  }
}

resource "aws_s3_bucket_public_access_block" "product_images" {
  bucket                  = aws_s3_bucket.product_images.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket2 - INVOICES - Financial records, aging to glacier

resource "aws_s3_bucket" "invoices" {
  bucket        = local.buckets.invoices
  force_destroy = var.force_destroy
  tags = merge(var.tags, {
    Name = "local.buckets.invoices"
  })
}

resource "aws_s3_bucket_versioning" "invoices" {
  bucket = aws_s3_bucket.invoices.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "invoices" {
  bucket                  = aws_s3_bucket.invoices.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "invoices" {
  bucket = aws_s3_bucket.invoices.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "invoices" {
  bucket = aws_s3_bucket.invoices.id
  rule {
    id     = "invoice-retention"
    status = "Enabled"

    filter {

    }
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
    expiration {
      days = 2555 # 7 Years(financial retention)
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# HTTPS- Only bucket policy (deny unencrypted transport)

resource "aws_s3_bucket_policy" "invoices" {
  bucket = aws_s3_bucket.invoices.id
  policy = data.aws_iam_policy_document.invoices_https_only.json
}

data "aws_iam_policy_document" "invoices_https_only" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.invoices.arn,
      "${aws_s3_bucket.invoices.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Bucket3 LOGS - (Standard→IA→Deep Archive→delete)

resource "aws_s3_bucket" "logs" {
  bucket        = local.buckets.logs
  force_destroy = var.force_destroy
  tags = merge(var.tags, {
    Name = local.buckets.logs
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Standard (0-30d) → Standard-IA (30d) → Glacier Deep Archive (1yr) → delete (7yr)
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "log-retention"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555 # 7 years
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_https_only.json
}

data "aws_iam_policy_document" "logs_https_only" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

