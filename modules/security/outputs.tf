output "task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "cicd_role_arn" {
  value = aws_iam_role.cicd_role.arn
}
