module "vpc" {
  source = "./modules/vpc"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  azs         = var.azs
}

module "compute" {
  source = "./modules/compute"

  project                = var.project
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  ami_id                 = var.ami_id
  instance_type          = var.instance_type
}

# ── DATABASE MODULE ───────────────────────────
module "database" {
  source = "./modules/database"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  ec2_sg_id             = module.compute.ec2_sg_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
}