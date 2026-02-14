# --- ECS Task Execution Role (Infrastructure level: Pull images, write logs) ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_standard" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- ECS Task Role (Application level: Access S3, DynamoDB, etc.) ---
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# --- CI/CD OIDC Role (GitHub Actions) ---
# Create the OIDC Provider (Run once per account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"] # Standard GitHub thumbprint
}

resource "aws_iam_role" "cicd_role" {
  name = "github-actions-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity",
      Effect = "Allow",
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub": "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })
}

# --- Log Groups ---
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/streaming-app-${var.environment}"
  retention_in_days = 30
  tags              = var.common_tags
}

# --- Alarms ---

# 1. ECS High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "ecs-cpu-utilization-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}

# 2. ALB 5XX Error Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "alb-high-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# 3. Aurora RDS CPU High Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "rds-cpu-utilization-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  dimensions = {
    DBClusterIdentifier = var.db_cluster_id
  }
}
