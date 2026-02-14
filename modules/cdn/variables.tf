variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, staging, prod)"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}

variable "domain_name" {
  type        = string
  description = "Main domain name (e.g., streaming.com)"
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the Application Load Balancer (ALB) from the compute module"
}

variable "media_bucket_name" {
  type        = string
  description = "Name of the S3 bucket used for storing media content"
}

