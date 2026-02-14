# 1. Networking Foundation
module "vpc" {
  source              = "./modules/vpc"
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  public_subnets      = var.public_subnets
  private_app_subnets = var.private_app_subnets
  private_db_subnets  = var.private_db_subnets
  common_tags         = local.common_tags
}

# 2. Security, IAM & Monitoring
module "security" {
  source           = "./modules/security"
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  github_org       = var.github_org
  github_repo      = var.github_repo
  ecs_cluster_name = module.compute.ecs_cluster_name
  ecs_service_name = module.compute.frontend_service_name
  alb_arn_suffix   = module.compute.alb_arn_suffix
  db_cluster_id    = module.database.db_cluster_id
  common_tags      = local.common_tags
}

# 3. Data Layer (Aurora & Redis)
module "database" {
  source               = "./modules/database"
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.db_subnet_group_name
  db_subnet_ids        = module.vpc.private_db_subnet_ids
  app_subnet_ids       = module.vpc.private_app_subnet_ids
  ecs_sg_id            = module.compute.ecs_tasks_sg_id
  common_tags          = local.common_tags
}

# 4. Compute Layer (ALB + ECS Fargate)
module "compute" {
  source             = "./modules/ecs"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_app_subnet_ids

  # IAM Roles from Security Module
  execution_role_arn = module.security.task_execution_role_arn
  task_role_arn      = module.security.task_role_arn

  # Container Images
  frontend_image     = var.frontend_image
  backend_image      = var.backend_image

  common_tags        = local.common_tags
}

# 5. Content Delivery (S3 + CloudFront)
module "cdn" {
  source            = "./modules/cdn"
  environment       = var.environment
  domain_name       = var.domain_name
  alb_dns_name      = module.compute.alb_dns_name
  media_bucket_name = var.media_bucket_name
  common_tags       = local.common_tags
}

# 6. Asynchronous Processing (SQS + EventBridge)
module "async" {
  source              = "./modules/async"
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_app_subnet_ids
  ecs_cluster_arn     = module.compute.ecs_cluster_arn
  task_definition_arn = module.compute.backend_task_arn
  ecs_task_sg_id      = module.compute.ecs_tasks_sg_id
  common_tags         = local.common_tags
}

