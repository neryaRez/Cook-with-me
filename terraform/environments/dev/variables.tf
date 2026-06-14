variable "project_name" {
  description = "Project name used for AWS resource naming."
  type        = string
  default     = "cook-with-me"
}

variable "env_name" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub repository owner."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the CI/CD role."
  type        = string
  default     = "main"
}

variable "github_actions_infra_role_arn" {
  type        = string
  description = "GitHub Actions infra role ARN created by terraform/foundation"
}
