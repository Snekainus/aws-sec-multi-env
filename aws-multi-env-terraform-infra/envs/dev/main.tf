terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source          = "../../modules/networking"
  name            = "dev"
  cidr_block      = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  azs             = ["us-east-1a", "us-east-1b"]
}

module "security" {
  source = "../../modules/security"
  vpc_id = module.networking.vpc_id
}

module "compute" {
  source             = "../../modules/compute"
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  app_sg_id          = module.security.app_sg_id
  instance_type      = "t3.micro"
  app_name           = "dev-app"
  vpc_id             = module.networking.vpc_id
}

module "database" {
  source          = "../../modules/database"
  db_name         = "devdb"
  username        = "devuser"
  password        = var.db_password
  subnet_ids      = module.networking.private_subnet_ids
  vpc_id          = module.networking.vpc_id
  app_sg_id       = module.security.app_sg_id
  backup_retention = 7
}

module "storage" {
  source = "../../modules/s3"
  env    = "dev"
}

module "monitoring" {
  source   = "../../modules/monitoring"
  asg_name = module.compute.asg_name
}
