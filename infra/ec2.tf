# ============================================================
# EC2 del backend (Spring Boot) + red
# Importado desde recursos existentes (ver Parte 7D)
# ============================================================

variable "ip_admin_ssh" {
  description = "IP pública desde donde se permite SSH (tu casa). Actualízala si tu proveedor la cambia"
  type        = string
  default     = "181.42.188.88/32"
}

# VPC por defecto de la región
data "aws_vpc" "default" {
  default = true
}

# Lista oficial de IPs de CloudFront que AWS mantiene actualizada
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ------------------------------------------------------------
# Security group: SSH solo desde tu IP, 8888 solo desde CloudFront
# ------------------------------------------------------------
resource "aws_security_group" "backend" {
  name        = "tareas-backend-sg"
  description = "Backend Spring Boot tareas-db" # cambiarla obliga a recrear el SG
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = ""
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.ip_admin_ssh]
  }

  ingress {
    description     = "CloudFront"
    protocol        = "tcp"
    from_port       = 8888
    to_port         = 8888
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    description = ""
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------
# Instancia
# ------------------------------------------------------------
resource "aws_instance" "backend" {
  ami                         = "ami-0dc1b24288e1849b8" # Amazon Linux 2023 arm64
  instance_type               = "t4g.small"
  subnet_id                   = "subnet-0ba394fa227191e9d"
  vpc_security_group_ids      = [aws_security_group.backend.id]
  iam_instance_profile        = aws_iam_instance_profile.backend_ec2.name
  key_name                    = "tareas-key" # el key pair no se gestiona con Terraform
  associate_public_ip_address = true

  ebs_optimized                        = true
  monitoring                           = false
  disable_api_stop                     = false
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  source_dest_check                    = true
  tenancy                              = "default"

  credit_specification {
    cpu_credits = "unlimited"
  }

  # IMDSv2 obligatorio (más seguro); hop limit 2 por compatibilidad con contenedores
  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    iops                  = 3000
    throughput            = 125
    encrypted             = false
    delete_on_termination = true
  }

  tags = {
    Name = "tareas-backend"
  }

  lifecycle {
    # Recrear la instancia borraría Java, el servicio systemd, app.env y deploy.sh
    prevent_destroy = true
    # Una AMI nueva no debe provocar el reemplazo de una instancia ya configurada
    ignore_changes = [ami, user_data]
  }
}

# ------------------------------------------------------------
# Elastic IP: dirección fija para que CloudFront encuentre la EC2
# ------------------------------------------------------------
resource "aws_eip" "backend" {
  domain = "vpc"

  tags = {
    Name = "tareas-backend-eip"
  }
}

resource "aws_eip_association" "backend" {
  allocation_id = aws_eip.backend.id
  instance_id   = aws_instance.backend.id
}
