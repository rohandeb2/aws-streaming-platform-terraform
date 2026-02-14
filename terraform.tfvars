environment  = "prod"
aws_region   = "ap-south-1"
project_name = "streaming-pro"

# Networking (Mumbai 3-AZ)
vpc_cidr            = "10.0.0.0/16"
azs                 = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_app_subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
private_db_subnets  = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

# Images (Pinned to specific versions for Prod)
frontend_image = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/frontend:v1.2.4"
backend_image  = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/backend:v2.1.0"

# Content Delivery
domain_name       = "hotstar-clone.com"
media_bucket_name = "prod-media-assets-hotstar"

# CI/CD Integration
github_org  = "my-organization"
github_repo = "streaming-app-repo"
