# providers.tf (Root Directory)

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use any version in the 5.x range
    }
  }
}

provider "aws" {
  region = var.aws_region

  # This is a lifesaver: it applies these tags to EVERY resource created in this project
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Netflix-Clone"
      ManagedBy   = "Terraform"
    }
  }
}
