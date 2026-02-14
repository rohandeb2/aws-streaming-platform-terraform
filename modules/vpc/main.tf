# --- VPC & Internet Gateway ---
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, { Name = "vpc-${var.environment}" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "igw-${var.environment}" })
}

# --- Subnets ---

# Public Subnets (For ALB and NAT Gateways)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, { Name = "public-subnet-${count.index + 1}-${var.environment}" })
}

# Private App Subnets (For ECS Fargate)
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.common_tags, { Name = "app-subnet-${count.index + 1}-${var.environment}" })
}

# Private DB Subnets (For Aurora & Redis)
resource "aws_subnet" "private_db" {
  count             = length(var.private_db_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.common_tags, { Name = "db-subnet-${count.index + 1}-${var.environment}" })
}

# --- NAT Gateway (One per AZ for HA) ---
resource "aws_eip" "nat" {
  count  = length(var.public_subnets)
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "nat-eip-${count.index + 1}-${var.environment}" })
}

resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.common_tags, { Name = "nat-gw-${count.index + 1}-${var.environment}" })
  
  depends_on = [aws_internet_gateway.this]
}

# --- Route Tables & Associations ---

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.common_tags, { Name = "rt-public-${var.environment}" })
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (One per AZ to point to local NATGW)
resource "aws_route_table" "private" {
  count  = length(var.private_app_subnets)
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }
  tags = merge(var.common_tags, { Name = "rt-private-${count.index + 1}-${var.environment}" })
}

resource "aws_route_table_association" "app" {
  count          = length(var.private_app_subnets)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "db" {
  count          = length(var.private_db_subnets)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- Database Subnet Group (Required for RDS/Aurora) ---
resource "aws_db_subnet_group" "this" {
  name        = "db-subnet-group-${var.environment}"
  description = "Subnet group for Aurora Database"
  subnet_ids  = aws_subnet.private_db[*].id

  tags = merge(var.common_tags, { Name = "db-subnet-group-${var.environment}" })
}
