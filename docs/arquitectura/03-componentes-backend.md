# Nivel 3: Componentes de la API de tareas

Contenedor: **API de tareas** (`backend/tareas-db`, Spring Boot 4.1, paquete `cl.backend.tareas_db`).

```mermaid
flowchart TB
  cdn["<b>CloudFront</b><br/><small>[Contenedor]</small><br/><small>Reenvía /tareas-db/*</small>"]
  cognito["<b>Amazon Cognito</b><br/><small>[Sistema externo]</small><br/><small>JWKS</small>"]

  subgraph api["API de tareas [Spring Boot]"]
    security["<b>Seguridad</b><br/><small>[SecurityConfig, OAuth2 Resource Server]</small><br/><small>Valida firma, iss, client_id, token_use</small>"]
    controller["<b>TareaController</b><br/><small>[@RestController]</small><br/><small>/api/v1/tareas, toma el sub del JWT</small>"]
    errores["<b>GlobalExceptionHandler</b><br/><small>[@RestControllerAdvice]</small><br/><small>400, 404, 409, 500</small>"]
    service["<b>TareaService</b><br/><small>[@Service @Transactional]</small><br/><small>Reglas: título único por usuario, 404 si es ajena</small>"]
    repo["<b>TareaRepository</b><br/><small>[Spring Data JPA]</small><br/><small>JPQL filtrado por usuarioId</small>"]
    publisher["<b>TareaEventosPublisher</b><br/><small>[@TransactionalEventListener]</small><br/><small>AFTER_COMMIT</small>"]
    flyway["<b>Migraciones</b><br/><small>[Flyway]</small><br/><small>V1 a V5 al arrancar</small>"]
    health["<b>Health y Swagger</b><br/><small>[Actuator, springdoc]</small><br/><small>Públicos</small>"]
  end

  db[("<b>Base de tareas</b><br/><small>[Aurora PostgreSQL]</small><br/><small>Tabla tarea</small>")]
  bus["<b>EventBridge</b><br/><small>[Contenedor]</small><br/><small>Bus default</small>"]

  cdn -- "HTTP + Bearer JWT" --> security
  security -. "Llaves públicas" .-> cognito
  security --> controller
  controller -- "usuarioId + datos" --> service
  controller -. "Excepciones" .-> errores
  service --> repo
  service -- "TareaEliminadaEvent" --> publisher
  repo -- "SQL<br/>[JDBC wrapper IAM, Hikari]" --> db
  flyway -- "DDL" --> db
  publisher -- "PutEvents<br/>[AWS SDK v2]" --> bus

  class security,controller,errores,service,repo,publisher,flyway,health componente
  class cdn,db,bus contenedor
  class cognito externo
  class api limite
  classDef persona fill:#08427b,stroke:#052e56,color:#fff
  classDef sistema fill:#1168bd,stroke:#0b4884,color:#fff
  classDef contenedor fill:#438dd5,stroke:#2e6295,color:#fff
  classDef componente fill:#85bbf0,stroke:#5d82a8,color:#000
  classDef externo fill:#999999,stroke:#6b6b6b,color:#fff
  classDef limite fill:none,stroke:#444,stroke-dasharray:6 4,color:#444
```

## Componentes

| Componente | Clase / paquete | Responsabilidad |
|---|---|---|
| Seguridad | `config.SecurityConfig` | Cadena de filtros sin estado ni CSRF. Rutas públicas: `OPTIONS`, `/api/health`, Swagger. `JwtDecoder` con 3 validadores |
| TareaController | `controller.TareaController` | `GET` listar / `findById` / `findByTitulo` / `findByCompletada`, `POST` crear (201), `PATCH /{id}/completada`, `DELETE /{id}` (204) |
| TareaService | `service.TareaService` | Cada método recibe el `usuarioId`. Las tareas ajenas responden 404, no 403, para no revelar que existen. El dueño sale del token, nunca del body |
| TareaRepository | `repository.TareaRepository` | `findAllDto`, `findByTitulo`, `findByCompletada` (con `Slice`), `findByIdAndUsuarioId`, `existsByUsuarioIdAndTitulo` |
| Modelo | `model.entity.Tarea`, `model.dto.TareaDTO`, `util.ParseoUtil` | La entidad tiene `usuarioId`. El DTO no lo expone |
| TareaEventosPublisher | `evento.TareaEventosPublisher` | Solo existe si `eventos.habilitados=true` (perfil `aws`). Publica después del commit; si falla, lo registra y no afecta al usuario |
| GlobalExceptionHandler | `exception.*` | `ResourceNotFoundException` → 404, `DuplicateResourceException` → 409, validación → 400 |
| Migraciones | `resources/db/migration` | `ddl-auto=validate`: Hibernate solo verifica; los cambios de esquema van siempre en migraciones |

## Flujo de una petición

1. `GET /tareas-db/api/v1/tareas` llega por CloudFront con `Authorization: Bearer ...`.
2. **Seguridad** valida el JWT (las llaves se descargan en la primera petición y luego quedan en caché).
3. **TareaController** recibe `@AuthenticationPrincipal Jwt` y pasa `jwt.getSubject()` al servicio.
4. **TareaService** delega en el repositorio dentro de una transacción de solo lectura.
5. **TareaRepository** ejecuta `... WHERE t.usuarioId = :usuarioId` y devuelve un `Slice<TareaDTO>`.
6. El controller lo envuelve en `ControllerResponse { code, message, data: PageResponse }`.

## Configuración por perfil

| Aspecto | Por defecto (local / CI) | Perfil `aws` |
|---|---|---|
| Conexión | `jdbc:postgresql`, usuario y contraseña (`DB_*`) | `jdbc:aws-wrapper` + plugin IAM (`RDS_DB_*`), sin contraseña |
| Pool Hikari | 2–10 conexiones | 0–5, se vacía a los 60 s para que Aurora pueda pausarse |
| Eventos | Desactivados | `eventos.habilitados=true` |
