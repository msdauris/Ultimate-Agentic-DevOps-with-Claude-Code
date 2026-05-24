# ---------------------------------------------------------------------------
# Local values
# ---------------------------------------------------------------------------
locals {
  bucket_name = "${var.project_name}-${var.environment}-site"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# S3 Bucket — private static site storage
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name

  tags = local.common_tags
}

# Block ALL public access — CloudFront reaches the bucket via OAC only
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disable ACLs — bucket owner enforced (required for OAC)
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Server-side encryption — SSE-S3 (AES256), AWS-managed keys
# AWS enables this by default on all new buckets; codified here so Terraform
# owns the configuration and drift is visible in future plans.
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

# ---------------------------------------------------------------------------
# CloudFront Origin Access Control (OAC)
# ---------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for ${var.project_name} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ---------------------------------------------------------------------------
# S3 Bucket Policy — allow CloudFront OAC to read objects
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json

  # The bucket policy references the distribution ARN, so the distribution
  # must be created first.
  depends_on = [aws_cloudfront_distribution.site]
}

# ---------------------------------------------------------------------------
# CloudFront Distribution
# ---------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  comment             = "${var.project_name} ${var.environment} static site"

  # --- Origin: private S3 bucket via OAC ---
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "S3-${local.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # --- Default cache behaviour ---
  default_cache_behavior {
    target_origin_id       = "S3-${local.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # AWS-managed CachingOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # --- Custom error responses ---
  # Return index.html with HTTP 200 for 404s (SPA / clean URLs)
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # --- Geo restriction: none ---
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # --- TLS: default CloudFront certificate ---
  # NOTE: minimum_protocol_version is only enforced by AWS when using a custom
  # SSL certificate (ACM/IAM). With cloudfront_default_certificate = true, AWS
  # ignores this field and always returns "TLSv1" regardless of what is set.
  # To enforce TLSv1.2_2021, attach a custom domain + ACM certificate.
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}
