---
id: 0004
title: La lógica nueva vive en micros; GeneXus actúa como capa de presentación
status: proposed
date: 2026-10-13
services: [core, verifactu, auth, einvoice]
supersedes: null
superseded_by: null
---

> **PENDIENTE DE CONFIRMAR.** El principio general está aplicado en varios micros, pero en
> ms-verifactu hay dos versiones del diseño en las notas y hay que fijar cuál es la vigente.
> Ver sección "Conflicto".

## Contexto

GeneXus 16 U8 tiene limitaciones fuertes: no hay `JsonReader`, `HttpClient` limitado, envía
ISO-8859-1, `Commit on exit` sobrescribe campos, recompilaciones que pierden propiedades.
Meter lógica nueva en GeneXus es caro y arriesgado.

## Aplicaciones ya hechas

- **ms-auth:** toda la lógica de recuperación de contraseña en el micro; GeneXus solo presenta.
- **ms-einvoice:** módulo fuera de GeneXus; integración por tabla outbox, sin HTTP dentro de
  transacciones GeneXus.
- **ms-ocr:** GeneXus llama y recoge; la extracción vive en el micro.

## Conflicto en ms-verifactu (decidir)

**Versión A — 29/09/2026 (conversación sobre Claude Code):** GeneXus envía la petición al MS; el MS
gestiona colas, reintentos y envío a la AEAT y **escribe el resultado directamente en MySQL**;
GeneXus muestra los datos con un botón de refresco. Supabase se elimina. Parte síncrona solo
para devolver huella y QR al momento.

**Versión B — notas del proyecto "micros", última actualización 02/10/2026:** flujo
**síncrono** (GeneXus espera ~2–3 s); el MS es el único SIF y guarda la cadena en
`verifactu_registro`; **descartado** que el MS actualice directamente la tabla `facturas`
("dos escritores en la misma tabla"); el Rule Store sigue en Supabase. Reintentos automáticos
como pendiente (job nocturno sobre `msFacVeriPendEnv=S`).

Posible lectura: B describe lo validado en preproducción y A es la evolución decidida después.
**José María: indicar cuál es la vigente** y, si es A, cómo se resuelve lo de los dos
escritores sobre `facturas` (¿el MS escribe solo en columnas `msFacVeri*` y `Fac*` de
VeriFactu y GeneXus deja de escribirlas?).

## Decisión (borrador)

La lógica nueva se implementa en micros. GeneXus queda como cliente/presentación. Cuando un
micro escribe en MySQL del núcleo, cada columna tiene un único escritor documentado en
`system-map.md`.

## Origen

Conversaciones de ms-auth (sep 2026), ms-verifactu (29/09/2026), SPFE (26/09/2026) y notas del
proyecto "micros".
