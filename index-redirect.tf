

# -----------------------------------------------------------------------------------------------------------
# IAM Role for Redirect Lambda

data "aws_iam_policy_document" "lambda_redirect" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "lambda_redirect" {
  name = "${var.site}-lambda-redirect-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_redirect.json

  tags = {
    Site = var.site
  }
}

# -----------------------------------------------------------------------------------------------------------
# Lambda Subdirectory index.html Redirect

data "archive_file" "index_redirect" {
  type        = "zip"
  source_file = "${path.module}/frontend/index_redirect.js"
  output_path = ".terraform/tmp/lambda/index_redirect.zip"
}

resource "aws_lambda_function" "index_redirect" {
  function_name    = "${var.site}_frontend_index_redirect"

  filename         = data.archive_file.index_redirect.output_path
  source_code_hash = data.archive_file.index_redirect.output_base64sha256
  
  description      = "index.html subdirectory redirect"
  handler          = "index_redirect.handler"
  publish          = true
  role             = aws_iam_role.lambda_redirect.arn
  runtime          = "nodejs12.x"

  tags = {
    Name   = "${var.site}-index-redirect"
    Site = var.site
  }
}

