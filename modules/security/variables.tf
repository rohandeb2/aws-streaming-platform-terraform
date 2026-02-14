variable "environment"         { type = string }
variable "common_tags"         { type = map(string) }
variable "github_org" {
  type = string
  description = "GitHub Organization name"
}
variable "github_repo"         {
  type = string
  description = "GitHub Repository name"
}
variable "ecs_cluster_name"    { type = string }
variable "ecs_service_name"    { type = string }
variable "alb_arn_suffix"      { type = string }
variable "db_cluster_id"       { type = string }

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where security groups and logs will be configured"
}
