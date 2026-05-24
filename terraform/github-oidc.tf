# ---------------------------------------------------------------------------
# GitHub Actions OIDC — keyless CI/CD authentication
#
# Allows GitHub Actions workflows in msdauris/Ultimate-Agentic-DevOps-with-Claude-Code
# to assume an AWS IAM role without storing any long-lived credentials.
# ---------------------------------------------------------------------------

# OIDC Identity Provider — registered once per AWS account
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # AWS STS is the intended audience for GitHub Actions OIDC tokens
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's well-known OIDC certificate thumbprints (stable, published by GitHub)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Trust policy — scoped to pushes to main in this repository only
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid     = "GitHubOIDCAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Audience must be sts.amazonaws.com (matches client_id_list above)
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Subject is scoped to pushes to main in this exact repository — no wildcards
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:msdauris/Ultimate-Agentic-DevOps-with-Claude-Code:ref:refs/heads/main"]
    }
  }
}

# IAM Role assumed by GitHub Actions runners
resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Deploy policy — minimum permissions needed for S3 sync + CF invalidation
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_deploy" {
  # S3: read/write/delete objects, list bucket (required for --delete sync)
  statement {
    sid    = "S3SyncSite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]
  }

  # CloudFront: create cache invalidations only
  statement {
    sid       = "CloudFrontInvalidate"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "deploy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}

# ---------------------------------------------------------------------------
# Output — embed in workflow file or use for reference
# ---------------------------------------------------------------------------
output "github_actions_role_arn" {
  description = "IAM role ARN to use in aws-actions/configure-aws-credentials"
  value       = aws_iam_role.github_actions.arn
}
