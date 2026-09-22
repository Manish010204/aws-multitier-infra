output "alb_dns_name" {
  description = "Paste this in browser to see your app"
  value       = module.compute.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = module.database.rds_endpoint
}

output "sns_topic_arn" {
  description = "SNS topic for alerts"
  value       = module.monitoring.sns_topic_arn
}

# ── MONITORING MODULE ─────────────────────────
module "monitoring" {
  source = "./modules/monitoring"

  project        = var.project
  environment    = var.environment
  alert_email    = var.alert_email
  asg_name       = module.compute.asg_name
  alb_arn_suffix = module.compute.alb_arn_suffix
}