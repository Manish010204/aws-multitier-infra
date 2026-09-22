# ─────────────────────────────────────────────
# Database Module — Input Variables
# ─────────────────────────────────────────────

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from VPC module"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "Private DB subnet IDs for RDS"
  type        = list(string)
}

variable "ec2_sg_id" {
  description = "EC2 security group ID — only this SG can reach RDS"
  type        = string
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}