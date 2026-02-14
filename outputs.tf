# --- Networking Outputs ---
output "vpc_id" {
  description = "The ID of the VPC created for the streaming platform"
  value       = module.vpc.vpc_id # Derived from
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (used for ALBs and NAT Gateways)"
  value       = module.vpc.public_subnet_ids # Derived from
}

# --- Compute & Entry Point Outputs ---
output "streaming_platform_url" {
  description = "The public DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name # Derived from
}

output "ecs_cluster_name" {
  description = "The name of the ECS Cluster running the services"
  value       = module.compute.ecs_cluster_name # Derived from
}

# --- Database & Cache Endpoints ---
output "aurora_writer_endpoint" {
  description = "The writer endpoint for the Aurora PostgreSQL cluster"
  value       = module.database.db_cluster_endpoint # Derived from
}

output "redis_primary_endpoint" {
  description = "The primary endpoint address for ElastiCache Redis"
  value       = module.database.redis_primary_endpoint # Derived from
}

# --- Content Delivery Outputs ---
output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution for media assets"
  value       = module.cdn.cloudfront_domain_name # Derived from
}

output "media_s3_bucket_arn" {
  description = "The ARN of the S3 bucket storing media content"
  value       = module.cdn.s3_bucket_arn # Derived from
}

# --- Security & CI/CD Outputs ---
output "cicd_iam_role_arn" {
  description = "The IAM Role ARN to be used in GitHub Actions for OIDC authentication"
  value       = module.security.cicd_role_arn # Derived from
}

# --- Messaging Outputs ---
output "sqs_queue_url" {
  description = "The URL of the primary SQS queue for async processing"
  value       = module.async.sqs_queue_url # Derived from
}
