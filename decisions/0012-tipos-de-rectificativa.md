---
id: 0012
title: Rectificativas total y parcial, siempre por diferencias, con el tipo R1/R4 según el motivo
status: proposed
date: 2026-10-27
services: [verifactu, core]
supersedes: null
superseded_by: null
---

## Contexto

Hoy ActivoPro solo hace un tipo de rectificativa: una copia exacta de la factura en negativo
que la anula entera (100 → −100). Después, si hace falta, se emite una factura nueva. En
VeriFactu se declara `TipoRectificativa = I` (ADR-0010) y siempre con `R4` (o `R5` si la
factura es simplificada).

Esto no basta para clientes que hacen abonos parciales, por ejemplo devoluciones de una parte
del material (Torro). Para ellos hacen falta rectificativas parciales y que el tipo refleje
la causa.

Lo que dice la AEAT (FAQ VERI\*FACTU, procedimientos de facturación):

- **`S` (sustitución):** la rectificativa lleva los importes **correctos finales** e
  `ImporteRectificacion` con los de la original.
- **`I` (diferencias):** la rectificativa lleva **la diferencia**, negativa o positiva (un
  aumento de base 200 al 21 % se informa como importe total 242), sin `ImporteRectificacion`.
- **`R1`:** error fundado en derecho y art. 80 Uno, Dos y Seis LIVA (devoluciones, descuentos
  y bonificaciones posteriores, resolución de la operación). **`R2`:** art. 80.3 (concurso).
  **`R3`:** art. 80.4 (incobrables). **`R4`:** el resto (errores de cálculo o de datos).
  **`R5`:** cualquier rectificativa de una factura simplificada.
- Las rectificativas se expiden en una **serie específica**.
- Una rectificativa puede rectificar varias facturas. En ese caso, `FechaOperacion` es la de la
  más reciente.

## Opciones consideradas

1. **Implementar `S` además de `I`.** Contra: una `S` de 90 sobre una original de 100 tiene un
   efecto real de −10, pero `ContaFacVen`, el libro de IVA, el 303 y el 347 suman las facturas
   tal cual (darían 190). Habría que cambiar la contabilización y todos los informes, para todos
   los tenants. La AEAT admite los dos procedimientos, así que no hay obligación de usar `S`.
2. **Solo `I`, con dos modos (total y parcial) y el tipo según el motivo.** Reutiliza la copia
   en negativo que ya existe y la contabilización actual, que ya trata facturas en negativo.

## Decisión

Opción 2 (decidida por José María el 27/10/2026, a falta de pasar a `accepted`).

Al marcar «Rectificativa: Sí», GeneXus pregunta dos cosas.

**Qué se quiere hacer:**

- **A. Total, que anula la factura.** Es lo de hoy: copia exacta en negativo y se graba.
- **B. Parcial, por diferencias.** Genera la misma copia en negativo, pero en modo edición y
  antes de grabar. El usuario deja solo lo que cambia: puede **reducir** el importe (borrar
  líneas, ajustar unidades o precio) o **aumentarlo** (líneas en positivo).

**El motivo:**

| Motivo | Tipo |
|---|---|
| Devolución, descuento o bonificación posterior, o anulación de la venta | `R1` |
| Error en la factura (importe, cálculo, dato) | `R4` |
| Factura simplificada (cualquier motivo) | `R5`, automático |

`R2` y `R3` quedan fuera: son raros y tienen su propio procedimiento.

**Siempre `TipoRectificativa = I`.** Nunca `S`. En pantalla no se usa la palabra
«sustitución», que en la AEAT significa otra cosa. Se usa «Total» y «Parcial».

## Consecuencias

**GeneXus:**

- Un diálogo con modo (A/B) y motivo (R1/R4). B abre la copia negativa en edición.
- La cabecera de la rectificativa (cliente, NIF, datos fiscales) sale de la factura original,
  que conserva sus datos, no de la ficha actual del cliente. No se puede editar.
- **Tope:** el total que restan las rectificativas de una factura no puede superar su importe
  original. Para devoluciones ya existe el control de no devolver más de lo vendido.
- `VF_EnviarMS` envía `I` de forma explícita, también en las parciales que aumentan el importe.
  Hoy el micro solo convierte a `I` las `S` con total negativo, así que una que aumentara el
  importe enviada como `S` se declararía mal.
- El tipo `R1`/`R4` se envía según el motivo. `R5` sigue saliendo automático en las
  simplificadas.
- Con VeriFactu, no se permite una rectificativa si la empresa no tiene configurada la serie de
  rectificativas (ya es así).
- No se puede rectificar una factura con registro rechazado (`E`). Esa se resuelve con la
  anulación del registro (pendiente de su propio ADR).

**Micro:**

- Admite `R1` (hoy recibe `R4` y `R5`). `I` pasa a ser el tipo por defecto de una rectificativa.
  El bloque de rectificativa no cambia: `FacturasRectificadas` y `FechaOperacion`.
- Entrada en el `CHANGELOG`, porque cambia el registro (ADR-0007).

**Contabilidad:** sin cambios. Las rectificativas siguen siendo facturas con importes negativos
o positivos.

## Puntos abiertos

1. **Abonos que agrupan varias facturas.** Hay que confirmar si Torro agrupa varias facturas en
   un abono o varios albaranes en una factura. Si es lo primero, hace falta:
   - en GeneXus, una tabla hija con las facturas rectificadas (hoy solo existe `FacNumRec`);
   - en el micro, que `factura_rectificada` pase a ser una lista y `FechaOperacion` sea la de
     la más reciente.
2. **Serie de rectificativas sin VeriFactu.** La obligación de la serie específica viene del
   Reglamento de facturación, no de VeriFactu. ¿Avisar a los clientes sin VeriFactu que no la
   tengan configurada? Bloquearlos afectaría a todos los tenants. Hay que cotejar el artículo en
   el BOE.

## Origen

Conversación con José María, 27/10/2026. Antecedentes: ADR-0010 y la FAQ VERI\*FACTU de la AEAT
(https://sede.agenciatributaria.gob.es/Sede/iva/sistemas-informaticos-facturacion-verifactu/preguntas-frecuentes/procedimientos-facturacion.html).
