# ─────────────────────────────────────────────
# IAM Role for EC2
#
# WHY: EC2 needs AWS permissions (SSM access)
# Use IAM role — NEVER hardcode access keys
# Role gives temporary auto-rotating credentials
# ─────────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  name = "${var.project}-${var.environment}-ec2-role"

  # Trust policy — who can assume this role
  # Only EC2 service can use it
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.project}-${var.environment}-ec2-role" }
}

# SSM = AWS Systems Manager
# Lets you connect to EC2 via browser/CLI
# without opening port 22 or managing SSH keys
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile = container that holds the role
# EC2 doesn't attach roles directly — needs profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}