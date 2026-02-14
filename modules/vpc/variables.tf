variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}

variable "azs" {
  description = "List of Availability Zones in the region"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of CIDRs for Public subnets"
  type        = list(string)
}

variable "private_app_subnets" {
  description = "List of CIDRs for Private App subnets"
  type        = list(string)
}

variable "private_db_subnets" {
  description = "List of CIDRs for Private DB subnets"
  type        = list(string)
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
