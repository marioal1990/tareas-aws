# Diagramas dinámicos

Escenarios clave en orden temporal. Se usan diagramas de secuencia, que se leen mejor que el formato `C4Dynamic` cuando hay muchos pasos.

## 1. Inicio de sesión (Authorization Code + PKCE)

```mermaid
sequenceDiagram
    autonumber
    actor U as Usuario
    participant SPA as Aplicación web
    participant COG as Cognito
    U->>SPA: Abre la app y pulsa "Iniciar sesión"
    SPA->>SPA: Genera code_verifier y code_challenge
    SPA->>COG: Redirige a /oauth2/authorize con code_challenge
    U->>COG: Ingresa email y contraseña
    COG-->>SPA: Redirige a la app con ?code=...
    SPA->>COG: POST /oauth2/token con code y code_verifier
    COG-->>SPA: access token, id token y refresh token
    Note over SPA: access e id token duran 60 min y el refresh 30 días.<br/>La renovación es automática 60 s antes del vencimiento
```

## 2. Crear una tarea

```mermaid
sequenceDiagram
    autonumber
    participant SPA as Aplicación web
    participant CF as CloudFront
    participant API as API de tareas
    participant DB as Aurora
    SPA->>CF: POST /tareas-db/api/v1/tareas con Bearer y titulo
    CF->>API: Reenvía por el puerto 8888
    API->>API: Valida el JWT (firma, iss, client_id, token_use)
    API->>DB: ¿existe (usuario_id, titulo)?
    alt Ya existe
        API-->>SPA: 409 El titulo de la tarea ya existe
    else No existe
        API->>DB: INSERT tarea con usuario_id = sub
        DB-->>API: id, creada_en
        API-->>SPA: 201 Tarea creada
    end
    Note over API,DB: Si Aurora estaba pausada, la primera conexión tarda unos 15 s
```

## 3. Borrar una tarea y limpiar sus comentarios (asíncrono)

```mermaid
sequenceDiagram
    autonumber
    participant SPA as Aplicación web
    participant API as API de tareas
    participant DB as Aurora
    participant EB as EventBridge
    participant FL as Lambda limpieza
    participant DDB as DynamoDB
    SPA->>API: DELETE /tareas-db/api/v1/tareas/42
    API->>DB: SELECT tarea WHERE id = 42 AND usuario_id = sub
    alt No existe o es de otro usuario
        API-->>SPA: 404
    else Es del usuario
        API->>DB: DELETE y COMMIT
        API->>EB: PutEvents TareaEliminada {tareaId: 42} (AFTER_COMMIT)
        API-->>SPA: 204
        EB->>FL: Invoca (hasta 5 reintentos en 1 hora)
        FL->>DDB: Query tareaId = 42, solo las llaves
        FL->>DDB: BatchWriteItem en lotes de 25, con reintentos
    end
    Note over API,EB: Si PutEvents falla, se registra un ERROR (alarma) pero el borrado ya ocurrió
```

## 4. Token vencido durante el uso

```mermaid
sequenceDiagram
    autonumber
    participant SPA as Aplicación web
    participant INT as sesionInterceptor
    participant API as API
    participant COG as Cognito
    SPA->>API: GET con un access token vencido
    API-->>INT: 401
    INT->>COG: forceRefreshSession con el refresh token
    alt Renovación correcta
        COG-->>INT: Nuevo access token
        INT->>API: Reintenta una sola vez con el token nuevo
        API-->>SPA: 200
    else Refresh token vencido o revocado
        INT->>SPA: SesionService.expirada() y logoffLocal()
        Note over SPA: Muestra "Tu sesión expiró"
    end
```

## 5. Despliegue del backend

```mermaid
sequenceDiagram
    autonumber
    participant GH as GitHub Actions
    participant ECR as ECR
    participant SSM as SSM
    participant EC2 as EC2 (Docker)
    participant CW as CloudWatch
    GH->>GH: mvnw verify con Postgres 17
    GH->>ECR: buildx linux/arm64, push con tag del commit
    GH->>SSM: send-command con deploy-contenedor.sh
    SSM->>EC2: Ejecuta el script como root
    EC2->>ECR: docker login y pull
    EC2->>EC2: Detiene la versión actual y la renombra a -anterior
    EC2->>EC2: docker run con la nueva imagen
    EC2->>CW: Logs vía driver awslogs
    loop Hasta unos 3 minutos
        EC2->>EC2: curl /tareas-db/api/health
    end
    alt Responde
        EC2->>EC2: Borra la versión anterior y prune
        GH->>GH: Smoke test por CloudFront (200 y 401)
    else No responde
        EC2->>EC2: Muestra los logs y restaura la versión anterior
        SSM-->>GH: Failed
    end
```
