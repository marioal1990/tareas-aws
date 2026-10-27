# Arquitectura de software (modelo C4)

Documentación de la arquitectura de **Tareas AWS** según el [modelo C4](https://c4model.com/), que describe el software en cuatro niveles de zoom, de lo general a lo particular:

| Nivel | Documento | Pregunta que responde | Para quién |
|---|---|---|---|
| 1. Contexto | [01-contexto.md](01-contexto.md) | ¿Qué es el sistema, quién lo usa y con qué se relaciona? | Cualquier persona |
| 2. Contenedores | [02-contenedores.md](02-contenedores.md) | ¿De qué piezas ejecutables se compone y cómo se comunican? | Desarrolladores y operación |
| 3. Componentes | [Aplicación web](03-componentes-frontend.md) · [API de tareas](03-componentes-backend.md) · [Comentarios](03-componentes-comentarios.md) | ¿Cómo está organizado el interior de cada contenedor? | Desarrolladores |
| Despliegue | [04-despliegue.md](04-despliegue.md) | ¿Dónde corre cada pieza en AWS y cómo llega a producción? | Operación |
| Dinámicos | [05-dinamicos.md](05-dinamicos.md) | ¿Qué pasa, paso a paso, en los escenarios clave? | Desarrolladores |

El nivel 4 (código) no se documenta aparte: la estructura de clases está en el código y en las tablas del nivel 3.

## Notación

- **Persona:** quien usa el sistema.
- **Sistema:** el software que se documenta. *Sistema externo:* uno con el que se integra, pero que no se controla (Cognito, GitHub).
- **Contenedor:** algo que se ejecuta o almacena datos por separado (la SPA, la API, una Lambda, una base de datos). No significa "contenedor Docker".
- **Componente:** una agrupación de código dentro de un contenedor (un controller, un servicio, un repositorio).
- **Flechas:** dependencia o flujo de datos, con la tecnología o el protocolo cuando aporta.

## Cómo ver los diagramas

- **GitHub** muestra los bloques ` ```mermaid ` directamente.
- **IntelliJ:** instala el plugin *Mermaid* y abre el `.md` en vista previa.
- **Exportar a imagen:** `npx -p @mermaid-js/mermaid-cli mmdc -i 02-contenedores.md -o 02-contenedores.svg`
- Los diagramas usan `flowchart` de Mermaid con la paleta de C4, porque el formato `C4Container` de Mermaid acomoda mal los elementos:

  | Color | Elemento C4 |
  |---|---|
  | Azul oscuro, círculo | Persona |
  | Azul medio | Sistema / contenedor (cilindro = almacén de datos) |
  | Celeste | Componente |
  | Gris | Sistema externo |
  | Borde punteado | Límite (sistema, contenedor o nodo de despliegue) |

## Cómo mantenerlos

Actualiza el diagrama en el mismo commit que el cambio de arquitectura:

| Si cambias… | Actualiza |
|---|---|
| Un servicio de AWS nuevo o eliminado, o un nuevo flujo entre servicios | Nivel 2 y despliegue |
| Una clase o paquete principal del backend, la Lambda o Angular | Nivel 3 del contenedor correspondiente |
| Recursos de Terraform o SAM, o permisos IAM | Despliegue |
| Un flujo de negocio (eventos, autenticación) | Dinámicos |
