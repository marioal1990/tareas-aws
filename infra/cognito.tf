# ============================================================
# Cognito: autenticación de usuarios de la app de tareas
# Importado desde recursos existentes (ver Parte 7B)
# ============================================================

resource "aws_cognito_user_pool" "tareas" {
  name                     = "tareas-usuarios"
  user_pool_tier           = "ESSENTIALS"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"
  deletion_protection      = "ACTIVE"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  password_policy {
    minimum_length                   = 8
    password_history_size            = 0
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  sign_in_policy {
    allowed_first_auth_factors = ["PASSWORD"]
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  lifecycle {
    # Borrar el pool elimina a TODOS los usuarios: Terraform se niega a hacerlo
    prevent_destroy = true
  }
}

resource "aws_cognito_user_pool_domain" "login" {
  domain                = "tareas-mario-2026"
  user_pool_id          = aws_cognito_user_pool.tareas.id
  managed_login_version = 1
}

resource "aws_cognito_user_pool_client" "angular" {
  name         = "tareas-angular"
  user_pool_id = aws_cognito_user_pool.tareas.id

  # OAuth: Authorization Code + PKCE para la SPA de Angular (cliente público, sin secret)
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]

  callback_urls = ["http://localhost:4200/", "https://${aws_cloudfront_distribution.app.domain_name}/"]
  logout_urls   = ["http://localhost:4200/", "https://${aws_cloudfront_distribution.app.domain_name}/"]

  # Duración de los tokens
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30
  auth_session_validity  = 3
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  enable_token_revocation                       = true
  enable_propagate_additional_user_context_data = false
  read_attributes                               = []
  write_attributes                              = []
}
