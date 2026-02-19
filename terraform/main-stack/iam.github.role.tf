resource "aws_iam_role" "github" {
  name = "labs-devops-na-nuvem-github-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:sub" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:aud" = "repo:igorcostati/mini-curso-devops-e-aws-dia*"
        }
      }
    }]
    Version = "2012-10-17"
  })
}


data "aws_iam_policy_document" "github" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = aws_ecr_repository.this[*].arn
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      aws_cloudfront_distribution.s3_distribution.arn
    ]
  }
}

resource "aws_iam_policy" "pipeline" {
  name   = "labs-devops-na-nuvem-github-policy"
  policy = data.aws_iam_policy_document.github.json
}

resource "aws_iam_role_policy_attachment" "github_pipeline" {
  policy_arn = aws_iam_policy.pipeline.arn
  role       = aws_iam_role.github.name
} 