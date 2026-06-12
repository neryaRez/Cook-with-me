variable "project_name" {
  type = string
}

variable "env_name" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "github_oidc_provider_arn" {
  type    = string
  default = null
}

variable "ecr_repository_arns" {
  type = list(string)
}

variable "eks_cluster_arn" {
  type = string
}
