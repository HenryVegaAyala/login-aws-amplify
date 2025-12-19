# Landing Page - Infraestructura Terraform en AWS

## 📋 Descripción

Este módulo de Terraform gestiona la infraestructura para el despliegue de aplicaciones estáticas (landing pages, SPAs) en AWS, incluyendo:

- **S3 Bucket** para hosting estático con versionamiento
- **CloudFront** para distribución CDN global con soporte SPA
- **ACM** para certificados SSL/TLS automáticos
- **Route53** para gestión DNS con soporte multi-subdominio

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    Usuarios Finales                      │
└────────────────┬───────────────┬────────────────────────┘
                 │               │
        ┌────────▼──────┐  ┌────▼─────────┐
        │ shop.domain   │  │ store.domain │  (Múltiples subdominios)
        └────────┬──────┘  └────┬─────────┘
                 │               │
                 └───────┬───────┘
                         │
                 ┌───────▼────────┐
                 │   Route53      │ (DNS Management)
                 └───────┬────────┘
                         │
                 ┌───────▼────────┐
                 │  CloudFront    │ (CDN + SSL)
                 │  + ACM Cert    │
                 └───────┬────────┘
                         │
                 ┌───────▼────────┐
                 │   S3 Bucket    │ (Static Hosting)
                 │   (Único)      │
                 └────────────────┘
```

## 📁 Estructura del Proyecto

```
terraform/
├── envs/
│   └── dev/
│       ├── main.tf              # Configuración principal
│       ├── outputs.tf           # Outputs de la infraestructura
│       ├── provider.tf          # Configuración de AWS Provider
│       ├── variables.tf         # Definición de variables
│       └── terraform.tfvars     # Valores de variables (personalizable)
├── modules/
│   ├── acm/
│   │   └── main.tf              # Módulo certificados SSL/TLS
│   ├── cloudfront/
│   │   └── main.tf              # Módulo CDN CloudFront
│   ├── route53/
│   │   └── main.tf              # Módulo gestión DNS
│   └── s3/
│       └── main.tf              # Módulo bucket S3
├── users/
│   ├── main.tf                  # Gestión de usuarios IAM
│   ├── outputs.tf               # Outputs de usuarios
│   └── providers.tf             # Providers para usuarios
└── README.md                    # Este archivo
```

## 🚀 Configuración Rápida

### Pre-requisitos

- Terraform >= 1.0
- AWS CLI configurado
- Credenciales AWS con permisos adecuados
- Zona Route53 existente para el dominio

### Variables Principales

Las variables se configuran en `envs/dev/terraform.tfvars`:

```hcl
# General
project_name = "s3-app"
environment  = "dev"
aws_region   = "us-east-1"

# Dominio y Subdominios
domain_name = "hvegatech.me"        # Tu dominio registrado
bucket_name = "s3-app-demo"         # Nombre del bucket S3
subdomains  = ["s3"]                # Subdominios (ej: 's3.hvegatech.me')

# Optimización de Costos
enable_lifecycle_rules             = true
enable_logging                     = false
noncurrent_version_expiration_days = 120
noncurrent_version_transition_days = 30
```

## 🔧 Uso

### 1. Inicializar Terraform

```bash
cd terraform/envs/dev
terraform init
```

### 2. Validar Configuración

```bash
terraform validate
terraform fmt -recursive
```

### 3. Planificar Cambios

```bash
terraform plan
```

### 4. Aplicar Infraestructura

```bash
terraform apply
```

### 5. Ver Outputs

```bash
terraform output
```

## 📤 Outputs Disponibles

| Output | Descripción |
|--------|-------------|
| `s3_bucket_name` | Nombre del bucket S3 |
| `s3_bucket_website_endpoint` | Endpoint web del bucket |
| `acm_certificate_arn` | ARN del certificado SSL |
| `cloudfront_distribution_id` | ID de CloudFront |
| `cloudfront_distribution_domain` | Dominio de CloudFront |
| `domain_urls` | URLs completas de subdominios |
| `dns_record_fqdns` | FQDNs de registros DNS |
| `subdomains_map` | Mapa de subdominios configurados |

## 🌐 Gestión de Subdominios

### Agregar Nuevo Subdominio

1. Edita `terraform.tfvars`:
```hcl
subdomains = ["s3", "app", "demo"]
```

2. Aplica los cambios:
```bash
terraform apply
```

### Eliminar Subdominio

1. Remueve el subdominio de la lista en `terraform.tfvars`
2. Aplica los cambios (Terraform eliminará el registro DNS automáticamente)

**⚠️ Nota**: Todos los subdominios apuntan al mismo bucket S3, por lo que sirven el mismo contenido.

## 📦 Despliegue de Aplicación

### Subir archivos al S3

```bash
# Sincronizar carpeta local con S3
aws s3 sync ./dist s3://dev-s3-app-s3-app-demo-bucket/ --delete

# Invalidar caché de CloudFront
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

### Script de Despliegue Automatizado

