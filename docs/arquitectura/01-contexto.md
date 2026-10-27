# Nivel 1: Contexto del sistema

Este nivel muestra **quién usa el sistema y con qué sistemas externos se relaciona**, sin detalles técnicos internos.

```mermaid
flowchart TB
  usuario(("<b>Usuario</b><br/><small>[Persona]</small><br/><small>Gestiona sus tareas y comentarios</small>"))
  dev(("<b>Desarrollador</b><br/><small>[Persona]</small><br/><small>Mantiene código e infraestructura</small>"))
  tareas["<b>Tareas AWS</b><br/><small>[Sistema]</small><br/><small>Tareas por usuario con comentarios</small>"]
  cognito["<b>Amazon Cognito</b><br/><small>[Sistema externo]</small><br/><small>Login y tokens JWT</small>"]
  github["<b>GitHub</b><br/><small>[Sistema externo]</small><br/><small>Código y CI/CD</small>"]
  email["<b>Email</b><br/><small>[Sistema externo]</small><br/><small>Recibe alarmas</small>"]

  usuario -- "Gestiona tareas<br/>[HTTPS]" --> tareas
  usuario -- "Inicia sesión<br/>[OIDC]" --> cognito
  tareas -- "Valida tokens<br/>[JWKS]" --> cognito
  dev -- "Push<br/>[git]" --> github
  github -- "Construye y despliega<br/>[AWS API]" --> tareas
  tareas -- "Alarmas<br/>[SNS]" --> email

  class usuario,dev persona
  class tareas sistema
  class cognito,github,email externo
  classDef persona fill:#08427b,stroke:#052e56,color:#fff
  classDef sistema fill:#1168bd,stroke:#0b4884,color:#fff
  classDef contenedor fill:#438dd5,stroke:#2e6295,color:#fff
  classDef componente fill:#85bbf0,stroke:#5d82a8,color:#000
  classDef externo fill:#999999,stroke:#6b6b6b,color:#fff
  classDef limite fill:none,stroke:#444,stroke-dasharray:6 4,color:#444
```

## Elementos

| Elemento | Tipo | Responsabilidad |
|---|---|---|
| **Usuario** | Persona | Usa la app web. Solo ve y modifica sus propias tareas y comentarios |
| **Desarrollador** | Persona | Escribe código, cambia la infraestructura (Terraform) y responde a las alarmas |
| **Tareas AWS** | Sistema (este) | Gestión de tareas por usuario, con comentarios |
| **Amazon Cognito** | Sistema externo | Identidad: user pool, página de login, tokens (access, id y refresh) |
| **GitHub** | Sistema externo | Código fuente y 4 pipelines (frontend, backend, comentarios, Terraform) |
| **Email** | Sistema externo | Destino de las alarmas (SNS) |

## Decisiones a este nivel

- **Identidad delegada en Cognito:** el sistema nunca ve contraseñas. Solo recibe y valida JWT firmados.
- **Un usuario = un `sub` de Cognito:** es la llave de autorización en todo el sistema (backend, comentarios y base de datos).
- **El despliegue lo hace GitHub, no una persona:** todo cambio a producción pasa por un pipeline. Terraform requiere además una aprobación manual (`aplicar=true`).
