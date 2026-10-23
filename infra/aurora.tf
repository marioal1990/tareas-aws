# ============================================================
# Aurora PostgreSQL Serverless v2 (configuración Express)
#   - Sin VPC, acceso por "internet access gateway" con TLS
#   - Autenticación solo con IAM (sin contraseña)
#   - Escala a 0 ACU tras 5 minutos sin uso
# Importado desde recursos existentes (ver Parte 7F)
#
# Nota: algunos atributos de la configuración Express (internet access
# gateway, sin VPC) aún no existen en el provider de Terraform; AWS los
# mantiene y Terraform simplemente no los gestiona.
# ============================================================

resource "aws_rds_cluster" "tareas" {
  cluster_identifier = "tareas-db"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned" # Serverless v2 usa el modo "provisioned" + instancias db.serverless
  engine_version     = "17.9"
  master_username    = "postgres" # cambiarlo obliga a recrear el cluster

  engine_lifecycle_support        = "open-source-rds-extended-support"
  db_cluster_parameter_group_name = "default.aurora-postgresql17"
  port                            = 5432

  # Seguridad: solo IAM, sin acceso "publicly_accessible" clásico
  iam_database_authentication_enabled = true
  publicly_accessible                 = false
  storage_encrypted                   = false
  enable_http_endpoint                = false

  # Capacidad: de 0 (pausado) a 1 ACU
  serverlessv2_scaling_configuration {
    min_capacity             = 0
    max_capacity             = 1
    seconds_until_auto_pause = 300
  }

  # Respaldos y mantenimiento
  backup_retention_period      = 1
  preferred_backup_window      = "06:18-06:48"
  preferred_maintenance_window = "fri:04:01-fri:04:31"
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = false
  delete_automated_backups     = true
  deletion_protection          = true # AWS rechaza borrar el cluster, venga de donde venga
  skip_final_snapshot          = false # si algún día se borra, se toma un snapshot final
  final_snapshot_identifier    = "tareas-db-final"

  # Monitoreo básico (sin Enhanced Monitoring: requeriría un rol que la SCP bloquea)
  database_insights_mode       = "standard"
  monitoring_interval          = 0
  performance_insights_enabled = false

  lifecycle {
    # Recrear el cluster significa PERDER TODAS LAS TAREAS
    prevent_destroy = true
    ignore_changes = [
      engine_version,     # AWS aplica versiones menores automáticamente (17.9 -> 17.x)
      availability_zones, # AWS las asigna; cambiarlas en el código forzaría un reemplazo
    ]
  }
}

resource "aws_rds_cluster_instance" "tareas_1" {
  identifier         = "tareas-db-instance-1"
  cluster_identifier = aws_rds_cluster.tareas.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.tareas.engine
  engine_version     = aws_rds_cluster.tareas.engine_version

  availability_zone            = "us-east-2a"
  db_parameter_group_name      = "default.aurora-postgresql17"
  ca_cert_identifier           = "rds-ca-rsa2048-g1"
  publicly_accessible          = false
  promotion_tier               = 1
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = false
  preferred_backup_window      = "06:18-06:48"
  preferred_maintenance_window = "wed:07:02-wed:07:32"

  monitoring_interval          = 0
  performance_insights_enabled = false

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [engine_version]
  }
}
