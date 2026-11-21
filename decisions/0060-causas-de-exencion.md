---
id: 0060
title: Causa de exención por línea, de un catálogo central, heredada y obligatoria al emitir
status: accepted
date: 2026-11-21
services: [platform]
supersedes: null
superseded_by: null
---

## Contexto

La factura emitida de la plataforma imprime una mención por operación: entrega intracomunitaria (art. 25 de la Ley 37/1992),
exportación (art. 21) y, en toda exenta interior, «artículo 20». El art. 20.Uno tiene 27 supuestos (sanidad, enseñanza, seguros,
alquiler de vivienda…) y hay exenciones de los arts. 22 (operaciones asimiladas a la exportación), 23 y 24 (zonas francas, depósitos,
regímenes aduaneros). El art. 6.1.j del Reglamento de facturación (RD 1619/2012) pide, en una operación exenta, la referencia al
precepto de la Ley o de la Directiva o la indicación de que está exenta, y VeriFactu y el SII piden la causa (`CausaExencion` E1–E6):
hoy la plataforma manda E1 en toda exenta interior, que está mal si la causa es del art. 22 (E3) o 23–24 (E4). La clase de la
exenta para el 390 y el 425 (`clase_operacion`: con o sin derecho a deducir) sale de `empresa_config_fiscal.clase_exentas`, un único
valor por empresa.

Una incidencia de cliente lo planteó como «un campo donde informar la excepción de impuestos».

## Opciones consideradas

1. **Texto libre en la configuración de la factura.** Sencillo, pero lo impreso no tendría relación con lo declarado a VeriFactu y al
   SII ni con el 390, y cada usuario redactaría textos legales.
2. **Escribirlo al generar cada factura sin IVA.** Tedioso y con errores; el mismo problema de coherencia.
3. **Una causa por línea, elegida de un catálogo central con su mención, su clave y su clase, propuesta por herencia y obligatoria
   al emitir.**

## Decisión

Opción 3.

- **Catálogo central `causa_exencion`** (norma, como `clave_retencion` y `tipo_impositivo`): código, artículo y apartado, impuesto
  (IVA o IGIC), mención legal por idioma (los seis: la recibe el cliente), clave E1–E6, clase de `clase_operacion` para el 390 / 425 y
  vigencia. Incluye «Otra causa» (E6) con texto libre, que avisa.
- **Herencia**: producto (o su familia, como el resto de heredables del catálogo) → relación cliente → empresa («Causa de exención
  habitual» en Datos de la empresa → Fiscal). La exportación y la entrega intracomunitaria la siguen poniendo el territorio y la
  operación (`app.operacion_propuesta`, E2 / E5).
- **Línea**: en una línea exenta, el desplegable **Causa** ya relleno con lo heredado; se cambia solo cuando esa factura es la
  excepción. Emitir con una línea exenta sin causa es un error (`CAUSA_EXENCION_FALTA`) que lleva a elegirla.
- **Lo que sale de la causa**: la mención impresa (una por causa distinta, en el idioma del cliente), `CausaExencion` en VeriFactu y
  en el SII y la clase para el 390 / 425 (la de la empresa queda como respaldo de lo que no tiene causa: lo migrado y los asientos a
  mano).
- **Recibidas y asientos**: fuera de esta decisión; el registro de IVA conserva la clase como hoy.

## Consecuencias

- Lo impreso, lo declarado a VeriFactu / SII y el 390 salen del mismo dato.
- El usuario normal (una academia, una clínica) lo configura una vez y no lo vuelve a ver.
- Migración: lo emitido antes no cambia (VeriFactu es inmutable); las facturas de la plataforma ya emitidas con E1 se quedan como
  están.
- Pendiente: el contenido exacto del catálogo (supuestos del art. 20.Uno que se ofrecen uno a uno y los que van agrupados) se fija
  con la implementación, contra el texto vigente de la Ley 37/1992 y la Ley 20/1991 (IGIC).

## Origen

Conversación del 21/11/2026 (consulta de José María sobre «Operación exenta en base al art. 25 de la Ley 37/1992»); de acuerdo con
la propuesta.

## Implementación (21/11/2026)

Aceptado por José María el 21/11/2026. En `activopro-platform`: migración `20261231000033_causas_exencion.sql` (catálogo `causa_exencion`, causa por
línea, habitual del cliente y de la empresa, `app.lineas_con_causa`, `CAUSA_EXENCION_FALTA` al emitir, mención en el impreso), PR #219;
aplicada en Supabase el 21/11/2026. Pendiente (H-114): producto y familia, recibidas y asientos, Facturae y la carga.
