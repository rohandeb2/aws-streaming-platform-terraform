output "alb_dns_name" {
  description = "Public DNS of the ALB"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS Cluster"
  value       = aws_ecs_cluster.this.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "frontend_service_name" {
  value = aws_ecs_service.frontend.name
}

output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "backend_task_arn" {
  # Note: Since your code currently only has a frontend task definition,
  # point this to frontend or create a backend one.
  value = aws_ecs_task_definition.frontend.arn
}
