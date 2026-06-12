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

module "github_oidc" {
  source = "../../modules/github-oidc"

  project_name = var.project_name
  env_name     = var.env_name

  github_owner  = var.github_owner
  github_repo   = var.github_repo
  github_branch = var.github_branch

  github_oidc_provider_arn = var.github_oidc_provider_arn

  ecr_repository_arns = module.ecr.repository_arns
  eks_cluster_arn     = module.eks.cluster_arn
}

resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.github_oidc.github_actions_role_arn
  type          = "STANDARD"

  depends_on = [module.eks]
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.github_oidc.github_actions_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}
