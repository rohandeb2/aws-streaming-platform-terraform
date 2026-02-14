output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of private app subnet IDs"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "List of private db subnet IDs"
  value       = aws_subnet.private_db[*].id
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}
