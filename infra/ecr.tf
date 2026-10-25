# ============================================================
# ECR: registro privado de imágenes Docker del backend
# ============================================================

resource "aws_ecr_repository" "backend" {
  name = "tareas-db"

  # Un tag nunca se sobrescribe: "a1b2c3d" siempre es el mismo commit
  image_tag_mutability = "IMMUTABLE"

  # Escaneo básico de vulnerabilidades (gratis) cada vez que se sube una imagen
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Solo se guardan las últimas 5 imágenes (el almacenamiento se cobra por GB)
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Conservar solo las ultimas 5 imagenes"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

# La EC2 descarga (pull) las imágenes
resource "aws_iam_role_policy" "backend_ecr_pull" {
  name = "ecr-pull"
  role = aws_iam_role.backend_ec2.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken" # no admite restringir por recurso
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:BatchCheckLayerAvailability"]
        Resource = aws_ecr_repository.backend.arn
      },
    ]
  })
}

# GitHub Actions sube (push) las imágenes.
# Es una política administrada (no inline): las inline de un usuario suman
# máximo 2048 bytes y github-deploy ya está cerca del límite
resource "aws_iam_policy" "github_ecr_push" {
  name        = "github-deploy-ecr-push"
  description = "Subir imagenes del backend a ECR desde GitHub Actions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:BatchGetImage", "ecr:DescribeImages",
        ]
        Resource = aws_ecr_repository.backend.arn
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "github_ecr_push" {
  user       = aws_iam_user.github_deploy.name
  policy_arn = aws_iam_policy.github_ecr_push.arn
}