```bash
#!/bin/bash
# deploy.sh

BUCKET_NAME=$(terraform output -raw s3_bucket_name)
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
BUILD_DIR="./dist"

echo "🚀 Desplegando a $BUCKET_NAME..."

# Build de la aplicación (ajustar según tu framework)
npm run build

# Subir archivos a S3
aws s3 sync $BUILD_DIR s3://$BUCKET_NAME/ --delete

# Invalidar caché
echo "🔄 Invalidando caché de CloudFront..."
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"

echo "✅ Despliegue completado"
```

## 🔐 Características de Seguridad

### S3 Bucket
- ✅ Encriptación AES256 habilitada
- ✅ Versionamiento activado
- ✅ Acceso público bloqueado (solo CloudFront)
- ✅ Origin Access Identity (OAI) configurado

### CloudFront
- ✅ SSL/TLS obligatorio (HTTPS)
- ✅ Política de seguridad TLSv1.2_2021
- ✅ HTTP redirige a HTTPS automáticamente
- ✅ Función de reescritura para SPA routing

### ACM
- ✅ Certificados SSL multi-dominio
- ✅ Validación automática vía DNS

## 💰 Optimización de Costos

### Ambiente DEV
```hcl
enable_lifecycle_rules = true   # Optimiza costos a largo plazo
enable_logging         = false  # Ahorra ~$2-5/mes
```

### Lifecycle Rules (Versionamiento)
- Versiones antiguas → STANDARD_IA (30 días)
- Versiones antiguas → Eliminación (90 días)

### Estimación de Costos Mensuales

| Servicio | DEV | PROD |
|----------|-----|------|
| S3 Storage | ~$0.5 | ~$2 |
| CloudFront | ~$5 | ~$20-50 |
| Route53 | $0.50/dominio | $0.50/dominio |
| ACM | Gratis | Gratis |
| **Total** | **~$6-10** | **~$25-60** |

*Nota: Costos varían según tráfico y almacenamiento*

## 🔄 Soporte SPA (Single Page Application)

CloudFront incluye una función que reescribe URIs para soportar routing de SPAs:

- `/about` → `/index.html`
- `/products/123` → `/index.html`
- `/shop/` → `/shop/index.html`

Esto permite que frameworks como React, Vue o Angular funcionen correctamente.

## 🧪 Testing

### Verificar Certificado SSL

```bash
curl -I https://s3.hvegatech.me
```

### Verificar Subdominios

```bash
for subdomain in s3 app demo; do
  echo "Testing $subdomain..."
  curl -I https://$subdomain.hvegatech.me
done
```

### Verificar Propagación DNS

```bash
dig s3.hvegatech.me
nslookup app.hvegatech.me
```

## 🛠️ Mantenimiento

### Actualizar Certificado SSL
Los certificados ACM se renuevan automáticamente si la validación DNS está configurada correctamente.

### Limpiar Versiones Antiguas de S3
Las lifecycle rules se encargan automáticamente si `enable_lifecycle_rules = true`.

### Monitoreo
CloudFront genera métricas en CloudWatch automáticamente:
- Requests
- Bytes Downloaded
- Error Rate

## 🐛 Troubleshooting

### Error: Certificado no válido
**Problema**: CloudFront muestra error SSL
**Solución**: 
1. Verifica que el certificado esté en `us-east-1`
2. Espera a que la validación DNS se complete (~5-10 min)

### Error: 403 Forbidden en S3
**Problema**: No se puede acceder a los archivos
**Solución**:
1. Verifica la bucket policy
2. Confirma que los archivos tienen permisos correctos
3. Revisa el OAI de CloudFront

### Error: Subdominios no resuelven
**Problema**: DNS no propaga
**Solución**:
1. Verifica registros en Route53: `terraform output dns_record_fqdns`
2. Espera propagación DNS (hasta 48h, típicamente 5-30 min)
3. Limpia caché DNS local: `ipconfig /flushdns` (Windows)

### CloudFront sirve contenido antiguo
**Problema**: Cambios no se reflejan
**Solución**:
```bash
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

## 📚 Recursos Adicionales

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/best-practices.html)
- [Route53 Documentation](https://docs.aws.amazon.com/route53/)

## 🤝 Contribuir

1. Crea un branch para tu feature: `git checkout -b feature/nueva-funcionalidad`
2. Valida los cambios: `terraform validate && terraform fmt`
3. Commit: `git commit -m 'feat: descripción del cambio'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Crea un Pull Request

## 📝 Changelog

### v1.0.0 (2024-12-18)
- ✨ Configuración inicial multi-subdominio
- ✨ Soporte SPA con reescritura de URIs
- ✨ Certificados SSL multi-dominio
- ✨ Lifecycle rules para optimización de costos
- ✨ Ambientes dev y prod

## 📄 Licencia

Este proyecto es de código abierto y está disponible para uso educativo y comercial.

## 👥 Contacto

Para consultas sobre esta infraestructura, puedes contactar al equipo de desarrollo.

---

**⚠️ Importante**: Nunca commitees archivos `terraform.tfstate` o credenciales AWS al repositorio.

