# Configuración - Ambiente DEV

# General
project_name = "s3-app"
environment  = "dev"
aws_region   = "us-east-1"

# Dominio y Subdominios
domain_name = "hvegatech.me" # Cambiar por su dominio registrado
bucket_name = "s3-app-demo" # Cambiar Nombre del bucket S3 de su proyecto
subdomains  = ["s3"] # Cambiar Subdominios a usar (ejemplo: 's3' para 's3.hvegatech.me')

# Optimización de Costos
enable_lifecycle_rules             = true
enable_logging                     = false
noncurrent_version_expiration_days = 120
noncurrent_version_transition_days = 30


