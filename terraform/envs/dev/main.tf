# Frontend Ecommerce - Infraestructura Dev
# S3 + CloudFront + ACM + Route53

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

locals {
  full_domains = [for subdomain in var.subdomains : "${subdomain}.${var.domain_name}"]
}

# S3 Bucket para hosting estático
module "s3" {
  source                             = "../../modules/s3"
  project_name                       = var.project_name
  environment                        = var.environment
  bucket_name                        = var.bucket_name
  enable_logging                     = var.enable_logging
  enable_lifecycle_rules             = var.enable_lifecycle_rules
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
  noncurrent_version_transition_days = var.noncurrent_version_transition_days
}

# Certificados SSL/TLS
module "acm" {
  source       = "../../modules/acm"
  project_name = var.project_name
  environment  = var.environment
  domain_names = local.full_domains
  zone_id      = data.aws_route53_zone.selected.zone_id
}

# CloudFront CDN
module "cloudfront" {
  source             = "../../modules/cloudfront"
  project_name       = var.project_name
  environment        = var.environment
  domain_names       = local.full_domains
  certificate_arn    = module.acm.certificate_arn
  bucket_domain_name = module.s3.bucket_website_endpoint
  bucket_name        = module.s3.bucket_name

  depends_on = [module.acm, module.s3]
}

# DNS Records
module "route53" {
  source             = "../../modules/route53"
  domain_name        = var.domain_name
  subdomains         = var.subdomains
  cloudfront_domain  = module.cloudfront.distribution_domain
  cloudfront_zone_id = module.cloudfront.distribution_zone_id

  depends_on = [module.cloudfront]
}

