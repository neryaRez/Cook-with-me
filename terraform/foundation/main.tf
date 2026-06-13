module "github_oidc_infra" {
  source = "../modules/github-oidc"

  project_name = var.project_name
  env_name     = var.env_name

  github_owner  = var.github_owner
  github_repo   = var.github_repo
  github_branch = var.github_branch

  github_oidc_provider_arn = var.github_oidc_provider_arn


  github_branch_patterns = [
    var.github_branch,
    "ci/*"
  ]
  role_name_suffix            = "github-actions-infra-role"
  attach_administrator_policy = true
}
