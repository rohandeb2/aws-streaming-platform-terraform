output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.main.domain_name
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.media.arn
}

output "route53_nameservers" {
  value = aws_route53_zone.main.name_servers
}
