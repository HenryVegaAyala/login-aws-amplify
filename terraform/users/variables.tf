variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Región de AWS"
}

variable "project_name" {
  type        = string
  default     = "s3-app"
  description = "Nombre del proyecto (debe coincidir con terraform/envs)"
}

variable "user_name" {
  type    = string
  default = "user-frontend-deployer"
  description = "Nombre del usuario IAM para despliegues"
}

variable "environments" {
  type        = list(string)
  default     = ["dev", "uat", "prod"]
  description = "Lista de ambientes"
}

variable "bucket_name" {
  type        = string
  default     = "s3-app-demo"
  description = "Nombre del bucket (debe coincidir con terraform/envs)"
}

