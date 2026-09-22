# ─────────────────────────────────────────────
# Database Module — RDS MySQL
# ─────────────────────────────────────────────

# ── SECURITY GROUP: RDS ───────────────────────
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Allow MySQL only from EC2 security group"
  vpc_id      = var.vpc_id

  # CRITICAL: Only EC2 SG can reach RDS
  # Not 0.0.0.0/0 — not even your laptop
  # Only the application tier EC2 instances
  ingress {
    description     = "MySQL from EC2 only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ec2_sg_id]
  }

  # No outbound needed for RDS
  # But AWS requires egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-${var.environment}-rds-sg" }
}

# WHY reference EC2 SG instead of CIDR:
# If you use CIDR (10.0.10.0/24), anyone who
# gets into that subnet can reach RDS
# If you use SG reference, ONLY instances
# with that exact security group can connect
# Much more precise and secure

# ── DB SUBNET GROUP ───────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = { Name = "${var.project}-${var.environment}-db-subnet-group" }
}

# WHY DB subnet group:
# RDS needs to know which subnets it can use
# Subnet group = list of subnets across AZs
# RDS picks one for primary, one for standby
# Must span at least 2 AZs for Multi-AZ

# ── RDS INSTANCE ──────────────────────────────
resource "aws_db_instance" "main" {
  identifier = "${var.project}-${var.environment}-mysql"

  # Engine
  engine         = "mysql"
  engine_version = "8.0"

  # Size — t3.micro is free tier eligible
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  # Database credentials
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network — place in private DB subnets
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # NEVER expose to internet
  publicly_accessible = false

  # Multi-AZ = standby replica in another AZ
  # If primary fails, AWS auto-promotes standby
  # Failover takes ~60-120 seconds automatically
  # Set false to save cost, true for screenshot
  multi_az = false

  # Encryption at rest using AES-256
  storage_encrypted = true

  # Automated backups — 1 day retention
  backup_retention_period = 1
  backup_window           = "03:00-04:00"

  # Maintenance window — when AWS applies patches
  maintenance_window = "Mon:04:00-Mon:05:00"

  # Performance Insights — free tier available
  performance_insights_enabled = false

  # skip_final_snapshot = true means terraform
  # destroy works cleanly without creating a snapshot
  # In production this would be FALSE
  skip_final_snapshot = true

  # Prevent accidental deletion
  deletion_protection = false

  tags = {
    Name = "${var.project}-${var.environment}-rds"
  }
}

# ── CLOUDWATCH ALARMS FOR RDS ─────────────────
# WHY alarms here and not monitoring module:
# RDS-specific metrics are tightly coupled
# to the RDS instance — makes more sense here

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project}-${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU above 80% for 4 minutes"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  tags = { Name = "${var.project}-${var.environment}-rds-cpu-alarm" }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project}-${var.environment}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000 # 2GB in bytes
  alarm_description   = "RDS free storage below 2GB"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  tags = { Name = "${var.project}-${var.environment}-rds-storage-alarm" }
}