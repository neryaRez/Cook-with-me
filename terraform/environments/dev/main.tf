data "aws_caller_identity" "current" {}

module "network" {
  source = "../../modules/network"

  project_name = var.project_name
  env_name     = var.env_name
  aws_region   = var.aws_region
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  env_name     = var.env_name
  repositories = local.repositories
}

module "eks" {
  source = "../../modules/eks"

  project_name = var.project_name
  env_name     = var.env_name

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
}

module "inspector" {
  source = "../../modules/inspector"

  enable_inspector = true
}

module "storage" {
  source = "../../modules/storage"

  project_name = var.project_name
  env_name     = var.env_name
  aws_region   = var.aws_region
}
