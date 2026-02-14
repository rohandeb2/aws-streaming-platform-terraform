# --- S3 Media Storage ---
resource "aws_s3_bucket" "media" {
  bucket        = "${var.media_bucket_name}-${var.environment}"
  force_destroy = var.environment == "prod" ? false : true
  tags          = var.common_tags
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    id     = "archive-old-content"
    status = "Enabled"
    filter {}
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# --- CloudFront OAC ---
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "oac-${var.environment}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- CloudFront Distribution ---
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.environment} streaming platform"
  price_class         = "PriceClass_All" # Best for global streaming

  # Origin 1: S3 Media
  origin {
    domain_name              = aws_s3_bucket.media.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = "S3-Media"
  }

  # Origin 2: ALB API
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-Backend"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default Behavior (S3 Media)
  default_cache_behavior {
    target_origin_id       = "S3-Media"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  # API Behavior (Route /api/* to ALB)
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "ALB-Backend"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "https-only"
    
    forwarded_values {
      query_string = true
      headers      = ["*"] # Forward all headers to backend API
      cookies { forward = "all" }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
  viewer_certificate { cloudfront_default_certificate = true }
}

# --- Bucket Policy for OAC ---
resource "aws_s3_bucket_policy" "oac_access" {
  bucket = aws_s3_bucket.media.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipal",
      Effect    = "Allow",
      Principal = { Service = "cloudfront.amazonaws.com" },
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.media.arn}/*",
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.main.arn }
      }
    }]
  })
}

# --- Route53 ---
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "cdn_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
