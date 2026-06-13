data "tls_certificate" "github" {
  count = var.github_oidc_provider_arn == null ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  name_prefix = "${var.project_name}-${var.env_name}"

  allowed_branch_patterns = length(var.github_branch_patterns) > 0 ? var.github_branch_patterns : [var.github_branch]

  repo_refs = [
    for branch_pattern in local.allowed_branch_patterns :
    "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${branch_pattern}"
  ]

  role_name         = "${local.name_prefix}-${var.role_name_suffix}"
  oidc_provider_arn = var.github_oidc_provider_arn != null ? var.github_oidc_provider_arn : aws_iam_openid_connect_provider.github[0].arn

  ecr_resources = length(var.ecr_repository_arns) > 0 ? var.ecr_repository_arns : ["*"]
  eks_resource  = var.eks_cluster_arn != null ? var.eks_cluster_arn : "*"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_oidc_provider_arn == null ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.github[0].certificates[0].sha1_fingerprint
  ]
}

resource "aws_iam_role" "github_actions" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.repo_refs
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_deploy" {
  count = var.attach_administrator_policy ? 0 : 1

  name = "${local.role_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = local.ecr_resources
      },
      {
        Sid      = "EksDescribe"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = local.eks_resource
      },
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  count = var.attach_administrator_policy ? 0 : 1

  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_deploy[0].arn
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  count = var.attach_administrator_policy ? 1 : 0

  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
