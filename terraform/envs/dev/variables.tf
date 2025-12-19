# Variables - Ambiente DEV

variable "project_name" {
  type        = string
  default     = ""
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Ambiente de despliegue"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Región de AWS"
}

variable "domain_name" {
  type        = string
  default     = ""
  description = "Dominio base"
}

variable "bucket_name" {
  type        = string
  default     = "ecommerce"
  description = "Nombre del bucket"
}

variable "subdomains" {
  type        = list(string)
  default     = ["shop", "tienda"]
  description = "Lista de subdominios"
}

variable "enable_logging" {
  type        = bool
  default     = false
  description = "Habilitar logging S3"
}

variable "enable_lifecycle_rules" {
  type        = bool
  default     = true
  description = "Habilitar lifecycle policies"
}

variable "noncurrent_version_expiration_days" {
  type        = number
  default     = 90
  description = "Días para eliminar versiones antiguas"
}

variable "noncurrent_version_transition_days" {
  type        = number
  default     = 30
  description = "Días para transicionar a STANDARD_IA"
}

variable "additional_tags" {
  type        = map(string)
  default     = {}
  description = "Tags adicionales"
}

