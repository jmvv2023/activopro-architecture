---
id: 0031
title: Emisión de facturas — series de la empresa, numeración por ejercicio y menú Facturación
status: accepted
date: 2026-11-08
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

ADR-0030 creó el registro de facturas. En el paso 1 la factura emitida era una factura **registrada**: hecha con otro programa, con el número que traía. Al probarlo, José María señaló que en la plataforma una factura emitida no puede llevar un número inventado por el usuario. Duplicaría o saltaría números, y la numeración tiene que ser correlativa.

**Norma** (RD 1619/2012):
- Art. 6.1.a: la numeración es correlativa dentro de cada serie; puede haber series separadas cuando haya razones que lo justifiquen; las rectificativas van obligatoriamente en serie específica.
- Art. 11: se expide en el momento de la operación; si el destinatario es empresario, antes del día 16 del mes siguiente al devengo.
- Art. 15: la rectificativa se expide en cuanto se conoce la causa y dentro de los cuatro años desde el devengo.
- VeriFactu: el registro de facturación se genera al expedir la factura, con la fecha y hora del sistema.

## Decisión

Decidido por José María el 08/11/2026.

**1. Las emitidas de Facturación las emite la plataforma.**
- **Borrador**: sin número, editable y sin asiento.
- **Emitir** (`app.emitir_factura`): asigna la serie, el siguiente número y la fecha de expedición, genera el asiento y la deja **inmutable** (`emitida_en = 'plataforma'`).
- A partir de ahí no se modifica ni se anula: se corrige con una rectificativa en su serie.
- Las emitidas hechas con otro programa no se registran a mano: las traerá un **módulo de importación** (origen `importacion`). El registro manual de emitidas externas desaparece de la pantalla.

**2. Series de la empresa** (`serie_factura`).
- Las define el cliente en Configuración: código, descripción y tipo (`ordinaria`, `simplificada`, `rectificativa`).
- Cada serie tiene vigencia desde y hasta; **hasta vacío = no caduca**.
- Cada serie numera por su cuenta, de forma correlativa, y la numeración **se reinicia al empezar cada ejercicio**: el ejercicio contable que contiene la fecha de expedición (ADR-0029).
- El número es único por serie y ejercicio (`unique (serie_id, ejercicio_id, numero_serie)`).
- **Número de la factura** = serie, ejercicio y número correlativo, por ejemplo `A-2026-00001`. Lleva el ejercicio porque la numeración se reinicia cada año y el número tiene que ser único.
- La serie tiene que corresponder al tipo de factura: simplificada → serie simplificada; rectificativa → serie rectificativa; el resto → serie ordinaria. Si hay una sola serie vigente del tipo, se propone esa.

**3. Fechas.**
- **Emitida.**
  - La fecha de expedición no puede ser futura.
  - Puede ser pasada, pero no anterior a la última emitida de la misma serie y ejercicio: número y fecha avanzan juntos.
  - La fecha de operación puede ser anterior o posterior (anticipos).
  - Avisa, sin bloquear, si a un empresario se le expide más tarde del día 15 del mes siguiente a la operación.
- **Recibida.**
  - La fecha de expedición no puede ser futura.
  - La de registro va desde la de expedición en adelante; si es futura, avisa.

**4. Menú Facturación.**
- Lleva su portada, con el estilo de Contabilidad (indicadores y tarjetas), con las emitidas (borradores y emitidas) y las recibidas.
- Contabilidad sigue enlazando el asiento con su factura y la factura con su asiento.
- El formulario se abre **en lectura** cuando la factura ya está contabilizada o emitida. Las recibidas se cambian con **Modificar**, que avisa de que el asiento se rehará.

**5. Ficha del tercero.**
- Vencimientos, condiciones de cobro y pago, recargo de equivalencia y cuenta se arrastrarán de la ficha del cliente, proveedor o acreedor.
- Se aborda con el alta de terceros. Entonces se revisará lo que había en ActivoPro (GeneXus y el front anterior) y se limpiará lo viejo para pasar al modelo nuevo.

## Consecuencias

- La factura emitida por la plataforma queda lista para VeriFactu (ms verifactu): número correlativo, fecha del sistema e inmutable.
- La pantalla de Configuración de la empresa tiene una pestaña nueva de series, que habla con la API nueva.
- Los vencimientos siguen fuera hasta la ficha de terceros, como en ADR-0030.

## Origen

Revisión de José María del 08/11/2026 sobre el paso 1 de ADR-0030. Señaló el número inventado en emitidas, las fechas, los datos de la ficha y el flujo de edición, y decidió el módulo de importación, las series con vigencia y la numeración por ejercicio.
