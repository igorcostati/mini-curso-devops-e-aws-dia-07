resource "aws_s3_bucket" "this" {
  bucket = "labs-devops-na-nuvem.tecnologia-i.com.br"

  tags = {
    Name        = "labs-devops-na-nuvem.tecnologia-i.com.br"
    Environment = "Dev"
    Teste = "Teste"
  }
}


resource "aws_s3_bucket_policy" "allow_oac_access" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}