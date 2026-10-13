---
id: 0005
title: Documentos fuera de MySQL — MinIO self-hosted y no archivar PDFs regenerables con VeriFactu
status: proposed
date: 2026-10-07
services: [core, docgenerator]
supersedes: null
superseded_by: null
---

> **Parcialmente decidido.** MinIO self-hosted en IONOS frente a Supabase Storage o S3 externo
> está elegido. El "Frente A" (dejar de archivar PDFs con VeriFactu activo) se propuso en la
> conversación y queda pendiente de hablar con Nestor. Confirmar ambos puntos.

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
