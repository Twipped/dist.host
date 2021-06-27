
resource "aws_s3_bucket" "frontend" {
  bucket = var.domain
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = {
    Name = "Frontend"
    Site = var.site
  }
}

# data "aws_iam_policy_document" "frontend_policy" {
#   statement {
#     actions = [
#       "s3:ListBucket",
#       "s3:PutObject",
#       "s3:PutObjectAcl",
#       "s3:GetObject",
#       "s3:GetObjectAcl",
#       "s3:DeleteObject",
#       "s3:ListMultipartUploadParts",
#       "s3:AbortMultipartUpload",
#     ]

#     principals {
#       type        = "AWS"
#       identifiers = [
#         aws_iam_user.s3sync.arn
#       ]
#     }

#     resources = [ aws_s3_bucket.frontend.arn ]
#   }

#   depends_on = [ aws_s3_bucket.frontend ]
# }

# resource "aws_s3_bucket_policy" "frontend_sync_policy" {
#   bucket = aws_s3_bucket.frontend.bucket
#   policy = data.aws_iam_policy_document.frontend_policy.json
# }

# -----------------------------------------------------------------------------------------------------------
# Data Storage Bucket

resource "aws_s3_bucket" "datastore" {
  bucket = "${var.site}-data"
  acl    = "private"

  tags = {
    Name = "Data Store"
    Site = var.site
  }
}

# # -----------------------------------------------------------------------------------------------------------
# # Frontend Logs Bucket

# data "aws_canonical_user_id" "current" {}

# resource "aws_s3_bucket" "ipixel_logs" {
#   bucket = "${var.site}-analytics"

#   grant {
#     id          = data.aws_canonical_user_id.current.id
#     permissions = ["FULL_CONTROL"]
#     type        = "CanonicalUser"
#   }

#   grant {
#     # Grant CloudFront awslogsdelivery logs access to your Amazon S3 Bucket
#     # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#AccessLogsBucketAndFileOwnership
#     id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
#     permissions = ["FULL_CONTROL"]
#     type        = "CanonicalUser"
#   }

#   lifecycle_rule {
#     id      = "logfiles"
#     enabled = true

#     prefix = "RAW/"

#     transition {
#       days          = 30
#       storage_class = "STANDARD_IA" # or "ONEZONE_IA"
#     }

#   }

#   tags = {
#     Name = "iPixel Logs Storage"
#     Site = var.site
#   }
# }