---
id: 0009
title: Presupuestos — mantener el flujo actual con entregas parciales y cerrar los caminos de facturación que no van a VeriFactu
status: accepted
date: 2026-10-11
services: [core, verifactu, docgenerator]
supersedes: null
superseded_by: null
---

## Contexto

El módulo de Presupuestos tenía errores visibles: descuentos de pie que duplicaban o corrompían
líneas en la pantalla Albarán, facturas creadas desde esa pantalla que no llegaban a VeriFactu,
falta de serie para simplificadas de no clientes y presupuestos de no cliente que se imprimían
como factura simplificada. Ningún cliente usa hoy este modelo de presupuesto, y el único cliente
con módulo de almacén no usa presupuestos.

## Opciones consideradas

1. **Popup nuevo `AceptarPresupuesto`** que sustituyera a la pantalla Albarán y eliminara la copia
   K (y con ella las entregas parciales). Propuesto por Claude.
2. **Mantener el flujo actual** y corregir los defectos concretos.

## Decisión

Opción 2. Las pruebas reales mostraron que el flujo aceptar → albarán funciona y que las
**entregas parciales** (copia del presupuesto en estado K) están bien pensadas: un presupuesto
con muchos elementos se entrega por partes. Se decide:

- Corregir la duplicación de líneas de descuento (falta de `.Clone()`).
- **Deshabilitar el combo Facturar de la pantalla Albarán** en vez de arreglarlo: ya hay dos
  caminos que facturan bien con VeriFactu (bandeja de albaranes y bandeja de presupuestos).
- Exigir `SERSIMPL` antes de facturar por lotes presupuestos de no cliente con VeriFactu: si
  falta, se bloquea toda la tanda.
- En `ms_PDFService`, decidir la plantilla por la categoría del documento (presupuesto,
  albarán, factura) **antes** de aplicar la regla de cliente genérico → simplificada.
- Reglas de negocio: un presupuesto no descuenta stock (solo el albarán). Se puede presupuestar
  sin cliente, pero al aceptar (convertir en albarán) hace falta el alta del cliente.

Todos estos cambios se probaron en el entorno de pruebas (facturas 656 y 670).

## Consecuencias

- Estados del presupuesto: H Solicitado → al aceptar se desdobla en I Aceptado (original,
  archivado) y K Pendiente de entrega (copia que genera albaranes A). Facturar desde la bandeja
  de presupuestos pasa el presupuesto a L Finalizado. J = No aceptado.
- Pendiente: buscar en los tenants facturas ya creadas con el combo deshabilitado (no están en
  VeriFactu); claridad de la pantalla Albarán (el combo no debe aceptar por defecto en
  "Solicitado", columnas de cantidad entregada/pendiente, avisos antes de guardar); protección
  contra doble clic; errores de guardado que no se muestran.
- Si algún día un cliente con almacén quiere presupuestos, el stock se añade como paso aparte.
- Lección de seguridad: había una contraseña SMTP escrita en el código de `WpImPresupuesto`.
  Ya resuelto.

## Origen

Conversaciones "PRESUPUESTOS" (oct 2026) y "Presupuesto workflow design" (hasta el 11/10/2026).
