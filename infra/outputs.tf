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
