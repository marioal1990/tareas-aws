# ============================================================
# Usuarios técnicos para el pipeline de Terraform (GitHub Actions)
#
# Dos usuarios separados (principio de mínimo privilegio):
#   - github-terraform-plan : solo LECTURA. Corre automático en cada push.
#   - github-terraform-apply: puede MODIFICAR la infraestructura.
#                             Solo se usa cuando ejecutas el apply a mano.
#
# Las access keys NO se gestionan aquí (quedarían en el state):
# se crean con la CLI y se guardan como secrets en GitHub.
# ============================================================

locals {
  tfstate_bucket = "tareas-tfstate-mario-2026"
}

# ---------- Plan: solo lectura + uso del state ----------
resource "aws_iam_user" "terraform_plan" {
  name = "github-terraform-plan"
  path = "/"
}

resource "aws_iam_user_policy_attachment" "terraform_plan_readonly" {
  user       = aws_iam_user.terraform_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# El plan necesita leer el state y crear/borrar el archivo de bloqueo (.tflock)
resource "aws_iam_user_policy" "terraform_plan_state" {
  name = "tfstate"
  user = aws_iam_user.terraform_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.tfstate_bucket}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${local.tfstate_bucket}/tareas-aws/*"
      },
    ]
  })
}

# ---------- Apply: permisos amplios, protegido por la ejecución manual ----------
# Terraform administra IAM, EC2, RDS, CloudFront, Cognito y S3, por eso necesita
# permisos de administrador. La protección está en el proceso: este usuario solo
# se usa cuando ejecutas el workflow a mano con "aplicar = true".
resource "aws_iam_user" "terraform_apply" {
  name = "github-terraform-apply"
  path = "/"
}

resource "aws_iam_user_policy_attachment" "terraform_apply_admin" {
  user       = aws_iam_user.terraform_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
