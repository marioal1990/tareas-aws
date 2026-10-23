# ============================================================
# Valores compartidos del proyecto
# ============================================================

data "aws_caller_identity" "actual" {}

locals {
  account_id = data.aws_caller_identity.actual.account_id


  # Recursos que gestiona SAM (microservicio de comentarios): Terraform solo los referencia
  sam_stack  = "comentarios-api"
  sam_bucket = "aws-sam-cli-managed-default-samclisourcebucket-dojmvaqx96sw"
}
