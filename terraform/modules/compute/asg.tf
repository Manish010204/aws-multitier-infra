# ─────────────────────────────────────────────
# Launch Template + Auto Scaling Group
#
# Launch Template = "blueprint" for EC2
# ASG = "manager" that keeps N instances running
#
# ASG self-heals:
# Instance dies → ASG launches replacement
# Traffic spikes → ASG adds instances
# Traffic drops → ASG removes instances
# ─────────────────────────────────────────────

# ── LAUNCH TEMPLATE ───────────────────────────
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-${var.environment}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Read user-data.sh and base64 encode it
  # AWS requires user-data to be base64 encoded
  user_data = filebase64("${path.module}/user-data.sh")

  monitoring {
    enabled = true # detailed CloudWatch metrics
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project}-${var.environment}-app"
      Environment = var.environment
    }
  }

  lifecycle {
    # Create new template version before destroying old
    # Ensures zero downtime during updates
    create_before_destroy = true
  }
}

# ── AUTO SCALING GROUP ────────────────────────
resource "aws_autoscaling_group" "app" {
  name                = "${var.project}-${var.environment}-asg"
  min_size            = 1 # never go below 1
  max_size            = 2 # never go above 3
  desired_capacity    = 1 # start with 2
  vpc_zone_identifier = var.private_app_subnet_ids

  target_group_arns = [aws_lb_target_group.app.arn]

  # ELB type = ALB decides if instance is healthy
  # EC2 type = just checks if instance is running
  # ELB is stricter — better for production
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.environment}-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── SCALING POLICY ────────────────────────────
# Target Tracking = cruise control for scaling
# Set target CPU at 70% — AWS handles the rest
# CPU rises above 70% → add instance
# CPU falls below 70% → remove instance
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${var.project}-${var.environment}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}