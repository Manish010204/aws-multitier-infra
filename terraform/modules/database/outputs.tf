# ─────────────────────────────────────────────
# Database Module — Outputs
# ─────────────────────────────────────────────

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_identifier" {
  description = "RDS instance identifier for CloudWatch"
  value       = aws_db_instance.main.identifier
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}