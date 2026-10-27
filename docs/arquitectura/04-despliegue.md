# Diagrama de despliegue

Muestra **dónde corre cada contenedor** en la infraestructura de AWS (región `us-east-2`) y cómo llega a producción.

```mermaid
flowchart TB
  subgraph nav["Navegador del usuario"]
    spaCliente["<b>Aplicación web</b><br/><small>[Angular]</small>"]
  end

  subgraph aws["AWS us-east-2 · plan Free · Organization con SCP"]
    subgraph edge["CloudFront (edge global)"]
      cdn["<b>CDN</b><br/><small>[CloudFront + OAC + spa-rewrite]</small>"]
    end
    subgraph s3["S3 · tareas-frontend (privado)"]
      estaticos["<b>Archivos de Angular</b><br/><small>[HTML, JS, CSS]</small>"]
    end
    subgraph vpc["VPC por defecto · SG: 22 desde IP admin, 8888 desde CloudFront"]
      subgraph ec2["EC2 t4g.small · AL2023 · Elastic IP"]
        subgraph docker["Docker · restart unless-stopped · 1 GB · awslogs"]
          api["<b>API de tareas</b><br/><small>[Spring Boot, Corretto 21]</small><br/><small>:8888</small>"]
        end
      end
    end
    subgraph rds["Aurora Serverless v2 Express · sin VPC · 0–1 ACU"]
      db[("<b>tareas-db</b><br/><small>[PostgreSQL 17]</small>")]
    end
    subgraph sam["Stack SAM comentarios-api"]
      apigw["<b>HTTP API</b><br/><small>[API Gateway]</small>"]
      fn["<b>Lambdas</b><br/><small>[Java 21 arm64, SnapStart]</small>"]
      ddb[("<b>tareas-comentarios</b><br/><small>[DynamoDB, PITR]</small>")]
    end
    subgraph ecr["ECR · tareas-db · tags inmutables"]
      imagen["<b>Imagen del backend</b><br/><small>[linux/arm64]</small>"]
    end
    cw["<b>CloudWatch + SNS</b><br/><small>[Logs, alarmas, dashboard]</small>"]
  end

  spaCliente -- "HTTPS" --> cdn
  cdn -- "OAC" --> estaticos
  cdn -- "HTTP 8888" --> api
  cdn -- "HTTPS" --> apigw
  api -- "TLS + token IAM" --> db
  apigw --> fn --> ddb
  imagen -. "docker pull vía SSM" .-> api
  api -. "logs" .-> cw

  class spaCliente,cdn,estaticos,api,db,apigw,fn,ddb,imagen contenedor
  class cw externo
  class nav,aws,edge,s3,vpc,ec2,docker,rds,sam,ecr limite
  classDef persona fill:#08427b,stroke:#052e56,color:#fff
  classDef sistema fill:#1168bd,stroke:#0b4884,color:#fff
  classDef contenedor fill:#438dd5,stroke:#2e6295,color:#fff
  classDef componente fill:#85bbf0,stroke:#5d82a8,color:#000
  classDef externo fill:#999999,stroke:#6b6b6b,color:#fff
  classDef limite fill:none,stroke:#444,stroke-dasharray:6 4,color:#444
```

## Infraestructura por nodo

| Nodo | Recurso | Definido en |
|---|---|---|
| CloudFront | `aws_cloudfront_distribution.app`, OAC, `spa-rewrite` | `infra/cloudfront.tf` |
| S3 | `tareas-frontend-mario-2026` | `infra/s3.tf` |
| EC2 | `aws_instance.backend` + Elastic IP + security group + rol `tareas-backend-ec2` | `infra/ec2.tf`, `infra/iam.tf` |
| Aurora | `aws_rds_cluster.tareas` + `tareas_1` | `infra/aurora.tf` (creado por CLI e importado) |
| ECR | `aws_ecr_repository.backend` | `infra/ecr.tf` |
| API Gateway, Lambdas, DynamoDB, regla EventBridge | Stack `comentarios-api` | `serverless/comentarios/template.yaml` |
| Cognito | User pool, cliente `tareas-angular`, dominio de login | `infra/cognito.tf` |
| Observabilidad | Log group, 6 alarmas, SNS, dashboard | `infra/observabilidad.tf` |

## Pipeline de entrega

```mermaid
flowchart LR
    dev[Push a master] --> gh{GitHub Actions}
    gh -->|frontend/**| f1[ng build] --> f2[S3 sync] --> f3[Invalidar CloudFront]
    gh -->|backend/**| b1[Tests con Postgres 17] --> b2[Imagen arm64 a ECR] --> b3[SSM: deploy-contenedor.sh] --> b4[Smoke test]
    gh -->|serverless/**| s1[sam validate y build] --> s2[sam deploy con rol CFN] --> s3[Smoke test]
    gh -->|infra/**| t1[terraform plan] -.Run workflow con aplicar=true.-> t2[terraform apply]
```

## Identidades y permisos

| Identidad | Tipo | Puede |
|---|---|---|
| `tareas-backend-ec2` | Rol de la EC2 | `rds-db:connect` como `tareas_app`, `events:PutEvents`, descargar de ECR, escribir logs, SSM |
| Roles de las Lambdas | Roles creados por SAM | CRUD solo sobre `tareas-comentarios` |
| `comentarios-cfn-exec` | Rol de CloudFormation | Crear y actualizar el stack de SAM (permisos acotados por prefijo) |
| `github-deploy` | Usuario IAM (access keys) | S3 del frontend, invalidar CloudFront, push a ECR, `ssm:SendCommand` a la EC2, desplegar el stack de SAM |
| `github-terraform-plan` | Usuario IAM | `ReadOnlyAccess` + state |
| `github-terraform-apply` | Usuario IAM | `AdministratorAccess`, solo en ejecuciones manuales |
