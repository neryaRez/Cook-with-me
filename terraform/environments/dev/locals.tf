locals {
  name_prefix = "${var.project_name}-${var.env_name}"

  repositories = [
    "backend",
    "frontend"
  ]
}
