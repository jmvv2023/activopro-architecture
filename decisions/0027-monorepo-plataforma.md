---
id: 0027
title: Plataforma en un solo repositorio (monorepo con npm workspaces)
status: accepted
date: 2026-11-06
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

La plataforma vivía en dos repositorios:
- `jmvv2023/activopro-platform`: base de datos, API, generadores fiscales y ETL, todo colgando de la raíz. Había un `src/`
  que no era del front sino de la API.
- `jmvv2023/activopro`: el front.

Cada funcionalidad tocaba los dos a la vez. Las pantallas fiscales fueron PRs coordinados en cada repo, y el front repetía
a mano las formas de las respuestas de la API. No hay equipos distintos de front y back que justifiquen separarlos.

La preferencia por servicios autónomos se refiere a microservicios que no dependan unos de otros en ejecución. Front y API
son dos capas de un mismo producto: en ejecución el front depende de su API de todas formas, así que separarlos en dos
repos no les daba autonomía.

## Decisión

1. **Un repositorio**, `jmvv2023/activopro-platform` (mantiene el nombre), con npm workspaces:

   | Ruta | Paquete | Contenido |
   |---|---|---|
   | `supabase/migrations/` | — | esquema SQL. Se queda en la raíz porque es donde lo espera la CLI de Supabase |
   | `db/` | `@activopro/db` | tests de las reglas de la base, utilidades de test (`@activopro/db/testing`) y scripts (reinicio local, demo) |
   | `apps/api/` | `@activopro/api` | backend (ADR-0025) |
   | `apps/web/` | `@activopro/web` | front, traído de `jmvv2023/activopro` con su historial (`git subtree`) |
   | `packages/fiscal/` | `@activopro/fiscal` | ficheros y borradores AEAT/ATC; sin acceso a la base |
   | `etl/` | `@activopro/etl` | carga desde GeneXus y modo sombra |

2. **Imports entre workspaces por nombre de paquete** (`@activopro/fiscal/modelo303`), sin build intermedio: los paquetes
   exportan el código TypeScript. Nunca rutas relativas que salgan de un workspace.
3. **Tests junto al código que prueban.** Se ejecutan todos con `npm test` desde la raíz, en serie, porque comparten la
   base local.
4. **Despliegue independiente.** El front se construye desde la raíz (`docker build -f apps/web/Dockerfile .`) y se sirve
   como estáticos; la API, como contenedor. Estar en un repo no los acopla al desplegar.
5. **CI con dos trabajos:**
   - back: migraciones sobre un Postgres limpio, tipos y tests;
   - web: tipos y build de producción.
6. **Módulos antiguos del front.** Los que leen el modelo antiguo de Supabase (`public`) se mueven tal cual y se retiran a
   medida que cada módulo pase a la API, igual que los schemas viejos (ADR-0026).
7. **`jmvv2023/activopro` se archiva**, con un README que apunta aquí. Se borrará cuando toque.
8. **Los microservicios de alrededor** (verifactu, ocr, import…) siguen en sus repositorios.

## Consecuencias

- Un cambio que toca base, API y pantalla va en un solo PR.
- **Paquete de tipos del contrato.** El siguiente paso natural es un paquete con los tipos generados desde
  `GET /openapi.json`, para que el front no copie a mano las formas de las respuestas. Queda como tarea aparte.
- **Instalación compartida.** Una sola instalación y un lockfile en la raíz:
  - `legacy-peer-deps` (del front) pasa al `.npmrc` de la raíz y aplica a todos;
  - `vite` se fija en la raíz para que lo compartan vitest y el front.
- **Historial.** El PR que trae el front se integra con merge commit, no squash, para conservar el historial del front.
