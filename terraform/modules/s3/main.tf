# ==============================================================================
# MÓDULO S3 - Gestión Segura de Bucket Único para ecommerce
# ==============================================================================
#

variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Ambiente de despliegue"
}

variable "bucket_name" {
  type        = string
  description = "Nombre del bucket único"
}

variable "enable_logging" {
  type        = bool
  default     = true
  description = "Habilitar logging de acceso S3"
}

variable "enable_lifecycle_rules" {
  type        = bool
  default     = true
  description = "Habilitar reglas de ciclo de vida"
}

variable "noncurrent_version_expiration_days" {
  type        = number
  default     = 120
  description = "Días para eliminar versiones no actuales (debe ser > transition_days + 60)"
}

variable "noncurrent_version_transition_days" {
  type        = number
  default     = 30
  description = "Días para transición a STANDARD_IA"
}

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  bucket_full_name = "${var.environment}-${var.project_name}-${var.bucket_name}-bucket"
  default_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Module      = "s3"
  }
}

# ==============================================================================
# S3 BUCKET ÚNICO PARA ecommerce
# ==============================================================================

resource "aws_s3_bucket" "bucket" {
  bucket        = local.bucket_full_name
  force_destroy = true
  tags          = merge(local.default_tags, { Name = local.bucket_full_name, BucketType = var.bucket_name })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.project_name}-${var.environment}-${var.bucket_name}"
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket     = aws_s3_bucket.bucket.id
  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadForWebsite"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.bucket.id

  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

# ✅ ARCHIVO index.html INICIAL
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<-HTML
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${var.project_name} - ${var.bucket_name}</title>
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          max-width: 900px;
          margin: 50px auto;
          padding: 30px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          backdrop-filter: blur(10px);
          border-radius: 20px;
          padding: 30px;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        h1 {
          margin-top: 0;
          font-size: 2.5em;
          text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .success { color: #4ade80; font-weight: bold; }
        .info {
          background: rgba(255, 255, 255, 0.15);
          padding: 20px;
          border-radius: 10px;
          margin: 20px 0;
          border-left: 4px solid #4ade80;
        }
        .info p { margin: 10px 0; }
        .badge {
          display: inline-block;
          padding: 5px 15px;
          background: rgba(74, 222, 128, 0.2);
          border-radius: 20px;
          font-size: 0.9em;
          margin: 5px;
        }
        hr {
          border: none;
          border-top: 1px solid rgba(255, 255, 255, 0.2);
          margin: 30px 0;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🛒 ${upper(var.bucket_name)} - E-commerce Platform</h1>
        <div class="info">
          <p><strong>🏷️ Proyecto:</strong> ${var.project_name}</p>
          <p><strong>🌍 Environment:</strong> <span class="badge">${var.environment}</span></p>
          <p><strong>🪣 Bucket:</strong> ${local.bucket_full_name}</p>
          <p><strong>🔒 Security:</strong> <span class="success">✅ Website Endpoint + CloudFront CDN</span></p>
          <p><strong>🔐 Encryption:</strong> <span class="success">AES-256</span></p>
          <p><strong>🚀 Tipo:</strong> ${var.bucket_name}</p>
          <p><strong>📦 Accesible desde múltiples subdominios</strong></p>
        </div>
        <p>✨ Este es el bucket único de <strong>${var.bucket_name}</strong>. Despliega tu aplicación de e-commerce aquí.</p>
        <p>🌐 Todos los subdominios configurados apuntarán a este mismo bucket.</p>
        <hr>
        <small>🤖 Managed by Terraform | Mochillea Platform</small>
      </div>
    </body>
    </html>
  HTML
}

# ==============================================================================
# BUCKET DE LOGS
# ==============================================================================

resource "aws_s3_bucket" "logs" {
  count         = var.enable_logging ? 1 : 0
  bucket        = "${var.environment}-${var.project_name}-${var.bucket_name}-logs"
  force_destroy = true
  tags          = merge(local.default_tags, { Name = "${var.environment}-${var.project_name}-${var.bucket_name}-logs", BucketType = "logs" })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encrypt" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs_private" {
  count                   = var.enable_logging ? 1 : 0
  bucket                  = aws_s3_bucket.logs[0].id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_cleanup" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"
    filter {}
    expiration                        { days = 90 }
    noncurrent_version_expiration     { noncurrent_days = 30 }
  }
}

resource "aws_s3_bucket_logging" "logging" {
  count         = var.enable_logging ? 1 : 0
  bucket        = aws_s3_bucket.bucket.id
  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "${local.bucket_full_name}/"
}

# Lifecycle Policies
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "manage-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_transition {
      noncurrent_days = var.noncurrent_version_transition_days
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = var.noncurrent_version_transition_days + 60
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}

output "bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}

