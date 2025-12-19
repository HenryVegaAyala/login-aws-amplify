# ==============================================================================
# MÓDULO CLOUDFRONT - Distribución CDN con Múltiples Dominios
# ==============================================================================

variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Ambiente de despliegue (dev, uat, prod)"
}

variable "domain_names" {
  type        = list(string)
  description = "Lista de dominios completos para los aliases"
}

variable "certificate_arn" {
  type        = string
  description = "ARN del certificado ACM"
}

variable "bucket_domain_name" {
  type        = string
  description = "Website endpoint del bucket S3"
}

variable "bucket_name" {
  type        = string
  description = "Nombre del bucket"
}

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  common_cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  common_response_headers_policy_id = "5cc3b908-e619-4b99-88e5-2cf7f45965bd"
}

# ==============================================================================
# CLOUDFRONT FUNCTIONS - Reescritura de URI para SPA
# ==============================================================================

# Función para reescribir URIs y servir index.html para SPA routing
resource "aws_cloudfront_function" "rewrite_uri" {
  name    = "${var.project_name}-${var.environment}-${var.bucket_name}-rewrite"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite URI for ${var.bucket_name} SPA routing"
  publish = true
  code    = <<-EOF
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    } else if (!uri.includes('.')) {
        request.uri = '/index.html';
    }

    return request;
}
EOF
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = var.domain_names
  default_root_object = "index.html"

  origin {
    domain_name = var.bucket_domain_name
    origin_id   = "S3-${var.bucket_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id           = "S3-${var.bucket_name}"
    viewer_protocol_policy     = "redirect-to-https"
    cached_methods             = ["GET", "HEAD"]
    allowed_methods            = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = local.common_cache_policy_id
    response_headers_policy_id = local.common_response_headers_policy_id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_uri.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}

# Outputs
output "distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "distribution_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.cdn.arn
}

output "distribution_zone_id" {
  value = aws_cloudfront_distribution.cdn.hosted_zone_id
}

