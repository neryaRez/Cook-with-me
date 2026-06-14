output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "ecr_repository_names" {
  value = module.ecr.repository_names
}

output "github_actions_role_arn" {
  value = var.github_actions_infra_role_arn
}

output "images_bucket_name" {
  value = module.storage.images_bucket_name
}
