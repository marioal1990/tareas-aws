output "cognito_issuer" {
  description = "Issuer para Spring Boot, API Gateway y Angular"
  value       = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.tareas.id}"
}

output "cognito_client_id" {
  description = "Client ID de la app Angular"
  value       = aws_cognito_user_pool_client.angular.id
}

output "cognito_dominio_login" {
  description = "Dominio de la página de login de Cognito"
  value       = "https://${aws_cognito_user_pool_domain.login.domain}.auth.${var.region}.amazoncognito.com"
}

output "backend_ip_publica" {
  description = "Elastic IP de la EC2 (para ssh y scp)"
  value       = aws_eip.backend.public_ip
}

output "backend_dns_publico" {
  description = "DNS de la EC2: es el origen /tareas-db/* en CloudFront"
  value       = aws_eip.backend.public_dns
}

output "cloudfront_dominio" {
  description = "URL pública de la aplicación"
  value       = "https://${aws_cloudfront_distribution.app.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "ID de la distribución (variable CF_DIST_ID de GitHub)"
  value       = aws_cloudfront_distribution.app.id
}

output "aurora_endpoint" {
  description = "Endpoint de Aurora (variable DB_HOST del backend)"
  value       = aws_rds_cluster.tareas.endpoint
}

output "ecr_backend_url" {
  description = "Repositorio ECR de la imagen del backend"
  value       = aws_ecr_repository.backend.repository_url
}
