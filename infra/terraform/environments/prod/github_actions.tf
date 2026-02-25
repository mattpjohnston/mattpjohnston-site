data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_frontend_ci_role && var.create_github_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? one(aws_iam_openid_connect_provider.github[*].arn) : var.github_oidc_provider_arn
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  count = var.enable_frontend_ci_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "github_actions_frontend" {
  count = var.enable_frontend_ci_role ? 1 : 0

  name               = "${var.project_name}-github-actions-frontend"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "github_actions_frontend" {
  count = var.enable_frontend_ci_role ? 1 : 0

  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${module.frontend.bucket_name}"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${module.frontend.bucket_name}/*"
    ]
  }

  statement {
    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = [
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.frontend.distribution_id}"
    ]
  }

  statement {
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
    ]

    resources = [
      "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-visitor-counter"
    ]
  }
}

resource "aws_iam_policy" "github_actions_frontend" {
  count = var.enable_frontend_ci_role ? 1 : 0

  name   = "${var.project_name}-github-actions-frontend"
  policy = data.aws_iam_policy_document.github_actions_frontend[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "github_actions_frontend" {
  count = var.enable_frontend_ci_role ? 1 : 0

  role       = aws_iam_role.github_actions_frontend[0].name
  policy_arn = aws_iam_policy.github_actions_frontend[0].arn
}
