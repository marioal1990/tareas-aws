# Nivel 2: Contenedores

Un "contenedor" en C4 es **algo que se ejecuta o almacena datos por separado**: una app web, una API, una función o una base de datos. No significa necesariamente un contenedor Docker.

```mermaid
flowchart TB
  usuario(("<b>Usuario</b><br/><small>[Persona]</small><br/><small>Navegador web</small>"))
  cognito["<b>Amazon Cognito</b><br/><small>[Sistema externo]</small><br/><small>User pool tareas-usuarios</small>"]

  subgraph sistema["Tareas AWS [Sistema]"]
    cdn["<b>CDN / Puerta de entrada</b><br/><small>[CloudFront]</small><br/><small>Un dominio HTTPS, enruta por ruta</small>"]
    spa["<b>Aplicación web</b><br/><small>[Angular 22 en S3]</small><br/><small>Login OIDC + PKCE, tareas y comentarios</small>"]

    subgraph tareasSvc["Servicio de tareas"]
      api["<b>API de tareas</b><br/><small>[Spring Boot 4.1 en Docker]</small><br/><small>REST /tareas-db/api/v1</small>"]
      db[("<b>Base de tareas</b><br/><small>[Aurora PostgreSQL 17]</small><br/><small>Auth IAM, escala a 0</small>")]
    end

    bus["<b>Bus de eventos</b><br/><small>[EventBridge]</small><br/><small>Regla TareaEliminada</small>"]

    subgraph comentariosSvc["Servicio de comentarios"]
      apigw["<b>API de comentarios</b><br/><small>[API Gateway HTTP API]</small><br/><small>Authorizer JWT</small>"]
      fnc["<b>Función comentarios</b><br/><small>[Lambda Java 21 + SnapStart]</small><br/><small>Listar, crear, borrar</small>"]
      fnl["<b>Función limpieza</b><br/><small>[Lambda Java 21]</small><br/><small>Borra comentarios huérfanos</small>"]
      ddb[("<b>Tabla de comentarios</b><br/><small>[DynamoDB]</small><br/><small>PK tareaId, SK comentarioId</small>")]
    end
  end

  usuario -- "Usa<br/>[HTTPS]" --> cdn
  usuario -- "Login<br/>[OIDC + PKCE]" --> cognito
  cdn -- "/*<br/>[S3 + OAC]" --> spa
  cdn -- "/tareas-db/*<br/>[HTTP :8888]" --> api
  cdn -- "/comentarios-api/*<br/>[HTTPS]" --> apigw
  api -- "Lee y escribe<br/>[JDBC, token IAM]" --> db
  api -- "TareaEliminada<br/>[PutEvents]" --> bus
  bus -- "Invoca<br/>[5 reintentos]" --> fnl
  apigw -- "Invoca" --> fnc
  fnc -- "Query / Put / Delete" --> ddb
  fnl -- "Query + BatchWrite" --> ddb
  api -. "JWKS" .-> cognito
  apigw -. "JWKS" .-> cognito

  class usuario persona
  class cdn,spa,api,db,bus,apigw,fnc,fnl,ddb contenedor
  class cognito externo
  class sistema,tareasSvc,comentariosSvc limite
  classDef persona fill:#08427b,stroke:#052e56,color:#fff
  classDef sistema fill:#1168bd,stroke:#0b4884,color:#fff
  classDef contenedor fill:#438dd5,stroke:#2e6295,color:#fff
  classDef componente fill:#85bbf0,stroke:#5d82a8,color:#000
  classDef externo fill:#999999,stroke:#6b6b6b,color:#fff
  classDef limite fill:none,stroke:#444,stroke-dasharray:6 4,color:#444
```

## Contenedores

| Contenedor | Tecnología | Código | Despliegue |
|---|---|---|---|
| CDN / Puerta de entrada | CloudFront + CloudFront Function `spa-rewrite` | `infra/cloudfront.tf` | Terraform |
| Aplicación web | Angular 22, angular-auth-oidc-client | `frontend/` | `deploy-frontend.yml` → S3 + invalidación |
| API de tareas | Spring Boot 4.1, JPA, Flyway, Spring Security | `backend/tareas-db/` | `deploy-backend.yml` → ECR → EC2 (Docker, vía SSM) |
| Base de tareas | Aurora PostgreSQL 17 (Express, IAM) | migraciones en `backend/.../db/migration` | CLI + import a Terraform |
| API de comentarios | API Gateway HTTP API + authorizer JWT | `serverless/comentarios/template.yaml` | `deploy-comentarios.yml` (SAM) |
| Función comentarios | Lambda Java 21 arm64 + SnapStart | `serverless/comentarios/function/` (`Handler`) | SAM |
| Función limpieza | Lambda Java 21 arm64 + SnapStart | `serverless/comentarios/function/` (`LimpiezaHandler`) | SAM |
| Tabla de comentarios | DynamoDB on-demand | `template.yaml` | SAM (`DeletionPolicy: Retain`) |
| Bus de eventos | EventBridge (bus `default`) | regla en `template.yaml` | SAM |

## Contratos entre contenedores

| Origen → destino | Contrato |
|---|---|
| SPA → API de tareas | REST JSON. Header `Authorization: Bearer <access token>`. Respuesta `{code, message, data}` |
| SPA → API de comentarios | REST JSON, mismo header y mismo formato de respuesta |
| API de tareas → EventBridge | `source: tareas-db`, `detail-type: TareaEliminada`, `detail: {"tareaId": <número>}`. Se publica **solo después del commit** |
| CloudFront → API de tareas | HTTP por el puerto 8888. El security group acepta solo la *prefix list* de CloudFront |

## Decisiones a este nivel

- **Dos estilos de cómputo a propósito:** la API de tareas es un servicio de larga vida (EC2 + Docker, con pool de conexiones a Aurora); los comentarios son serverless (Lambda + DynamoDB). Es parte del aprendizaje y muestra los compromisos de cada uno.
- **Una base de datos por servicio:** las tareas en PostgreSQL (relacional, con restricciones) y los comentarios en DynamoDB (llave-valor, acceso por `tareaId`). Ningún servicio lee la base del otro.
- **Integración asíncrona por eventos:** borrar una tarea no llama a la API de comentarios. Publica un evento, y el servicio de comentarios reacciona. Si la limpieza falla, el usuario no recibe un error.
- **Un solo dominio en CloudFront:** evita CORS y concentra TLS, caché y rutas en un solo lugar.
