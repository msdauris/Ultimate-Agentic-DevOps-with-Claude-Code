output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket hosting the static site"
  value       = aws_s3_bucket.site.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket hosting the static site"
  value       = aws_s3_bucket.site.arn
}
