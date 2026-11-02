---
id: 0003
title: Coexistencia temporal del núcleo GeneXus y el nuevo ActivoPro
status: accepted
date: 2026-10-09
services: [core, all]
supersedes: null
superseded_by: null
---

## Contexto

El nuevo ActivoPro (React + Supabase) está en desarrollo sin clientes. El núcleo GeneXus sigue
en producción con ~160 clientes. No hay forma de migrar módulo a módulo: cada cliente migra
completo de una plataforma a otra.

## Decisión

Coexistencia temporal: GeneXus sigue para los clientes no migrados y el nuevo crece en paralelo.
Los micros existentes mantienen dos entornos: producción (sirve a GeneXus) y desarrollo (sirve
al nuevo ActivoPro).

## Consecuencias

- Los micros nuevos se diseñan para servir a ambas plataformas (p. ej. ms-einvoice con modelo
  canónico y adaptadores por plataforma).
- Un cambio en un micro debe comprobarse contra los dos consumidores.

## Origen

Notas del proyecto "nuevo ActivoPro" (oct 2026).
