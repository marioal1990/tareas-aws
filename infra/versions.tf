terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "tareas-tfstate-mario-2026"
    key          = "tareas-aws/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true # bloqueo nativo en S3: dos "apply" no pueden correr a la vez
  }
}

provider "aws" {
  region = var.region
}