
# -----------------------------------------------------------------------------------------------------------
# Execution role for lambda functions

data "aws_iam_policy_document" "lambda_assume_role" {
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


resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.site}_backend"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Site = var.site,
  }
}

# -----------------------------------------------------------------------------------------------------------
# Lambda Function

data "archive_file" "backend" {
  type        = "zip"
  source_dir  = "${path.module}/backend"
  output_path = ".terraform/tmp/lambda/backend.zip"
}

resource "aws_lambda_function" "backend" {
  function_name = "${var.site}_backend"

  filename         = data.archive_file.backend.output_path
  source_code_hash = data.archive_file.backend.output_base64sha256

  handler       = "index.handler"
  runtime       = "nodejs12.x"

  role          = aws_iam_role.lambda_exec_role.arn

  timeout          = 600
  memory_size      = 512

  environment {
    variables = {
      DATASTORE_BUCKET = aws_s3_bucket.datastore.bucket
      CLOUDWATCH_LOGS_GROUP_ARN = aws_cloudwatch_log_group.backend.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.backend,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_s3_bucket.datastore,
  ]
}

# -----------------------------------------------------------------------------------------------------------
# Lambda Logging

resource "aws_cloudwatch_log_group" "backend" {
  name = "/aws/lambda/${var.site}_backend"

  retention_in_days = 14

  tags = {
    Site = var.site,
  }
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]

    resources = [ "arn:aws:logs:*:*:*" ]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}


# -----------------------------------------------------------------------------------------------------------
# Data Storage Bucket Access

data "aws_iam_policy_document" "lambda_datastore_access" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.datastore.arn,
      "${aws_s3_bucket.datastore.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_datastore_access" {
  name   = "${var.site}_backend_s3_access"
  role   = aws_iam_role.lambda_exec_role.id
  policy = data.aws_iam_policy_document.lambda_datastore_access.json
}
