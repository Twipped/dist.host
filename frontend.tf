
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {

}

# -----------------------------------------------------------------------------------------------------------
# Cloudfront Configuration

resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "s3"

    # THIS MAKES THE CONFIG UNSTABLE FOR SOME REASON
    # s3_origin_config {
    #   origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    # }
    
    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port = "80"
      https_port = "443"
      origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  origin {
    domain_name = replace(aws_api_gateway_deployment.backend.invoke_url, "/^https?://([^/]*).*/", "$1")
    origin_path = "/${var.stage}"
    origin_id   = "apigw"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [
    var.domain,
    "www.${var.domain}"
  ]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    # lambda_function_association {
    #   event_type   = "origin-request"
    #   lambda_arn   = aws_lambda_function.index_redirect.qualified_arn
    #   include_body = false
    # }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  ordered_cache_behavior {
    path_pattern     = "/v1"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "apigw"

    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern     = "/v1/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "apigw"

    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn       = aws_acm_certificate.cert.arn
    ssl_support_method        = "sni-only"
    minimum_protocol_version  = "TLSv1.1_2016"
  }
  
  depends_on = [
    aws_api_gateway_deployment.backend,
    aws_lambda_function.index_redirect,
  ]

  tags = {
    Name = "Frontend"
    Site = var.site
  }
}

# -----------------------------------------------------------------------------------------------------------
# Site Assets


data "external" "frontend_hash" {
  program = [ "bash", "${path.root}/frontend/hash.sh" ]
}

resource "null_resource" "synchronize_frontend_3s" {

  triggers = {
    script_hash = data.external.frontend_hash.result["hash"]
  }

  provisioner "local-exec" {
    command = "aws s3 sync --acl public-read ${path.module}/frontend/dist s3://${aws_s3_bucket.frontend.id}"
  }
}

