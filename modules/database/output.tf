output "db_cluster_endpoint" {
  description = "The connection endpoint for the PostgreSQL instance"
  value       = aws_db_instance.postgresql.address
}

output "db_reader_endpoint" {
  description = "The endpoint for read operations"
  value       = aws_db_instance.postgresql.address
}

output "db_cluster_id" {
  description = "The ID of the PostgreSQL instance"
  value       = aws_db_instance.postgresql.id
}

output "redis_primary_endpoint" {
  description = "The endpoint of the Redis replication group"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}
