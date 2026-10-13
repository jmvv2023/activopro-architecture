---
id: 0002
title: MySQL sigue siendo el motor y la fuente de verdad del núcleo; no se migra a Supabase
status: accepted
date: 2026-10-07
services: [core, verifactu, docgenerator]
supersedes: null
superseded_by: null
---

## Contexto

Se valoró mover el backend MySQL del núcleo a Supabase/Postgres. Hay ~160 schemas en
producción y GeneXus genera SQL específico de MySQL.

## Opciones consideradas

1. **Migrar el núcleo a Supabase/Postgres.** Alto riesgo y coste; afecta a todo el SQL generado.
2. **Mantener MySQL** y usar Supabase solo donde aporte (nuevo ActivoPro, reporting).

## Decisión

Se mantiene MySQL 8 como motor del núcleo y como fuente de verdad de los datos de negocio.
En ms-verifactu, MySQL es la fuente de verdad de la cadena de huellas.

## Consecuencias

- Supabase queda para el nuevo ActivoPro, reporting y, en VeriFactu, como Rule Store y monitor;
  nunca como fuente de verdad de la cadena (ADR-0004).
- Cualquier micro que necesite datos del núcleo los lee/escribe en MySQL del tenant.

## Origen

Conversaciones sobre ms-pdf-service / almacenamiento (oct 2026) y ms-verifactu (sep 2026).
