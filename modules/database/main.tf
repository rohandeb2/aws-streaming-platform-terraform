# --- Security Groups ---

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "rds-sg-${var.environment}"
  vpc_id      = var.vpc_id
  description = "Allow inbound from ECS tasks only"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

# Redis Security Group
resource "aws_security_group" "redis" {
  name        = "redis-sg-${var.environment}"
  vpc_id      = var.vpc_id
  description = "Allow inbound from ECS tasks"

  ingress {
    from_port       = var.redis_port
    to_port         = var.redis_port
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
  }

  tags = var.common_tags
}

# --- Standard RDS PostgreSQL (Free Tier Eligible) ---

resource "aws_db_instance" "postgresql" {
  identifier           = "db-instance-${var.environment}"
  engine               = "postgres"
  engine_version       = "16.6"        
  instance_class       = "db.t3.micro" # Free Tier eligible
  allocated_storage     = 20
  max_allocated_storage = 100
  
  db_name              = var.db_name
  username             = var.master_username
  password             = "Password123!" # Your static password
  
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  storage_encrypted    = true
  skip_final_snapshot  = true
  publicly_accessible  = false
  deletion_protection  = false

  tags = var.common_tags
}

# --- ElastiCache Redis ---

resource "aws_elasticache_subnet_group" "this" {
  name       = "redis-subnets-${var.environment}"
  subnet_ids = var.app_subnet_ids 
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "redis-params-${var.environment}"
  family = "redis7"
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "redis-cluster-${var.environment}"
  description                = "Redis for streaming metadata"
  node_type                  = "cache.t3.micro" 
  port                       = var.redis_port
  parameter_group_name       = aws_elasticache_parameter_group.this.name
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.redis.id]

  automatic_failover_enabled = true
  multi_az_enabled           = true
  num_cache_clusters         = 2 

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = var.common_tags
}
