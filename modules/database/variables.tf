variable "environment"          { type = string }
variable "vpc_id"               { type = string }
variable "db_subnet_group_name" { type = string }
variable "db_subnet_ids"        { type = list(string) }
variable "app_subnet_ids"       { type = list(string) }
variable "ecs_sg_id"            { type = string }
variable "common_tags"          { type = map(string) }

# Aurora Config
variable "db_name"              { default = "streaming_db" }
variable "master_username"      { default = "dbadmin" }
variable "min_acu"              { default = 0.5 }
variable "max_acu"              { default = 4.0 }

# Redis Config
variable "redis_node_type"      { default = "cache.t4g.medium" }
variable "redis_port"           { default = 6379 }
