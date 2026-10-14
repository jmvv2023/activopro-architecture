---
id: 0004
title: La lógica nueva vive en micros; GeneXus actúa como capa de presentación
status: accepted
date: 2026-10-13
services: [core, verifactu, auth, einvoice]
supersedes: null
superseded_by: null
---

## Contexto

GeneXus 16 U8 tiene limitaciones fuertes: no hay `JsonReader`, `HttpClient` limitado, envía
ISO-8859-1, `Commit on exit` sobrescribe campos, recompilaciones que pierden propiedades.
Meter lógica nueva en GeneXus es caro y arriesgado.

## Decisión

La lógica nueva se implementa en micros. GeneXus queda como cliente/presentación. Cuando un
micro escribe en MySQL del núcleo, cada columna tiene un único escritor documentado en
`system-map.md`.

## Aplicaciones

- **ms-auth:** toda la lógica de recuperación de contraseña en el micro; GeneXus solo presenta.
- **ms-einvoice:** módulo fuera de GeneXus; integración por tabla outbox, sin HTTP dentro de
  transacciones GeneXus.
- **ms-ocr:** GeneXus llama y recoge; la extracción vive en el micro.
- **ms-verifactu:** el micro **es el SIF de VeriFactu de ActivoPro**. Gestiona huella, colas,
  reintentos y envío a la AEAT, y **escribe el resultado directamente en MySQL** del tenant,
  en su tabla propia `verifactu_registro`. GeneXus envía la petición y muestra los datos (con
  botón de refresco). Supabase **se mantiene** (corrección del 13/10/2026) como copia para el
  monitor de VeriFactu y por transversalidad con el nuevo ActivoPro; nunca como dependencia. La
  fuente de verdad de la cadena es MySQL.

## Por qué el micro escribe en MySQL (y no GeneXus)

La intención inicial era que GeneXus recibiera la respuesta del micro y escribiera él en MySQL.
No fue posible: GeneXus no fue capaz de gestionar correctamente la respuesta del micro
(limitaciones de parseo de GX16, `Commit on exit`, conflictos de transacción). Se aceptó que
escriba el micro como **primera versión**.

## Consecuencias y deuda asumida

- El micro escribe en su propia tabla `verifactu_registro`, no en `facturas`: así el micro y
  GeneXus no escriben nunca en la misma tabla.
- Supabase no puede parar la facturación: las reglas del registro (huella e identificación del
  SIF) están en el código del micro, y la copia para el monitor nunca bloquea (issue #8 del
  micro, 15/10/2026). El Rule Store de Supabase deja de usarse.
- **Mejora pendiente:** hacer el micro más independiente del esquema de ActivoPro (tablas
  propias / contrato estable) para que sea operativo también con la nueva plataforma, en la
  línea del modelo canónico de ms-einvoice.
- Las notas antiguas que describen un flujo síncrono con Rule Store en Supabase y el micro sin
  escribir en `facturas` corresponden a una etapa anterior y quedan sustituidas por esta decisión.

## Origen

Conversaciones de ms-auth (sep 2026), ms-verifactu (29/09/2026), SPFE (26/09/2026) y
confirmación de José María (13/10/2026).
