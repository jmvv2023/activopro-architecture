---
id: 0005
title: Documentos fuera de MySQL — MinIO self-hosted y no archivar PDFs regenerables con VeriFactu
status: superseded
date: 2026-10-07
services: [core, docgenerator]
supersedes: null
superseded_by: '0057'
---

> **Sustituido por [ADR-0057](0057-documentos-adjuntos.md) (21/11/2026).** Los documentos de los clientes no se sacan de MySQL a
> un MinIO junto al programa anterior: van al archivo de la plataforma nueva (Supabase Storage, ADR-0046) y los adjuntos de
> `adjmovctas`, `facturasadjuntos` y `activofijoactdoc` se cargan allí en la migración de cada cliente. Mientras tanto el programa
> anterior se queda como está (no se toca `print_attach`): el «Frente A» no se hace, y la plataforma ya sigue ese criterio al
> no guardar los PDF que puede regenerar (solo la copia de lo enviado, ADR-0046). Se conserva el texto original abajo.

## Contexto

`adjmovctas` guarda PDFs como `longblob` (~23 GB entre todos los tenants). Todos los schemas
comparten servidor MySQL (buffer pool) y JVM de Tomcat. En Torro, ~98,6 % de los blobs son PDFs
de factura propia regenerables y ~1.000 son adjuntos de usuario no regenerables.

## Opciones consideradas

1. Seguir en MySQL. Penaliza backups, buffer pool y crecimiento.
2. Object storage gestionado (S3, Wasabi…). Coste bajo pero externo.
3. **MinIO self-hosted en IONOS.** Coste cero adicional, API S3, disco disponible.

## Decisión

- MinIO self-hosted en IONOS para documentos no regenerables. `adjmovctas` guardaría solo la ruta.
- (Propuesto) **Frente A:** `print_attach` deja de archivar el PDF cuando el tenant tiene
  VeriFactu activo, porque huella + XML + QR garantizan la inmutabilidad y el PDF se regenera igual.
- No se borra histórico: las copias anteriores a VeriFactu son la foto del documento tal como
  se contabilizó.

## Consecuencias

- Torro no necesita MinIO como bloqueante de su migración.
- `FACSTILO` vacío para Torro/Vidalpons hasta que el docgenerator soporte columnas de trazabilidad por lote.

## Origen

Conversación "ms-pdf-service" (oct 2026).
