output "github_actions_infra_role_arn" {
  value = module.github_oidc_infra.github_actions_role_arn
}

output "github_actions_infra_role_name" {
  value = module.github_oidc_infra.github_actions_role_name
}

output "github_oidc_provider_arn" {
  value = module.github_oidc_infra.github_oidc_provider_arn
}
