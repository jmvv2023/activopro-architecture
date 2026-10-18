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

La AEAT define los dos tipos así (FAQ de VeriFactu, procedimientos de facturación, y FAQ del SII,
que usa los mismos campos):

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

## Nota sobre la terminología (18/10/2026)

En GeneXus y en el negocio, ActivoPro llama **"sustitución"** a todo el proceso: la factura
emitida no se toca, se anula con su copia exacta en negativo y se emite una nueva. Es una
sustitución **de negocio**. En el registro VeriFactu se codifica con `TipoRectificativa = I`.
Que el código de GeneXus diga "sustitución" **no** es motivo para volver a `S`.

Fuente: FAQ VERI\*FACTU de la AEAT, «Procedimientos de facturación»
(https://sede.agenciatributaria.gob.es/Sede/iva/sistemas-informaticos-facturacion-verifactu/preguntas-frecuentes/procedimientos-facturacion.html):

- `S`: los importes de la rectificativa son los **correctos tras la rectificación**. Se informan
  además la base y la cuota rectificadas.
- `I`: se informa **directamente el importe de la rectificación** (la diferencia), sin más campos.
- «¿Qué fecha de operación debe hacerse constar en una factura rectificativa? La fecha de
  realización de la operación correspondiente a la factura original que se está rectificando.»
  El micro la envía en `FechaOperacion` desde el #68.

## Origen

Decisión de José María (14/10/2026), tras revisar la factura 691 en preproducción.
