---
id: 0001
title: Micros en repos independientes y documentación transversal en un repo central privado
status: accepted
date: 2026-10-13
services: [all]
supersedes: null
superseded_by: null
---

## Contexto

El conocimiento técnico estaba disperso en conversaciones. Para que cualquier sesión (incluidas
sesiones autónomas de Claude) tenga contexto sin reexplicarlo, tiene que vivir en Git junto al
código. Los micros son, en principio, independientes entre sí. El monorepo existente contiene
el manual y las webs públicas.

## Opciones consideradas

1. **Base de datos de conocimiento.** Más consultable, pero desacoplada del código, sin diff
   en los PR y requiere intermediario para que un agente la lea.
2. **Todo en el monorepo público.** Riesgo de publicar información interna; contexto
   contaminado para tareas del manual o las webs.
3. **Repos por micro + repo central privado.** Contexto acotado por micro, permisos acotados
   para sesiones autónomas, y un único sitio para lo transversal.

## Decisión

Opción 3. Cada micro mantiene `CLAUDE.md` y `docs/decisions/` en su repo. Lo transversal
(mapa, decisiones que afectan a varios micros o al núcleo, dominio fiscal, convenciones) vive
en `activopro-architecture`. Ficheros Markdown con frontmatter; una BD solo como índice
derivado si algún día hace falta.

Coherente con la decisión previa del nuevo ActivoPro: los micros existentes no entran en el
monorepo `activopro-platform`; los micros nuevos exclusivos del nuevo ActivoPro sí pueden.

## Consecuencias

- Los cambios que cruzan micros requieren varios PR. Si son frecuentes, el corte de micros
  está mal hecho.
- Cada `CLAUDE.md` de micro enlaza a este repo para el contexto global.

## Origen

Conversación del 13/10/2026 sobre organización del conocimiento.
