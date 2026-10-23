# ============================================================
# CloudFront: puerta de entrada única de la aplicación
#   /*                  -> S3 (Angular)
#   /tareas-db/*        -> EC2 (Spring Boot)
#   /comentarios-api/*  -> API Gateway (microservicio SAM)
# Importado desde recursos existentes (ver Parte 7E)
# ============================================================

# ---------- Políticas administradas por AWS (por nombre, no por ID) ----------
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

# ---------- Microservicio de comentarios: lo gestiona SAM, aquí solo se LEE ----------
data "aws_cloudformation_stack" "comentarios" {
  name = local.sam_stack
}

# ---------- Función: routing de la SPA (rutas de Angular -> index.html) ----------
resource "aws_cloudfront_function" "spa_rewrite" {
  name    = "spa-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true
  # Se normalizan los saltos de línea para que el resultado sea igual en Windows y en Linux (CI)
  code = trimspace(replace(file("${path.module}/cloudfront/spa-rewrite.js"), "\r\n", "\n"))
}

# ---------- Origin Access Control: "credencial" con la que CloudFront lee el bucket privado ----------
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "oac-tareas-frontend-mario-2026.s3.us-east-2.amazonaw-mv8w0t97sl9"
  description                       = "Created by CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # firma todas las peticiones a S3
  signing_protocol                  = "sigv4"
}

# ---------- Distribución ----------
resource "aws_cloudfront_distribution" "app" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2"
  price_class     = "PriceClass_All"

  tags = {
    Name = "tareas-frontend-mario-2026-cloudfront"
  }

  # ===== Orígenes =====

  # Frontend: bucket privado, CloudFront lo lee con OAC
  origin {
    origin_id                   = "tareas-frontend-mario-2026.s3.us-east-2.amazonaws.com-mv8vsritg2b"
    domain_name                 = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id    = aws_cloudfront_origin_access_control.frontend.id
    connection_attempts         = 3
    connection_timeout          = 10
    response_completion_timeout = 0
  }

  # Backend Spring Boot en la EC2 (DNS de la Elastic IP)
  origin {
    origin_id                   = "ec2-backend"
    domain_name                 = aws_eip.backend.public_dns
    connection_attempts         = 3
    connection_timeout          = 10
    response_completion_timeout = 0

    custom_origin_config {
      http_port                = 8888
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
      ip_address_type          = "ipv4"
    }
  }

  # Microservicio de comentarios (API Gateway, dominio leído del stack de SAM)
  origin {
    origin_id                   = "apigw-comentarios"
    domain_name                 = data.aws_cloudformation_stack.comentarios.outputs["ApiDomain"]
    connection_attempts         = 3
    connection_timeout          = 10
    response_completion_timeout = 0

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
      ip_address_type          = "ipv4"
    }
  }

  # ===== Behaviors =====

  # Por defecto: Angular desde S3, con caché y la función de routing
  default_cache_behavior {
    target_origin_id       = "tareas-frontend-mario-2026.s3.us-east-2.amazonaws.com-mv8vsritg2b"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_rewrite.arn
    }

    grpc_config {
      enabled = false
    }
  }

  # API del backend: sin caché, todos los métodos, reenvía headers (incluido Authorization)
  ordered_cache_behavior {
    path_pattern             = "/tareas-db/*"
    target_origin_id         = "ec2-backend"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id

    grpc_config {
      enabled = false
    }
  }

  # API de comentarios: igual que la anterior (sin Host: API Gateway lo exige)
  ordered_cache_behavior {
    path_pattern             = "/comentarios-api/*"
    target_origin_id         = "apigw-comentarios"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id

    grpc_config {
      enabled = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }

  lifecycle {
    # Recrearla cambiaría el dominio *.cloudfront.net: rompería Cognito y los pipelines
    prevent_destroy = true
  }
}
