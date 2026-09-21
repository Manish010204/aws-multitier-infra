# ─────────────────────────────────────────────
# VPC Module — Input Variables
# ─────────────────────────────────────────────

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC e.g. 10.0.0.0/16"
  type        = string
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
}