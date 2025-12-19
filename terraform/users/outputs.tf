output "user_name" {
  value = aws_iam_user.frontend_deployer.name
}

output "user_arn" {
  value = aws_iam_user.frontend_deployer.arn
}

output "s3_policy_arn" {
  value = aws_iam_policy.s3_deployment.arn
}

output "cloudfront_policy_arn" {
  value = aws_iam_policy.cloudfront_invalidation.arn
}

output "bucket_arns" {
  description = "ARNs de los buckets de la aplicación"
  value       = local.bucket_arns
}

output "instructions" {
  value = <<-EOT
  Usuario IAM: ${aws_iam_user.frontend_deployer.name}
  ARN: ${aws_iam_user.frontend_deployer.arn}

  Crear access keys:
    aws iam create-access-key --user-name ${aws_iam_user.frontend_deployer.name}

  Permisos:
    - S3 deployment para ambientes: ${join(", ", var.environments)}
    - CloudFront invalidations para todas las distribuciones

  Bucket: ${var.bucket_name}
  Formato: {env}-${var.project_name}-${var.bucket_name}-bucket
  EOT
}

