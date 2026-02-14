# --- ECS Cluster ---
resource "aws_ecs_cluster" "this" {
  name = "cluster-${var.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]
}

# --- CloudWatch Logs ---
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.environment}/logs"
  retention_in_days = 30
}

# --- IAM Roles ---
resource "aws_iam_role" "execution_role" {
  name = "ecs-execution-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{
      Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Security Groups ---
resource "aws_security_group" "alb" {
  name   = "alb-sg-${var.environment}"
  vpc_id = var.vpc_id
  ingress { 
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress  { 
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "ecs-task-sg-${var.environment}"
  vpc_id = var.vpc_id
  ingress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# --- Load Balancer ---
resource "aws_lb" "main" {
  name               = "alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "frontend" {
  name        = "tg-frontend-${var.environment}"
  port        = var.frontend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check { path = "/health" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.id
  }
}

# --- ECS Services (Frontend Example) ---
resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_mem
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = var.frontend_image
    essential = true
    portMappings = [{ containerPort = var.frontend_port }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = "ap-south-1"
        "awslogs-stream-prefix" = "frontend"
      }
    }
  }])
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = var.frontend_port
  }
}

# --- Auto Scaling ---
resource "aws_appautoscaling_target" "frontend_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.frontend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  name               = "cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
  }
}
