---
id: 0026
title: La plataforma vive en el proyecto Supabase `activopro`, schema `activopro_platform`
status: accepted
date: 2026-11-05
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

La plataforma (`activopro-platform`) solo existía en Postgres local. Para ver el progreso desde el front hace falta una
base compartida con el login de Supabase Auth que ya usa el front.

- La organización `eNumbers` está en el plan gratuito, con el límite de 2 proyectos ya ocupado (`activopro` y
  `activopro-ms`): no se puede crear un proyecto nuevo sin cambiar de plan.
- El proyecto `activopro` ya tiene Auth (los usuarios del front) y objetos del ActivoPro nuevo anterior a la plataforma:
  29 tablas y 116 funciones en `public` y los schemas `activoprobase`, `activopro00000/1/2` y `activo0001`.
- Las migraciones de la plataforma creaban las tablas en `public` y las funciones en `app`.

## Decisión

1. **Proyecto.** La plataforma se instala en el proyecto Supabase `activopro`. Se aprovecha su Auth: los usuarios
   del front son los de la plataforma (`usuario.proveedor_sub` = uid de Supabase Auth).
2. **Schema propio.** Las tablas van en el schema `activopro_platform` (snake_case: un identificador con guion
   obliga a entrecomillar). Las funciones siguen en `app` y la carga de GeneXus en `etl`. En `public` no se crea nada.
3. **Sin Data API.** `activopro_platform` y `app` no se exponen por la API REST de Supabase. Se revoca todo a `anon`
   y `authenticated`. Solo se entra por el backend (ADR-0025), con su rol de login, que hereda `app_user` y tiene
   RLS forzada.
4. **`search_path` explícito.**
   - Toda función de `app` lleva `set search_path = activopro_platform, app`; la migración 25 lo fija en las que
     existían y el CLAUDE.md lo exige a las nuevas.
   - El backend lo fija en cada transacción (`set local search_path`); el ETL y la demo, al conectar.
   - No se depende del `search_path` por defecto de la base, que en Supabase es `"$user", public`.
5. **Rol del backend.** `plataforma_api` (login, miembro de `app_user`) se crea sin contraseña. La contraseña la pone
   José María en Supabase, nunca en Git ni en una sesión.
6. **Solo datos de demostración.** En el plan gratuito el proyecto se pausa por inactividad y no hay PITR. Al proyecto
   van solo las empresas de `scripts/demo.sql`. Las cargas de clientes (ETL de GeneXus, terceros) siguen en local hasta
   que haya un entorno con copias y región decididas.
7. **Retirada de lo anterior.** Los objetos antiguos de `public` y de los schemas `activopro*` se eliminan a medida
   que cada módulo pase a la plataforma, con su ADR o PR. No se tocan en esta decisión.

## Consecuencias

- El front entra con el login de siempre. Para ver el progreso basta con mirar `activopro_platform` en el panel de
  Supabase.
- Las migraciones se aplican en orden en el proyecto. Los nombres coinciden con los ficheros de `supabase/migrations/`.
- Una función nueva sin `search_path` fallaría en Supabase pero no en local. Por eso se hace el smoke test con el
  `search_path` por defecto de Supabase.
- El plan gratuito no vale para clientes reales. Antes de cargar uno habrá que decidir plan, región y copias (ADR-0013).
