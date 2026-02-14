variable "environment" { 
  type = string 
}
variable "vpc_id"      { type = string }
variable "public_subnet_ids"  { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "common_tags"        { type = map(string) }

# Frontend Config
variable "frontend_image" { type = string }
variable "frontend_cpu"   { default = 256 }
variable "frontend_mem"   { default = 512 }
variable "frontend_port"  { default = 80 }

# Backend Config
variable "backend_image"  { type = string }
variable "backend_cpu"    { default = 512 }
variable "backend_mem"    { default = 1024 }
variable "backend_port"   { default = 8080 }

# Scaling
variable "max_capacity" { default = 10 }
variable "min_capacity" { default = 2 }

variable "execution_role_arn" {
  type        = string
  description = "ARN of the IAM role that allows ECS to pull images and push logs"
}

variable "task_role_arn" {
  type        = string
  description = "ARN of the IAM role that allows the application to access AWS services"
}
