
resource "aws_api_gateway_rest_api" "backend" {
  name        = "${var.site}_backend"
  description = "Lambda-powered Backend API"
  depends_on = [
    aws_lambda_function.backend
  ]
}

resource "aws_api_gateway_resource" "backend_api_root" {
  path_part   = "v1"
  parent_id   = aws_api_gateway_rest_api.backend.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.backend.id
}

resource "aws_api_gateway_resource" "backend_api_proxy" {
  path_part   = "{proxy+}"
  parent_id   = aws_api_gateway_resource.backend_api_root.id
  rest_api_id = aws_api_gateway_rest_api.backend.id
}

resource "aws_api_gateway_method" "backend" {
  rest_api_id   = aws_api_gateway_rest_api.backend.id
  resource_id   = aws_api_gateway_resource.backend_api_proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.backend.id
  resource_id = aws_api_gateway_method.backend.resource_id
  http_method = aws_api_gateway_method.backend.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend.invoke_arn

  request_parameters =  {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_method" "backend_root" {
  rest_api_id   = aws_api_gateway_rest_api.backend.id
  resource_id   = aws_api_gateway_rest_api.backend.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.backend.id
  resource_id = aws_api_gateway_method.backend_root.resource_id
  http_method = aws_api_gateway_method.backend_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend.invoke_arn
}

resource "aws_api_gateway_deployment" "backend" {
  rest_api_id = aws_api_gateway_rest_api.backend.id
  stage_name  = var.stage # THIS IS CRITICAL

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.lambda_root,
    aws_api_gateway_method.backend,
    aws_api_gateway_method.backend_root,
    aws_api_gateway_rest_api_policy.backend_public_access,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.backend_api_root,
      aws_api_gateway_resource.backend_api_proxy,
      aws_api_gateway_method.backend,
      aws_api_gateway_method.backend_root,
      aws_api_gateway_integration.lambda_integration,
      aws_api_gateway_integration.lambda_root,
      aws_api_gateway_rest_api_policy.backend_public_access, # REDEPLOY MUST HAPPEN IF PERMISSIONS CHANGE
    ]))
  }
}


resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.backend.execution_arn}/*/*"
}

output "base_url" {
  value = aws_api_gateway_deployment.backend.invoke_url
}

output "lambda_public_url" {
  value = "${aws_api_gateway_deployment.backend.invoke_url}${aws_api_gateway_resource.backend_api_root.path}"
}

data "aws_iam_policy_document" "public_api_access" {
  statement {
    actions = ["execute-api:Invoke"]

    principals {
      type = "AWS"
      identifiers = [ "*" ]
    }

    resources = [ "${aws_api_gateway_rest_api.backend.execution_arn}/*/*" ]
  }
}

resource "aws_api_gateway_rest_api_policy" "backend_public_access" {
  rest_api_id = aws_api_gateway_rest_api.backend.id
  policy = data.aws_iam_policy_document.public_api_access.json
}


resource "aws_api_gateway_gateway_response" "gateway-response" {
  rest_api_id   = aws_api_gateway_rest_api.backend.id
  status_code   = "403"
  response_type = "INVALID_API_KEY"
  response_templates = {
    "application/json" = "{\"status\":403,\"layer\":\"Gateway\",\"request-id\":\"$context.requestId\",\"code\":\"$context.error.responseType\",\"message\":\"$context.error.message\"}"
  }
}
