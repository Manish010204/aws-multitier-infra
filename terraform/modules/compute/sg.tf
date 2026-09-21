# ─────────────────────────────────────────────
# Security Groups
# WHO can talk to WHO
# ─────────────────────────────────────────────

# ── ALB SECURITY GROUP ────────────────────────
# Controls what traffic reaches the ALB
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Allow HTTP inbound to ALB from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound to reach EC2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-${var.environment}-alb-sg" }
}

# ── EC2 SECURITY GROUP ────────────────────────
# Controls what traffic reaches EC2 instances
resource "aws_security_group" "ec2" {
  name        = "${var.project}-${var.environment}-ec2-sg"
  description = "Allow HTTP only from ALB — not from internet"
  vpc_id      = var.vpc_id

  # KEY SECURITY DECISION:
  # Source is ALB security group — not 0.0.0.0/0
  # Only ALB can reach EC2 — nobody else
  ingress {
    description     = "HTTP only from ALB security group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outbound for updates via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-${var.environment}-ec2-sg" }
}