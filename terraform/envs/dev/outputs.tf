# Outputs - Ambiente Dev

# S3
output "s3_bucket_name" {
  description = "Nombre del bucket S3"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = module.s3.bucket_arn
}

# CloudFront
output "cloudfront_distribution_id" {
  description = "ID de la distribución CloudFront"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_url" {
  description = "URL de CloudFront"
  value       = "https://${module.cloudfront.distribution_domain}"
}

# Dominios
output "domain_urls" {
  description = "URLs completas de los subdominios"
  value       = module.route53.record_urls
}

output "primary_domain_url" {
  description = "URL principal"
  value       = length(module.route53.record_urls) > 0 ? module.route53.record_urls[0] : null
}

# Deployment info
output "deployment_info" {
  description = "Información de despliegue"
  value = {
    bucket_name          = module.s3.bucket_name
    cloudfront_id        = module.cloudfront.distribution_id
    primary_url          = length(module.route53.record_urls) > 0 ? module.route53.record_urls[0] : null
    all_urls             = module.route53.record_urls
    sync_command         = "aws s3 sync ./dist s3://${module.s3.bucket_name}/ --delete"
    invalidation_command = "aws cloudfront create-invalidation --distribution-id ${module.cloudfront.distribution_id} --paths '/*'"
  }
}

