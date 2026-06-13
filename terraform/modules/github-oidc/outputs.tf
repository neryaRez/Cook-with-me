output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  value = aws_iam_role.github_actions.name
}

output "github_oidc_provider_arn" {
  value = local.oidc_provider_arn
}
