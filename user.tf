# -----------------------------------------------------------------------------------------------------------
# IAM User for Uploading

resource "aws_iam_user" "s3sync" {
  name = "${var.site}-sync"
  path = "/${var.site}/"

  tags = {
    Site = var.site
    Category = "S3"
  }
}

data "aws_iam_policy_document" "s3sync_permissions" {
  statement {
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "s3:PutAccountPublicAccessBlock",
      "s3:GetAccountPublicAccessBlock",
      "s3:ListAllMyBuckets",
      "s3:HeadBucket"
    ]

    resources = [ aws_cloudfront_distribution.frontend.arn ]
  }
}

resource "aws_iam_user_policy" "s3" {
  name = "test"
  user = aws_iam_user.s3sync.name

  policy = data.aws_iam_policy_document.s3sync_permissions.json
}

# This writes the s3 access key and secret to the terraform state file
resource "aws_iam_access_key" "s3" {
  user    = aws_iam_user.s3sync.name
}
