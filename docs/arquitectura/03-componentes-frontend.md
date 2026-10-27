# Nivel 3: Componentes de la aplicación web

Contenedor: **Aplicación web** (`frontend/`, Angular 22 standalone con signals).

```mermaid
flowchart TB
  usuario(("<b>Usuario</b><br/><small>[Persona]</small>"))

  subgraph spa["Aplicación web [Angular 22]"]
    app["<b>App</b><br/><small>[Componente raíz]</small><br/><small>Login, listado paginado, crear, completar, borrar</small>"]
    comentarios["<b>Comentarios</b><br/><small>[Componente]</small><br/><small>Comentarios de una tarea</small>"]
    tareaSvc["<b>TareaService</b><br/><small>[Servicio HttpClient]</small>"]
    comentarioSvc["<b>ComentarioService</b><br/><small>[Servicio HttpClient]</small>"]
    oidc["<b>Autenticación OIDC</b><br/><small>[angular-auth-oidc-client]</small><br/><small>Code + PKCE, refresh, agrega el Bearer</small>"]
    sesionInt["<b>sesionInterceptor</b><br/><small>[HttpInterceptorFn]</small><br/><small>401: renueva y reintenta una vez</small>"]
    sesionSvc["<b>SesionService</b><br/><small>[Servicio con signal]</small><br/><small>Aviso de sesión expirada</small>"]
  end

  cognito["<b>Amazon Cognito</b><br/><small>[Sistema externo]</small>"]
  api["<b>API de tareas</b><br/><small>[Spring Boot]</small><br/><small>/tareas-db/api/v1</small>"]
  apigw["<b>API de comentarios</b><br/><small>[API Gateway]</small><br/><small>/comentarios-api</small>"]

  usuario --> app
  app -- "input tareaId" --> comentarios
  app --> tareaSvc
  app -- "checkAuth, authorize, logoff" --> oidc
  comentarios --> comentarioSvc
  tareaSvc -- "JSON + Bearer" --> api
  comentarioSvc -- "JSON + Bearer" --> apigw
  oidc -- "authorize / token<br/>[OIDC + PKCE]" --> cognito
  sesionInt -- "forceRefreshSession" --> oidc
  sesionInt -- "expirada()" --> sesionSvc

  class usuario persona
  class app,comentarios,tareaSvc,comentarioSvc,oidc,sesionInt,sesionSvc componente
  class api,apigw contenedor
  class cognito externo
  class spa limite
  classDef persona fill:#08427b,stroke:#052e56,color:#fff
  classDef sistema fill:#1168bd,stroke:#0b4884,color:#fff
  classDef contenedor fill:#438dd5,stroke:#2e6295,color:#fff
  classDef componente fill:#85bbf0,stroke:#5d82a8,color:#000
  classDef externo fill:#999999,stroke:#6b6b6b,color:#fff
  classDef limite fill:none,stroke:#444,stroke-dasharray:6 4,color:#444
```

## Componentes

| Componente | Archivo | Responsabilidad |
|---|---|---|
| `App` | `app.ts`, `app.html` | Estado con signals (`tareas`, `pagina`, `hayMas`, `error`, `comentariosAbiertos`). Muestra un solo panel de comentarios a la vez |
| `Comentarios` | `comentarios/` | Recibe `tareaId` y gestiona los comentarios de esa tarea |
| `TareaService` | `service/tarea.service.ts` | Lista paginada (orden `creadaEn,desc`), crear, `PATCH /completada`, borrar. Desempaqueta `ControllerResponse.data` |
| `ComentarioService` | `service/comentario.service.ts` | Listar, crear y borrar comentarios |
| Autenticación OIDC | `app.config.ts`, `auth.config.ts` | `responseType: code`, `useRefreshToken`, `silentRenew`, renovación 60 s antes del vencimiento, `secureRoutes` = solo las dos APIs |
| `sesionInterceptor` | `interceptor/` | Se ejecuta después de `authInterceptor`. Marca los reintentos con `HttpContextToken` para no entrar en un ciclo |
| `SesionService` | `service/sesion.service.ts` | Signal `aviso` que muestra la barra "Tu sesión expiró" |

## Decisiones

- **Rutas relativas (`/tareas-db`, `/comentarios-api`):** en producción las resuelve CloudFront y en desarrollo `proxy.conf.json`. El código no cambia entre entornos.
- **El token solo va a las APIs propias** (`secureRoutes`), nunca a terceros.
- **Sin backend-for-frontend:** la SPA es un cliente público (sin client secret), por eso usa PKCE.
