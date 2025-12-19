# Módulo Route53 - Gestión DNS

variable "domain_name" {
  type        = string
  description = "Dominio base"
}

variable "subdomains" {
  type        = list(string)
  description = "Lista de subdominios"
}

variable "cloudfront_domain" {
  type        = string
  description = "Dominio de CloudFront"
}

variable "cloudfront_zone_id" {
  type        = string
  description = "Zone ID de CloudFront"
}

locals {
  subdomains_map = { for subdomain in var.subdomains : subdomain => "${subdomain}.${var.domain_name}" }
}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "subdomains" {
  for_each = local.subdomains_map

  zone_id         = data.aws_route53_zone.selected.zone_id
  name            = each.value
  type            = "CNAME"
  ttl             = 300
  records         = [var.cloudfront_domain]
  allow_overwrite = true

  lifecycle {
    create_before_destroy = false
  }
}

# Outputs
output "zone_id" {
  value = data.aws_route53_zone.selected.zone_id
}

output "record_fqdns" {
  value = [for record in aws_route53_record.subdomains : record.fqdn]
}

output "record_urls" {
  value = [for subdomain in var.subdomains : "https://${subdomain}.${var.domain_name}"]
}

output "subdomains_map" {
  value = local.subdomains_map
}

