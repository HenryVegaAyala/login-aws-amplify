terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  # Formato: ${environment}-${project_name}-${bucket_name}-bucket
  # Ejemplo: dev-s3-app-s3-app-demo-bucket
  bucket_arns = [
    for env in var.environments :
    "arn:aws:s3:::${env}-${var.project_name}-${var.bucket_name}-bucket"
  ]

  # ARNs de objetos dentro de los buckets
  bucket_object_arns = [for arn in local.bucket_arns : "${arn}/*"]

  default_tags = {
    ManagedBy = "Terraform"
    Project   = var.project_name
    Module    = "users-frontend"
  }
}

resource "aws_iam_user" "frontend_deployer" {
  name = var.user_name
  path = "/deployers/"
  tags = merge(local.default_tags, { Name = var.user_name })
}

resource "aws_iam_policy" "s3_deployment" {
  name        = "${var.project_name}-frontend-s3-deployment"
  path        = "/deployers/"
  description = "Permisos S3 para despliegue de frontend"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketVersioning", "s3:GetBucketWebsite"]
        Resource = local.bucket_arns
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectVersion",
          "s3:DeleteObjectVersion"
        ]
        Resource = local.bucket_object_arns
      }
    ]
  })

  tags = merge(local.default_tags, { Name = "${var.project_name}-frontend-s3-deployment" })
}

resource "aws_iam_policy" "cloudfront_invalidation" {
  name        = "${var.project_name}-frontend-cloudfront-invalidation"
  path        = "/deployers/"
  description = "Permisos CloudFront para invalidaciones"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["cloudfront:ListDistributions", "cloudfront:GetDistribution", "cloudfront:GetDistributionConfig"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation", "cloudfront:ListInvalidations"]
        Resource = "arn:aws:cloudfront::*:distribution/*"
      }
    ]
  })

  tags = merge(local.default_tags, { Name = "${var.project_name}-frontend-cloudfront-invalidation" })
}

resource "aws_iam_user_policy_attachment" "s3_deployment" {
  user       = aws_iam_user.frontend_deployer.name
  policy_arn = aws_iam_policy.s3_deployment.arn
}

resource "aws_iam_user_policy_attachment" "cloudfront_invalidation" {
  user       = aws_iam_user.frontend_deployer.name
  policy_arn = aws_iam_policy.cloudfront_invalidation.arn
}


