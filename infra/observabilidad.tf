# ============================================================
# Observabilidad: logs, alarmas, avisos por email y dashboard
# (capa gratuita: 10 alarmas, 3 dashboards, 5 GB de logs)
# ============================================================

variable "email_alertas" {
  description = "Email que recibe las alarmas (en GitHub: variable ALERTAS_EMAIL)"
  type        = string

  validation {
    condition     = can(regex("^[^@ ]+@[^@ ]+\\.[^@ ]+$", var.email_alertas))
    error_message = "email_alertas debe ser un email válido (define la variable ALERTAS_EMAIL en GitHub)."
  }
}

locals {
  # El ID del HTTP API es la primera parte de su dominio: abc123.execute-api...
  api_comentarios_id = split(".", data.aws_cloudformation_stack.comentarios.outputs["ApiDomain"])[0]
  lambdas            = toset(["tareas-comentarios", "tareas-comentarios-limpieza"])
}

# ------------------------------------------------------------
# Logs del backend (el contenedor los envía con el driver awslogs)
# ------------------------------------------------------------
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/tareas/backend"
  retention_in_days = 14
}

resource "aws_iam_role_policy" "backend_logs" {
  name = "escribir-logs"
  role = aws_iam_role.backend_ec2.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.backend.arn}:*"
    }]
  })
}

# Cuenta las líneas "ERROR" de Spring Boot como una métrica
resource "aws_cloudwatch_log_metric_filter" "backend_errores" {
  name           = "backend-errores"
  log_group_name = aws_cloudwatch_log_group.backend.name
  pattern        = "ERROR"

  metric_transformation {
    namespace     = "Tareas"
    name          = "BackendErrores"
    value         = "1"
    default_value = "0"
  }
}

# ------------------------------------------------------------
# Avisos por email (SNS). AWS envía un correo de confirmación:
# hay que hacer clic en "Confirm subscription"
# ------------------------------------------------------------
resource "aws_sns_topic" "alertas" {
  name = "tareas-alertas"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alertas.arn
  protocol  = "email"
  endpoint  = var.email_alertas
}

# ------------------------------------------------------------
# Alarmas
# ------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "backend_errores" {
  alarm_name          = "tareas-backend-errores"
  alarm_description   = "El backend registró 3 o más ERROR en 5 minutos. Revisa el log group /tareas/backend"
  namespace           = "Tareas"
  metric_name         = "BackendErrores"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 3
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alertas.arn]
  ok_actions          = [aws_sns_topic.alertas.arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "tareas-ec2-status-check"
  alarm_description   = "La EC2 del backend falla los status checks de AWS (hardware o sistema operativo)"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  dimensions          = { InstanceId = aws_instance.backend.id }
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "breaching" # sin datos = la instancia no reporta
  alarm_actions       = [aws_sns_topic.alertas.arn]
  ok_actions          = [aws_sns_topic.alertas.arn]
}

# t4g con créditos "standard": si se agotan, la CPU queda limitada al 20%
resource "aws_cloudwatch_metric_alarm" "ec2_creditos" {
  alarm_name          = "tareas-ec2-creditos-cpu"
  alarm_description   = "Quedan pocos créditos de CPU: la EC2 se pondrá lenta pronto"
  namespace           = "AWS/EC2"
  metric_name         = "CPUCreditBalance"
  dimensions          = { InstanceId = aws_instance.backend.id }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 3
  comparison_operator = "LessThanThreshold"
  threshold           = 50
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.alertas.arn]
  ok_actions          = [aws_sns_topic.alertas.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_errores" {
  for_each = local.lambdas

  alarm_name          = "${each.key}-errores"
  alarm_description   = "La Lambda ${each.key} falló. Revisa /aws/lambda/${each.key}"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = each.key }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alertas.arn]
  ok_actions          = [aws_sns_topic.alertas.arn]
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "tareas-comentarios-api-5xx"
  alarm_description   = "El API de comentarios respondió errores 5xx"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5xx"
  dimensions          = { ApiId = local.api_comentarios_id }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alertas.arn]
  ok_actions          = [aws_sns_topic.alertas.arn]
}

# ------------------------------------------------------------
# Dashboard: todo el sistema en una pantalla
# ------------------------------------------------------------
locals {
  # Cada gráfico: título, posición (x, y) y métricas
  graficos = [
    {
      titulo = "Backend: errores en logs"
      x      = 0
      y      = 3
      ancho  = 8
      metricas = [
        ["Tareas", "BackendErrores", { stat = "Sum" }],
      ]
    },
    {
      titulo = "EC2: CPU (%) y créditos (eje derecho)"
      x      = 8
      y      = 3
      ancho  = 8
      metricas = [
        ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.backend.id, { stat = "Average" }],
        ["AWS/EC2", "CPUCreditBalance", "InstanceId", aws_instance.backend.id, { stat = "Minimum", yAxis = "right" }],
      ]
    },
    {
      titulo = "Aurora: capacidad (ACU)"
      x      = 16
      y      = 3
      ancho  = 8
      metricas = [
        ["AWS/RDS", "ServerlessDatabaseCapacity", "DBClusterIdentifier", aws_rds_cluster.tareas.cluster_identifier, { stat = "Maximum" }],
      ]
    },
    {
      titulo = "Lambdas: invocaciones y errores"
      x      = 0
      y      = 9
      ancho  = 12
      metricas = concat(
        [for f in local.lambdas : ["AWS/Lambda", "Invocations", "FunctionName", f, { stat = "Sum" }]],
        [for f in local.lambdas : ["AWS/Lambda", "Errors", "FunctionName", f, { stat = "Sum" }]],
      )
    },
    {
      titulo = "API comentarios: peticiones, 4xx y 5xx"
      x      = 12
      y      = 9
      ancho  = 12
      metricas = [
        ["AWS/ApiGateway", "Count", "ApiId", local.api_comentarios_id, { stat = "Sum" }],
        ["AWS/ApiGateway", "4xx", "ApiId", local.api_comentarios_id, { stat = "Sum" }],
        ["AWS/ApiGateway", "5xx", "ApiId", local.api_comentarios_id, { stat = "Sum" }],
      ]
    },
  ]

  alarmas = concat(
    [
      aws_cloudwatch_metric_alarm.backend_errores.arn,
      aws_cloudwatch_metric_alarm.ec2_status.arn,
      aws_cloudwatch_metric_alarm.ec2_creditos.arn,
      aws_cloudwatch_metric_alarm.api_5xx.arn,
    ],
    [for a in aws_cloudwatch_metric_alarm.lambda_errores : a.arn],
  )
}

resource "aws_cloudwatch_dashboard" "tareas" {
  dashboard_name = "tareas"
  dashboard_body = jsonencode({
    widgets = concat(
      [{
        type       = "alarm"
        x          = 0
        y          = 0
        width      = 24
        height     = 3
        properties = { title = "Alarmas", alarms = local.alarmas }
      }],
      [for g in local.graficos : {
        type   = "metric"
        x      = g.x
        y      = g.y
        width  = g.ancho
        height = 6
        properties = {
          title   = g.titulo
          region  = var.region
          period  = 300
          view    = "timeSeries"
          metrics = g.metricas
        }
      }],
    )
  })
}
