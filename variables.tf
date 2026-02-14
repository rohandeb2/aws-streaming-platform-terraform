variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type = string
}

variable "project_name" {
  type    = string
  default = "hotstar-clone"
}

# Networking
variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_app_subnets" {
  type = list(string)
}

variable "private_db_subnets" {
  type = list(string)
}

# Application
variable "frontend_image" {
  type = string
}

variable "backend_image" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "media_bucket_name" {
  type = string
}

# CI/CD
variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}
