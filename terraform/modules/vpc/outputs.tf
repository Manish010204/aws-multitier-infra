# ─────────────────────────────────────────────
# VPC Module — Outputs
#
# WHY outputs: Other modules need VPC info
# Compute module needs subnet IDs to place EC2
# Database module needs subnet IDs for RDS
# Outputs are how modules share data
# ─────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (ALB goes here)"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of private app subnet IDs (EC2 goes here)"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "List of private DB subnet IDs (RDS goes here)"
  value       = aws_subnet.private_db[*].id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}