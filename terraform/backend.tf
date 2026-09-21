# ─────────────────────────────────────────────
# Terraform Backend Configuration
#
# WHY: Stores terraform.tfstate in S3 instead
# of locally. This means:
#   - State is safe even if laptop crashes
#   - DynamoDB prevents two people running
#     terraform apply simultaneously
# ─────────────────────────────────────────────

terraform {
  backend "s3" {
    bucket       = "manish-terraform-state-762233741136"
    key          = "prod/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}