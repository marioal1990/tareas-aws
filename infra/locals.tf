# ============================================================
# Valores compartidos del proyecto
# ============================================================

data "aws_caller_identity" "actual" {}

locals {
  account_id = data.aws_caller_identity.actual.account_id

  # Recursos que TODAVÍA no gestiona Terraform.
  # Se reemplazarán por referencias cuando se importen (Partes 7D a 7F).
  cloudfront_distribution_id = "E16I8Q8JEB4NY9"                     # 7E
  ec2_instance_id            = "i-09c7d64216c6a4b9d"                # 7D
  aurora_cluster_resource_id = "cluster-M5BCRX5JVCEGCPFY5LIVAM4P2M" # 7F

  # Recursos que gestiona SAM (microservicio de comentarios): Terraform solo los referencia
  sam_stack  = "comentarios-api"
  sam_bucket = "aws-sam-cli-managed-default-samclisourcebucket-dojmvaqx96sw"
}
