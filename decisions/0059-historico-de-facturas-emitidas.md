---
id: 0059
title: Las facturas emitidas del programa anterior se cargan como documento, fijas y enlazadas a su asiento
status: proposed
date: 2026-11-20
services: [platform]
supersedes: null
superseded_by: null
---

## Contexto

La carga de un cliente trae sus asientos, sus registros de IVA y su cartera, pero no sus facturas emitidas como documento
(`facturas`, `facturasfaclin`, `facturasfacimp`, `facturasfacven`: unas 376.000 facturas con 2,4 millones de líneas en 79 empresas).
Con la carga actual el libro de facturas emitidas de la plataforma empieza vacío: no se puede reimprimir ni reenviar una factura
anterior, no se rectifica eligiendo la original del libro (hay que teclear número y fecha), los vencimientos cargados no saben a qué
factura pertenecen y no hay de dónde tomar la semilla de VeriFactu (H-101).

Las recibidas se registran sobre todo como asientos con su registro de IVA, que la carga contable ya trae; si `facturas` guarda
también recibidas, se cargan con el mismo criterio (por confirmar con datos, abajo).

Las facturas de la plataforma son inmutables una vez emitidas (ADR-0031) y generan su asiento, su cartera, su registro de VeriFactu
o del SII por triggers. La carga va sin triggers y ya hay precedentes de datos migrados fijos: cobros de origen `migrado`
(ADR-0035) y albaranes con `factura_externa` (ADR-0041, fase 5).

## Opciones consideradas

1. **Cargar cada factura emitida como `factura` de origen `migrada`** — cabecera, líneas comerciales (`facturasfaclin`), desglose
   (`facturasfacimp`), retención, enlazada a su asiento ya cargado (`FacEjer` + `FacAsi`) y a sus vencimientos de la cartera
   cargada; fija (ni se modifica ni se anula; se rectifica con una rectificativa de la plataforma). Libro completo, reimpresión con
   la plantilla de la plataforma, rectificación desde el libro.
2. **Solo cabecera** (número, fecha, cliente, total, asiento) para el libro y la rectificación. Menos trabajo, pero no se reimprime ni
   se reenvía, y la Facturae o la reimpresión de una factura anterior siguen sin poder hacerse.
3. **No cargarlas** y que el cliente consulte las anteriores en el programa anterior en modo lectura. Mantiene viva una instalación
   que se quiere apagar.

## Decisión

Opción 1. Propuesta concreta:

- **Qué**: las emitidas de los ejercicios abiertos y de los cerrados que se carguen (los mismos ejercicios que la contabilidad).
  Origen `migrada`, estado contabilizada, `asiento.factura_id` al asiento cargado; si el asiento no está o no cuadra con la factura,
  se carga igual y queda como anomalía (no se fuerza ningún enlace).
- **Series**: una serie de la plataforma por `FacSer`, con el número siguiente de cada una para que la primera factura emitida en la
  plataforma siga la numeración (esto cierra también lo pendiente de `numserie`).
- **Fijas**: un trigger impide cambiar o anular una factura `migrada` desde la aplicación (como `cobro_migrado_fijo`); se rectifica
  con una rectificativa de la plataforma que la referencia del libro.
- **Reimpresión**: con la plantilla y el estilo de la plataforma, con una marca discreta «Duplicado» cuando la original se emitió en el
  programa anterior: el aspecto no será el del original y eso se dice en el manual.
- **VeriFactu**: la semilla de la cadena de cada NIF es el último registro de la tabla del micro (`verifactu_registro` del schema), no
  `facturas.FacHashCode`: el micro es la fuente de verdad de la cadena (ADR-0004). Las facturas migradas no generan registros nuevos.
- **SII**: las migradas no se envían (lo enviado se cuadra con la consulta a la AEAT, H-089).
- **Modo sombra**: comparar por ejercicio, serie y mes el número de facturas, la base, la cuota y el total frente al programa
  anterior, y frente a los registros de IVA cargados.

## Consecuencias

- El libro de facturas, la cartera y la rectificación funcionan desde el primer día con la historia del cliente.
- Unos 2,4 millones de filas de líneas en la base para los clientes que facturan: tamaño asumible (la estimación de base de
  10–20 GB ya contaba con las facturas).
- La reimpresión no es idéntica al original del programa anterior; si un cliente lo necesita, el original en PDF tendría que venir
  como adjunto (ADR-0057), y hoy el programa anterior no lo guarda.
- Antes de implementar: confirmar con datos qué hay en `facturas` (si solo emitidas o también recibidas, que los campos
  `FacFecRec`, `FacSerRec` y `FacNumRec` hacen pensar en una recepción), qué distingue `FacTip`, cómo se identifican las
  rectificativas y su original, y el tratamiento de las facturas en divisa (`FacDivCod`, consulta en el análisis de paridad).

## Origen

Análisis `analysis/2026-11-paridad-programa-anterior.md` (20/11/2026); hueco H-101 de `activopro-platform/docs/manual/huecos.md`.
