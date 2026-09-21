# ─────────────────────────────────────────────
# VPC Module — Main Resources
# ─────────────────────────────────────────────

# ── VPC ──────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

# WHY enable_dns_hostnames + enable_dns_support:
# Without these, EC2 instances don't get DNS names
# like ec2-xx-xx.compute.amazonaws.com
# RDS endpoint resolution also needs DNS enabled

# ── PUBLIC SUBNETS ────────────────────────────
# ALB lives here — needs internet access
resource "aws_subnet" "public" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.azs[count.index]

  # Instances launched here get a public IP
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.environment}-public-${count.index + 1}"
    Tier = "public"
  }
}

# WHY count = length(var.azs):
# var.azs = ["ap-south-1a", "ap-south-1b"]
# length = 2, so this creates 2 public subnets
# count.index = 0 for first, 1 for second
# cidrsubnet(10.0.0.0/16, 8, 0) = 10.0.0.0/24
# cidrsubnet(10.0.0.0/16, 8, 1) = 10.0.1.0/24

# ── PRIVATE APP SUBNETS ───────────────────────
# EC2 instances live here — no direct internet
resource "aws_subnet" "private_app" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.azs[count.index]

  # NO public IP — these are private
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project}-${var.environment}-private-app-${count.index + 1}"
    Tier = "app"
  }
}

# WHY offset by 10:
# count.index + 10 means:
# cidrsubnet(10.0.0.0/16, 8, 10) = 10.0.10.0/24
# cidrsubnet(10.0.0.0/16, 8, 11) = 10.0.11.0/24
# Keeps IP ranges clearly separated per tier

# ── PRIVATE DB SUBNETS ────────────────────────
# RDS lives here — most isolated, no internet
resource "aws_subnet" "private_db" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = var.azs[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project}-${var.environment}-private-db-${count.index + 1}"
    Tier = "db"
  }
}

# ── INTERNET GATEWAY ──────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.environment}-igw"
  }
}

# WHY Internet Gateway:
# VPC is completely isolated by default
# IGW is the door between your VPC and internet
# Without IGW, nothing in VPC can reach internet
# ALB needs this to receive traffic from users

# ── ELASTIC IP FOR NAT ────────────────────────
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.environment}-nat-eip"
  }

  # Must create IGW first before EIP
  depends_on = [aws_internet_gateway.main]
}

# WHY Elastic IP:
# NAT Gateway needs a fixed public IP
# EIP gives it a permanent IP that doesn't change
# Even if NAT Gateway is replaced

# ── NAT GATEWAY ───────────────────────────────
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# WHY NAT Gateway in PUBLIC subnet:
# NAT Gateway allows PRIVATE subnet resources
# to reach internet (for updates, patches)
# but blocks internet from reaching them directly
# Think of it as a one-way door — outbound only
# It must sit in PUBLIC subnet so it can reach IGW
# We use only 1 NAT (cost saving — 2 would be HA)

# ── ROUTE TABLE: PUBLIC ───────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # All internet traffic → IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-rt-public"
  }
}

# ── ROUTE TABLE: PRIVATE ──────────────────────
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # All internet traffic → NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-rt-private"
  }
}

# WHY two route tables:
# Public RT sends traffic to IGW (bidirectional)
# Private RT sends traffic to NAT (outbound only)
# DB subnets use private RT but SG blocks
# all traffic anyway — double protection

# ── ROUTE TABLE ASSOCIATIONS ──────────────────
# Connect each subnet to its route table

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}

# ── VPC FLOW LOGS ─────────────────────────────
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.project}-${var.environment}-flow-logs"
  retention_in_days = 7

  tags = {
    Name = "${var.project}-${var.environment}-flow-logs"
  }
}

# WHY 7 days retention:
# Flow logs cost money to store
# 7 days is enough for debugging
# In production this might be 30-90 days

resource "aws_iam_role" "flow_log" {
  name = "${var.project}-${var.environment}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_log" {
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn

  tags = {
    Name = "${var.project}-${var.environment}-flow-log"
  }
}

# WHY VPC Flow Logs:
# Records ALL network traffic in your VPC
# Who connected to what, from where, accepted/rejected
# Critical for security auditing and debugging
# "ALL" captures both accepted and rejected traffic