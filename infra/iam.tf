# ============================================================
# IAM: roles y permisos del proyecto
# ============================================================

# ------------------------------------------------------------
# Rol de la EC2 del backend (Spring Boot)
# ------------------------------------------------------------
resource "aws_iam_role" "backend_ec2" {
  name                  = "tareas-backend-ec2"
  path                  = "/"
  max_session_duration  = 3600
  force_detach_policies = false

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "backend_ec2" {
  name = aws_iam_role.backend_ec2.name
  path = "/"
  role = aws_iam_role.backend_ec2.name
}

# Conectarse a Aurora como "tareas_app" con token IAM
resource "aws_iam_role_policy" "backend_rds_connect" {
  name = "rds-connect"
  role = aws_iam_role.backend_ec2.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "rds-db:connect"
      Resource = "arn:aws:rds-db:${var.region}:${local.account_id}:dbuser:${aws_rds_cluster.tareas.cluster_resource_id}/tareas_app"
    }]
  })
}

# Descargar los JAR que sube el pipeline
resource "aws_iam_role_policy" "backend_artifacts_read" {
  name = "artifacts-read"
  role = aws_iam_role.backend_ec2.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.artifacts.arn}/backend/*"
    }]
  })
}

# Publicar el evento TareaEliminada en EventBridge
resource "aws_iam_role_policy" "backend_publicar_eventos" {
  name = "publicar-eventos"
  role = aws_iam_role.backend_ec2.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "events:PutEvents"
      Resource = "arn:aws:events:${var.region}:${local.account_id}:event-bus/default"
    }]
  })
}

# Recibir comandos de SSM (despliegue desde GitHub Actions)
resource "aws_iam_role_policy_attachment" "backend_ssm" {
  role       = aws_iam_role.backend_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ------------------------------------------------------------
# Rol de ejecución de CloudFormation para el stack de SAM
# ------------------------------------------------------------
resource "aws_iam_role" "cfn_exec" {
  name                  = "comentarios-cfn-exec"
  path                  = "/"
  max_session_duration  = 3600
  force_detach_policies = false

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudformation.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cfn_exec_deploy" {
  name = "deploy-comentarios"
  role = aws_iam_role.cfn_exec.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Lambda"
        Effect   = "Allow"
        Action   = "lambda:*"
        Resource = "arn:aws:lambda:${var.region}:${local.account_id}:function:tareas-comentarios*"
      },
      {
        Sid      = "ApiGateway"
        Effect   = "Allow"
        Action   = "apigateway:*"
        Resource = "arn:aws:apigateway:${var.region}::/*"
      },
      {
        Sid      = "DynamoDB"
        Effect   = "Allow"
        Action   = "dynamodb:*"
        Resource = "arn:aws:dynamodb:${var.region}:${local.account_id}:table/tareas-comentarios"
      },
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = "logs:*"
        Resource = "arn:aws:logs:${var.region}:${local.account_id}:log-group:/aws/lambda/tareas-comentarios*"
      },
      {
        Sid    = "RolDeLaLambda"
        Effect = "Allow"
        Action = [
          "iam:GetRole", "iam:CreateRole", "iam:DeleteRole", "iam:PassRole", "iam:TagRole", "iam:UntagRole",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
        ]
        Resource = "arn:aws:iam::${local.account_id}:role/${local.sam_stack}-*"
      },
      {
        Sid      = "CodigoSam"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${local.sam_bucket}/*"
      },
      {
        Sid      = "TransformSam"
        Effect   = "Allow"
        Action   = "cloudformation:CreateChangeSet"
        Resource = "arn:aws:cloudformation:${var.region}:aws:transform/Serverless-2016-10-31"
      },
      {
        Sid      = "EventBridge"
        Effect   = "Allow"
        Action   = "events:*"
        Resource = "arn:aws:events:${var.region}:${local.account_id}:rule/${local.sam_stack}-*"
      },
    ]
  })
}

# ------------------------------------------------------------
# Usuario técnico de GitHub Actions
# (sus access keys NO se gestionan con Terraform: quedarían en el state)
# ------------------------------------------------------------
resource "aws_iam_user" "github_deploy" {
  name = "github-deploy"
  path = "/"
}

# Pipeline del frontend: subir a S3 e invalidar CloudFront
resource "aws_iam_user_policy" "github_frontend" {
  name = "deploy-frontend"
  user = aws_iam_user.github_deploy.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.frontend.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetDistribution"]
        Resource = aws_cloudfront_distribution.app.arn
      },
    ]
  })
}

# Pipeline del backend: subir el JAR y desplegar vía SSM
resource "aws_iam_user_policy" "github_backend" {
  name = "deploy-backend"
  user = aws_iam_user.github_deploy.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.artifacts.arn}/backend/*"
      },
      {
        Effect = "Allow"
        Action = "ssm:SendCommand"
        Resource = [
          "arn:aws:ec2:${var.region}:${local.account_id}:instance/${aws_instance.backend.id}",
          "arn:aws:ssm:${var.region}::document/AWS-RunShellScript",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation", "ssm:ListCommandInvocations"]
        Resource = "*"
      },
    ]
  })
}

# Pipeline del microservicio: desplegar el stack de SAM
resource "aws_iam_user_policy" "github_comentarios" {
  name = "deploy-comentarios"
  user = aws_iam_user.github_deploy.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StackComentarios"
        Effect = "Allow"
        Action = [
          "cloudformation:CreateChangeSet", "cloudformation:ExecuteChangeSet", "cloudformation:DescribeChangeSet",
          "cloudformation:DeleteChangeSet", "cloudformation:DescribeStacks", "cloudformation:DescribeStackEvents",
          "cloudformation:GetTemplate", "cloudformation:ListStackResources",
        ]
        Resource = "arn:aws:cloudformation:${var.region}:${local.account_id}:stack/${local.sam_stack}/*"
      },
      {
        Sid      = "TransformSam"
        Effect   = "Allow"
        Action   = "cloudformation:CreateChangeSet"
        Resource = "arn:aws:cloudformation:${var.region}:aws:transform/Serverless-2016-10-31"
      },
      {
        Sid      = "Lectura"
        Effect   = "Allow"
        Action   = ["cloudformation:GetTemplateSummary", "cloudformation:ValidateTemplate"]
        Resource = "*"
      },
      {
        Sid      = "PasarRolCfn"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.cfn_exec.arn
      },
      {
        Sid      = "BucketSam"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = ["arn:aws:s3:::${local.sam_bucket}", "arn:aws:s3:::${local.sam_bucket}/*"]
      },
    ]
  })
}
