# ─────────────────────────────────────────────
# Root Module — Calls all child modules
#
# Think of this as the "director"
# It doesn't create resources directly
# It calls modules and passes them inputs
# ─────────────────────────────────────────────

# ── VPC MODULE ────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  azs         = var.azs
}

# More modules coming in later labs:
# module "compute" { ... }
# module "database" { ... }
# module "monitoring" { ... }