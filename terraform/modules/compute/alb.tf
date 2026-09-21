# ─────────────────────────────────────────────
# Application Load Balancer
#
# Three resources work together:
# ALB → Listener → Target Group → EC2s
#
# Request flow:
# User → ALB (port 80) → Listener
#      → Target Group → healthy EC2
# ─────────────────────────────────────────────

# ── ALB ───────────────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false # internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project}-${var.environment}-alb" }
}

# ── TARGET GROUP ──────────────────────────────
# The "list" of EC2s that ALB sends traffic to
resource "aws_lb_target_group" "app" {
  name     = "${var.project}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    healthy_threshold   = 2     # 2 passes = healthy
    unhealthy_threshold = 3     # 3 fails = unhealthy
    timeout             = 5     # wait 5s for response
    interval            = 30    # check every 30s
    matcher             = "200" # expect HTTP 200
  }

  tags = { Name = "${var.project}-${var.environment}-tg" }
}

# ── LISTENER ──────────────────────────────────
# Listens on port 80, forwards to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}