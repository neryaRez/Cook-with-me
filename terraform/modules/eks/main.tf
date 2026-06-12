locals {
  cluster_name = "${var.project_name}-${var.env_name}-eks"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.30"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      name           = "${local.cluster_name}-nodes"
      subnet_ids     = var.private_subnet_ids
      instance_types = var.node_instance_types

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      disk_size = 20

      iam_role_name            = "${local.cluster_name}-node-role"
      iam_role_use_name_prefix = false
    }
  }

  tags = {
    Name = local.cluster_name
  }
}
