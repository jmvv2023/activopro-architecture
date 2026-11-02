---
id: 0008
title: Aparcar el primer micro de VeriFactu y extender el VeriFactu nativo de GeneXus
status: superseded
date: 2026-09-20
services: [verifactu, core]
supersedes: null
superseded_by: 0004
---

## Contexto

Al investigar un error en facturas simplificadas aparecieron problemas graves en el primer
micro: desfase de esquema de `facturas` entre KB y BDs (82 frente a 93 columnas), estado
duplicado entre columnas `Fac*` y `msFacVeri*`, uso de `FacMod` como fecha de expedición y falta
de contrato con GeneXus.

## Decisión

Trabajar con el VeriFactu ya disponible en GeneXus, ampliándolo para enviar simplificadas
(serie `SERSIMPL`), y retomar el micro más adelante. El micro se retira de Fly y queda solo en
local. El objetivo del micro (reducir dependencia de GeneXus con tecnologías actuales) se mantiene.

## Por qué se sustituye

El 29/09/2026 se retomó el micro con un diseño nuevo que resolvía estos problemas: único SIF,
columnas de resultado unificadas en `Fac*` y sin Supabase. Ver ADR-0004 y
`domain/verifactu-evolucion.md`.

## Origen

Conversación "Error al generar factura simplificada" (19–21/09/2026).
