---
id: 0064
title: El alta en VeriFactu de una empresa sin sistema empieza hoy o cualquier día posterior
status: proposed
date: 2026-11-25
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

ADR-0055 fija una regla única para todo cambio de sistema de facturación: el día 1 de un periodo de liquidación futuro, nunca hoy.
Incluye de forma expresa la primera alta en VeriFactu. Con esa regla, una empresa trimestral sin SII que quiere VeriFactu en
noviembre tiene que esperar al 1 de enero, aunque no haya nada que lo impida.

La regla existe para que un periodo no quede en dos sistemas: el SII liquida por meses y lleva los libros del periodo, y VeriFactu y el
SII se excluyen. Sin sistema antes, no hay nada que partir: VeriFactu es un registro por factura en el momento de expedirla y no
cambia la periodicidad ni el contenido del 303. Además, el RRSIF permite usar VeriFactu de forma voluntaria antes de que sea
obligatorio.

Planteado por José María el 25/11/2026: «si no tiene limitaciones debería poder activarlo, solo cuando salta entre SII y VeriFactu
tienen sentido las limitaciones».

## Opciones consideradas

1. **Mantener la regla de ADR-0055 para todo.** Más simple, pero hace esperar sin motivo a quien quiere VeriFactu ya.
2. **Alta en VeriFactu sin sistema anterior: cualquier día desde hoy**, con una sola condición: que no haya facturas emitidas con
   esa fecha o posterior.
3. **Además, alta con fecha pasada**, registrando lo ya emitido. No: un registro de VeriFactu se genera al expedir la factura; hacerlo
   a posteriori daría una huella y una fecha de generación que no corresponden.

## Decisión

Opción 2.

- **Alta en VeriFactu** (`app.alta_verifactu`) = el sistema pedido es VeriFactu y la empresa no lleva ninguno el día antes de
  empezar. Puede empezar hoy o cualquier día posterior, no solo el día 1. Desde hoy, entra en el momento: la siguiente factura que
  se emite lleva su registro y su QR.
- **Lo ya emitido no entra**: si hay facturas emitidas con esa fecha o posterior, no se puede (`ALTA_VERIFACTU_FACTURAS_EMITIDAS`):
  quedarían dentro del tramo sin registro. Se dice el día siguiente a la última.
- **Nunca hacia atrás** (`ALTA_VERIFACTU_FECHA`).
- **Lo demás no cambia**: entrar en el SII (también sin sistema anterior), pasar de VeriFactu al SII y del SII a VeriFactu siguen
  las reglas de ADR-0055 (día 1 de periodo futuro, nada en curso, rechazados aceptados). El resto de controles del alta (NIF,
  territorio foral, un cambio programado a la vez, aviso sin certificado) también siguen.
- Lo sigue haciendo solo Enumbers desde la consola, con motivo; la consola enseña un calendario desde hoy en lugar de la lista de
  fechas (`fecha_libre` en la comprobación).

## Consecuencias

- Un cliente nuevo o uno que se adelanta a la obligación puede empezar con VeriFactu el mismo día que lo pide.
- Un alta desde hoy no se puede cancelar (ya ha empezado); si se activa por error, salir de VeriFactu no está previsto hoy (no hay
  tramo «ninguno»). Se acepta: el alta la hace Enumbers con motivo y la pantalla pide confirmar.
- Pendiente aparte: la semilla de la cadena para una empresa que ya enviaba a VeriFactu desde el micro de GeneXus (H-074).

## Origen

Mensaje de José María del 25/11/2026 (arriba). Implementado en activopro-platform `20261231000047_alta_verifactu.sql`. Pendiente
de que José María lo pase a `accepted`.
