# ─────────────────────────────────────────────
# Compute Module — Outputs
# ─────────────────────────────────────────────

output "alb_dns_name" {
  description = "ALB DNS name — paste in browser to see app"
  value       = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
}

output "asg_name" {
  description = "Auto Scaling Group name for CloudWatch alarms"
  value       = aws_autoscaling_group.app.name
}

output "ec2_sg_id" {
  description = "EC2 Security Group ID — needed by RDS module"
  value       = aws_security_group.ec2.id
}