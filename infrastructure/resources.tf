# Big thanks to Alex Hyett for his post on setting this up!
# https://www.alexhyett.com/terraform-s3-static-website-hosting

locals {
  domain_name = "chedygov.com"
}

# www bucket

resource "aws_s3_bucket" "www" {
  bucket = "www.${local.domain_name}"
}

resource "aws_s3_bucket_website_configuration" "www" {
  bucket = aws_s3_bucket.www.bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_acl" "www" {
  bucket = aws_s3_bucket.www.bucket
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "www_public_access" {
  bucket = aws_s3_bucket.www.bucket
  policy = templatefile("templates/s3-policy.json", { bucket = "www.${local.domain_name}" })
}

# Root bucket

resource "aws_s3_bucket" "root" {
  bucket = local.domain_name
}

resource "aws_s3_bucket_website_configuration" "root" {
  bucket = aws_s3_bucket.root.bucket
  redirect_all_requests_to {
    host_name = "www.${local.domain_name}"
    protocol = "https"
  }
}

resource "aws_s3_bucket_acl" "root" {
  bucket = aws_s3_bucket.root.bucket
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "root_public_access" {
  bucket = aws_s3_bucket.root.bucket
  policy = templatefile("templates/s3-policy.json", { bucket = local.domain_name })
}

# SSL cert

resource "aws_acm_certificate" "ssl_cert" {
  provider = aws.acm_provider
  domain_name = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method = "EMAIL"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider = aws.acm_provider
  certificate_arn = aws_acm_certificate.ssl_cert.arn
}

# CloudFront distributions

data "aws_cloudfront_cache_policy" "default_cache" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "www" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.www.website_endpoint
    origin_id = "S3-www.${local.domain_name}"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true
  is_ipv6_enabled = true
  default_root_object = aws_s3_bucket_website_configuration.www.index_document[0].suffix

  aliases = ["www.${local.domain_name}"]

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "S3-www.${local.domain_name}"
    cache_policy_id = data.aws_cloudfront_cache_policy.default_cache.id
    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 31536000
    default_ttl = 31536000
    max_ttl = 31536000
    compress = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

resource "aws_cloudfront_distribution" "root" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.root.website_endpoint
    origin_id = "S3-.${local.domain_name}"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true
  is_ipv6_enabled = true

  aliases = [local.domain_name]

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "S3-.${local.domain_name}"
    cache_policy_id = data.aws_cloudfront_cache_policy.default_cache.id
    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 86400
    max_ttl = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

# Route 53 records

# Note: I don't want to override all of the existing DNS records, so I use
# `data` here instead of creating a resource.
data "aws_route53_zone" "main" {
  name = local.domain_name
}

resource "aws_route53_record" "root-a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name = local.domain_name
  type = "A"

  alias {
    name = aws_cloudfront_distribution.root.domain_name
    zone_id = aws_cloudfront_distribution.root.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root-aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name = local.domain_name
  type = "AAAA"

  alias {
    name = aws_cloudfront_distribution.root.domain_name
    zone_id = aws_cloudfront_distribution.root.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www-a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name = "www.${local.domain_name}"
  type = "A"

  alias {
    name = aws_cloudfront_distribution.www.domain_name
    zone_id = aws_cloudfront_distribution.www.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www-aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name = "www.${local.domain_name}"
  type = "AAAA"

  alias {
    name = aws_cloudfront_distribution.www.domain_name
    zone_id = aws_cloudfront_distribution.www.hosted_zone_id
    evaluate_target_health = false
  }
}
