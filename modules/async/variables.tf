variable "environment"        { type = string }
variable "common_tags"        { type = map(string) }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }

# ECS Target Config
variable "ecs_cluster_arn"    { type = string }
variable "task_definition_arn" { type = string }
variable "ecs_task_sg_id"     { type = string }

# SQS Config
variable "queue_name"         { default = "media-processing-queue" }

# EventBridge Config
variable "schedule_expression" { 
  default = "cron(0 20 * * ? *)" # Runs daily at 8 PM UTC
}
