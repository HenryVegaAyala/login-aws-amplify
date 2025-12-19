# ==============================================================================
# MÓDULO ACM - Certificados SSL/TLS Multi-Subdominio
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
  description = "Lista de dominios completos para el certificado (incluye SANs)"
}

variable "zone_id" {
  type        = string
  description = "ID de la zona Route53 para validación DNS"
}

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  default_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Module      = "acm"
  }
}

# ==============================================================================
# RECURSOS ACM
# ==============================================================================

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_names[0]
  subject_alternative_names = length(var.domain_names) > 1 ? slice(var.domain_names, 1, length(var.domain_names)) : []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags, {
    Name    = "${var.project_name}-${var.environment}-certificate"
    Domains = join(" ", var.domain_names)
  })
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.value]

  allow_overwrite = true

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Outputs
output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
}

output "certificate_status" {
  value = aws_acm_certificate.cert.status
}

output "validation_id" {
  value = aws_acm_certificate_validation.cert.id
}

