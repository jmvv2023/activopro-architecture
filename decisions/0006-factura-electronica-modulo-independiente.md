---
id: 0006
title: Factura electrónica B2B como servicio independiente con modelo canónico EN 16931
status: accepted
date: 2026-09-26
services: [einvoice, verifactu, core]
supersedes: null
superseded_by: null
---

## Contexto

Obligación de factura electrónica B2B (Ley 18/2022 "Crea y Crece", RD 238/2026, SPFE de la AEAT).
Fechas: oct 2027 (> 8 M€), oct 2028 (resto), estados de pago de personas físicas oct 2029.
Debe servir al núcleo GeneXus y al nuevo ActivoPro.

## Decisión

- Módulo fuera de GeneXus, como servicio independiente reutilizable por ActivoPro u otros
  sistemas (podría actuar como partner).
- Modelo canónico basado en los términos BT/BG de EN 16931; lo específico de la SPFE en el
  perfil `spfe-es`. Adaptadores por plataforma.
- Integración con GeneXus mediante tabla outbox por tenant (`ms_spfe_outbox`,
  `sp_spfe_encolar()`), sin llamadas HTTP dentro de transacciones GeneXus.
- Certificados gestionados como en ms-verifactu.
- Incluido en la cuota junto a VeriFactu y SII, sin coste adicional.
- Prioridad: núcleo SPFE de emisión. Recepción (apoderamiento) aplazada.

## Consecuencias

- La categoría de IVA, clave de régimen y exenciones deberían salir de la misma lógica que
  ms-verifactu, para que ambas obligaciones no den versiones distintas de la misma factura.
- Huecos del modelo pendientes: retención IRPF, suplidos, múltiples vencimientos.

## Origen

Conversaciones "SPFE y su impacto en ActivoPro" y "SPFE modelo canónico y adaptador" (sep 2026).
