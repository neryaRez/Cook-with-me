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
  type    = string
  default = "main"
}

variable "github_oidc_provider_arn" {
  type    = string
  default = null
}

variable "role_name_suffix" {
  type    = string
  default = "github-actions-role"
}

variable "attach_administrator_policy" {
  type    = bool
  default = false
}

variable "ecr_repository_arns" {
  type    = list(string)
  default = []
}

variable "eks_cluster_arn" {
  type    = string
  default = null
}


variable "github_branch_patterns" {
  type        = list(string)
  description = "Allowed GitHub branch patterns for OIDC trust, for example: main, ci/*"
  default     = []
}
