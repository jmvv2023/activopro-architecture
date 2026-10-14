---
id: 0010
title: Las rectificativas de ActivoPro se declaran a VeriFactu por diferencias
status: accepted
date: 2026-10-14
services: [verifactu, core]
supersedes: null
superseded_by: null
---

## Contexto

En ActivoPro, una rectificativa es la misma factura en negativo y anula totalmente la original
(fac 25 = 100 → R 25 = −100). Si hace falta, después se emite una factura nueva. GeneXus siempre
la ha declarado "por sustitución": `TipoRectificativa = S`, con `BaseRectificada` y
`CuotaRectificada` iguales a los importes de la propia rectificativa, en negativo.

La AEAT define los dos tipos así (FAQ del SII, que comparte campos con VeriFactu):

- **`S` (sustitución):** la rectificativa lleva los importes **finales** correctos, y
  `ImporteRectificacion` lleva los de la original, en positivo.
- **`I` (diferencias):** la rectificativa lleva la **diferencia**, que puede ser negativa, y no
  se informa `ImporteRectificacion`.

Leída con esas reglas, una `S` en negativo con la base rectificada también en negativo no anula
nada. La AEAT la acepta porque no valida el signo, así que el error no se detecta. Además, el
micro no enviaba `FacturasRectificadas` aunque recibía los datos de la factura original.

## Opciones

- **A. Declarar por diferencias (`I`).** Coincide con lo que ya genera GeneXus y con el PDF.
- **B. Mantener `S`.** Exige cambiar la rectificativa a importes 0 con la original en
  `ImporteRectificacion`, y el registro dejaría de coincidir con el PDF.

## Decisión

Opción A, resuelta en el micro sin tocar GeneXus (issue y PR #46/#47 del micro):

- Si una rectificativa llega como `S` con importe total negativo, se declara `I` y no lleva
  `ImporteRectificacion`. Una `S` con importes finales ≥ 0 se respeta.
- Siempre se envía `FacturasRectificadas` con emisor, número y fecha de la original.
- Nunca se envía `FacturasSustituidas` (solo es para F3).

## Consecuencias

- Cambia el registro enviado a la AEAT: va en el `CHANGELOG` del micro (ADR-0007).
- El flujo **nativo** de GeneXus (`MSVERACT = N`) sigue declarando `S` en negativo. El cliente en
  producción no ha emitido ninguna rectificativa. Hay que corregirlo o pasar ese cliente al micro
  antes de que emita una.
- Opcional: que GeneXus mande `I` directamente, para que el contrato sea más claro. El micro ya
  admite los dos valores.
- Validado en preproducción el 14/10/2026 con una R4 (692, exenta) y una R5.

## Origen

Decisión de José María (14/10/2026), tras revisar la factura 691 en preproducción.
