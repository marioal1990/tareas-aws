# ============================================================
# S3: frontend (Angular) y artefactos del backend (JAR)
# ============================================================

# ---------- Frontend: privado, solo CloudFront puede leerlo (OAC) ----------
resource "aws_s3_bucket" "frontend" {
  bucket              = "tareas-frontend-mario-2026"
  bucket_namespace    = "global"
  force_destroy       = false
  object_lock_enabled = false
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Id      = "PolicyForCloudFrontPrivateContent"
    Version = "2008-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipal"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
      Condition = {
        ArnLike = {
          "AWS:SourceArn" = aws_cloudfront_distribution.app.arn
        }
      }
    }]
  })
}

# ---------- Artefactos: JAR del backend que despliega el pipeline ----------
resource "aws_s3_bucket" "artifacts" {
  bucket              = "tareas-artifacts-mario-2026"
  bucket_namespace    = "global"
  force_destroy       = false
  object_lock_enabled = false
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket                                 = aws_s3_bucket.artifacts.id
  transition_default_minimum_object_size = "all_storage_classes_128K"

  rule {
    id     = "expirar-jars"
    status = "Enabled"

    filter {
      prefix = "backend/"
    }

    # Los JAR con más de 30 días se borran solos (ahorra almacenamiento)
    expiration {
      days = 30
    }
  }
}
