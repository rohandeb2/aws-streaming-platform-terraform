# --- KMS Key for Encryption ---
resource "aws_kms_key" "async" {
  description             = "KMS key for SQS and EventBridge"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.common_tags
}

# --- SQS with DLQ ---
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.queue_name}-dlq-${var.environment}"
  kms_master_key_id         = aws_kms_key.async.id
  message_retention_seconds = 1209600 # 14 days
  tags                      = var.common_tags
}

resource "aws_sqs_queue" "main" {
  name                      = "${var.queue_name}-${var.environment}"
  kms_master_key_id         = aws_kms_key.async.id
  visibility_timeout_seconds = 30
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5 # Move to DLQ after 5 failed attempts
  })

  tags = var.common_tags
}

# --- EventBridge Scheduler ---

# IAM Role for EventBridge to run ECS tasks
resource "aws_iam_role" "eventbridge_ecs" {
  name = "eb-ecs-trigger-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "eb_pass_role" {
  name = "eventbridge-passrole-policy"
  role = aws_iam_role.eventbridge_ecs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "*" # Restrict this to your ECS Task roles in production
      },
      {
        Effect   = "Allow",
        Action   = "ecs:RunTask",
        Resource = replace(var.task_definition_arn, "/:\\d+$/", ":*")
        Condition = {
          ArnEquals = { "ecs:cluster" = var.ecs_cluster_arn }
        }
      }
    ]
  })
}

# The Rule (The "When")
resource "aws_cloudwatch_event_rule" "scheduled_task" {
  name                = "nightly-maintenance-${var.environment}"
  description         = "Triggers ECS maintenance task"
  schedule_expression = var.schedule_expression
  tags                = var.common_tags
}

# The Target (The "What")
resource "aws_cloudwatch_event_target" "ecs_maintenance" {
  rule      = aws_cloudwatch_event_rule.scheduled_task.name
  arn       = var.ecs_cluster_arn
  role_arn  = aws_iam_role.eventbridge_ecs.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = var.task_definition_arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"

    network_configuration {
      subnets         = var.private_subnet_ids
      security_groups = [var.ecs_task_sg_id]
      assign_public_ip = false
    }
  }
}
