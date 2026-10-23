variable "region" {
  description = "Región principal del proyecto"
  type        = string
  default     = "us-east-2"
}

variable "dominio_app" {
  description = "Dominio público de la aplicación (CloudFront)"
  type        = string
  default     = "d1tqw0yq09gni5.cloudfront.net"
}