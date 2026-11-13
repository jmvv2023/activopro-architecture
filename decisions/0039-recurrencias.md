---
id: 0039
title: Recurrencias — facturación periódica de clientes y previsiones periódicas de pagos y cobros sin factura
status: proposed
date: 2026-11-13
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Quinto eslabón del orden acordado (ADR-0038): **remesas → recurrencias → catálogo**. En ADR-0030 se dejó «recurrentes» para la capa comercial y en ADR-0034, «facturación periódica» como dato de venta del cliente.

### Lo que hay en GeneXus

- **Cuotas o suscripciones** (`cuotas`, `cuotaslevel1`, pantalla `Cuotas_susc`). Cada fila es un **cliente × artículo** con:
  - fecha de alta y de baja;
  - periodicidad: mensual, bimestral, trimestral, cuatrimestral, semestral, anual o pago único;
  - fecha de la siguiente facturación;
  - descripción corta y larga propias y un orden;
  - un «grupo» (`CuoFacInf`) que separa en facturas distintas las cuotas del mismo cliente y fecha.
  - Los precios van por vigencia (`cuotaslevel1`: precio desde–hasta), y `Cuotas_Susc_pers` permite precios personalizados.
- **Facturación periódica** (`Facperiodo` → `FacPer_confirm` → `Altafacper`): a una fecha, toma las cuotas cuya siguiente facturación ha llegado.
  - Genera una factura por cliente, fecha y grupo, en la serie del programa `FACPERIODO`, con la ficha del cliente (forma de pago, plazos) y las cuentas e impuestos del artículo según el ámbito.
  - Avanza la siguiente fecha según la periodicidad y la ajusta al fin de mes si la empresa tiene el parámetro `FACTEOM`.
  - Contabiliza todas las facturas al final.
  - **Con VeriFactu** genera **proformas** (presupuestos) en lugar de facturas, salvo que el usuario marque «crear factura». Emitir es irreversible, y así se revisan antes.
  - Solo se permite una facturación al mes.
- **Pagos periódicos sin factura** (préstamos, seguros, alquileres sin factura, cuotas de Seguridad Social, impuestos): GeneXus no tiene previsiones periódicas. Los préstamos tienen su propio módulo (cuadro de amortización, `DevCuotaPeriodo`), fuera de este ADR.

### Lo que hay en la plataforma

- Factura emitida con **líneas comerciales** (ADR-0036): descripción, cantidad, precio, % de descuento, impuesto, operación y cuenta de ingreso, sin referencia a un artículo, y descuentos a pie.
- El paso de borrador a emitida (`app.emitir_factura`) da número, fecha y asiento y deja la factura lista para VeriFactu.
- Los vencimientos salen de las condiciones de la relación (ADR-0034) y van a la cartera (ADR-0035). Las remesas los proponen si la forma de pago es domiciliada (ADR-0038).
- Vencimientos manuales sin factura en la cartera (`app.guardar_vencimiento_manual`), que entran en la previsión de tesorería.
- Una página «Suscripciones» del modelo anterior (Supabase), sin uso real.
- El catálogo de productos (familias, artículos, tarifas) va **después** de este ADR.

## Opciones consideradas

### 1. Qué es una recurrencia de facturación

1. **Documento «recurrencia» por cliente** (recomendada).
   - Cabecera: cliente (relación), serie, forma de pago (por defecto, la de la relación), dirección de cobro, periodicidad, día de facturación, fechas de inicio y fin, siguiente fecha, estado (activa, pausada, terminada) y nombre.
   - Líneas comerciales **iguales que las de la factura** (ADR-0036), con el mismo editor.
   - Un cliente puede tener varias, y cada una da una factura por periodo.
   - Es la plantilla de la factura: lo que se ve es lo que se emitirá.
2. **Como GeneXus: una fila por cliente × artículo** con su periodicidad, agrupada al facturar por cliente, fecha y grupo. Es más flexible para mezclar periodicidades, pero la factura resultante no se ve en ningún sitio hasta generarla, y depende del catálogo.

### 2. Precio y su evolución

1. **Precio en la línea y cambios programados** (recomendada).
   - La línea lleva su precio. Un cambio de precio «desde tal fecha» (por línea o en bloque: % sobre una selección de recurrencias, como una subida del IPC) queda guardado y se aplica en el primer periodo que empiece en esa fecha o después.
   - Cuando exista el catálogo, la línea podrá tomar el precio de la tarifa al facturar en lugar de un precio fijo.
2. **Vigencias por línea como `cuotaslevel1`** (precio desde–hasta, editado a mano). Equivale, pero la edición es más pesada y la subida en bloque es un proceso aparte igualmente.

### 3. Qué genera el proceso de facturación

1. **Borradores revisables y emisión en bloque** (recomendada).
   - «Facturar el periodo» crea, para las recurrencias con la siguiente fecha alcanzada, borradores de factura emitida, sin número ni asiento, y avanza la fecha.
   - Una pantalla los lista para revisarlos, cambiar o quitar alguno y **emitirlos todos** (número correlativo, asiento, cartera y VeriFactu) o uno a uno.
   - Es el equivalente de las proformas de GeneXus con VeriFactu, sin un tipo de documento aparte: el borrador ya existe.
   - Un borrador descartado devuelve su periodo a la recurrencia.
2. **Emitir directamente.** Es más rápido, pero un error de precio se corrige con rectificativas en todos los clientes.
3. **Las dos, por recurrencia:** «emitir sin revisar» para las que no cambian nunca. Se puede añadir sobre la 1 sin cambiarla.

### 4. Periodo facturado, fecha de operación y textos

1. **Anticipado o vencido por recurrencia**, con el periodo facturado guardado en la factura (desde–hasta) (recomendada).
   - Se factura al principio del periodo (anticipado, lo habitual en cuotas) o al final (vencido, lo habitual en servicios prestados).
   - Vencido: la fecha de operación es el fin del periodo cuando difiere de la de expedición (dato del registro y de VeriFactu).
   - Variables en los textos de las líneas y en el concepto: `{periodo}` (p. ej. «noviembre 2026», «4T 2026», «2027»), `{desde}` y `{hasta}`, traducidas al idioma del cliente (ADR-0032).
2. **Solo anticipado, sin periodo**, como GeneXus. El texto del periodo se escribe a mano en cada cambio.

### 5. Calendario

1. **Periodicidades mensual, bimestral, trimestral, cuatrimestral, semestral y anual, más pago único** (recomendada).
   - Día de facturación: un día fijo del mes o el **fin de mes**, por recurrencia. Sustituye al parámetro de empresa `FACTEOM` y no tiene el problema de febrero, que en GeneXus deja el resto del año a día 28.
   - Los trimestres pueden ser naturales o contados desde el inicio.
   - Sin prorrateo del primer periodo: si hace falta, se pone una línea con el importe del periodo parcial en la primera factura.
2. **Además, prorrateo automático** del primer y del último periodo. Añade reglas (días naturales o comerciales, redondeos) que casi nadie usa. Se puede añadir más adelante.

### 6. Pagos y cobros periódicos sin factura

1. **Previsiones periódicas en la cartera** (recomendada).
   - Las mismas recurrencias, sin líneas: tercero o cuenta, importe, forma de pago, periodicidad y concepto.
   - Generan **vencimientos manuales** hasta un horizonte (p. ej. 12 meses), que la previsión de tesorería ya ve y que las remesas de pago ya proponen.
   - Al pagarlos, el cobro o pago y su asiento salen como hoy en la cartera o en la conciliación.
   - Sirven para alquileres sin factura, seguros, nóminas, cuotas de Seguridad Social, impuestos fijos y cuotas de préstamo mientras no haya módulo de préstamos.
2. **Asientos periódicos** (una plantilla de asiento, ADR-0033, con periodicidad) que se contabilizan solos: amortizaciones, periodificaciones. Es útil, pero es otra cosa: contabilidad, no tesorería. Se puede hacer después con la misma recurrencia sin líneas.
3. **Facturas recibidas periódicas** (prellenadas). La factura del proveedor llega con su número y su fecha, así que se registra cuando llega (con OCR o importación). Una recibida inventada a priori se descuadra con la real.

### 7. Ejecución

1. **Manual**: «Facturar el periodo» y «Generar previsiones» cuando el usuario quiera, con un aviso en la portada cuando haya recurrencias con la fecha alcanzada (recomendada para empezar).
2. **Automática**: una tarea programada del backend genera los borradores cada día. No emite nada, así que no tiene riesgo. Se añade cuando exista la infraestructura de tareas (también hará falta para VeriFactu).

### 8. Relación con el catálogo

1. **Recurrencias ahora con líneas libres** (recomendada). Cuando llegue el catálogo, la línea podrá llevar el producto, y su descripción, cuenta, impuesto y precio de tarifa saldrán de él, sin cambiar el resto.
2. **Catálogo primero.** Retrasa las recurrencias y no cambia su modelo.

## Decisión

Decidido por José María el 13/11/2026:

- **1.1 Documento de recurrencia por cliente**, con líneas iguales a las de la factura.
- **3.1 Borradores revisables y emisión en bloque.** La 3.3 («emitir sin revisar» por recurrencia) queda para más adelante.
- **6.1 Previsiones periódicas en la cartera** para pagos y cobros sin factura. Los asientos periódicos (6.2) no entran en este ADR.
- **8.1 Recurrencias ahora, con líneas libres.** El catálogo va después y añadirá el producto a la línea.

Pendiente de confirmar, con la propuesta: 2.1 (precio en la línea y cambios programados), 4.1 (anticipado o vencido, periodo en la factura, variables en los textos), 5.1 (periodicidades y día fijo o fin de mes, sin prorrateo) y 7.1 (ejecución manual con aviso; la automática cuando haya tareas programadas).

## Consecuencias (si se acepta la propuesta)

- **Modelo.**
  - `recurrencia`: empresa, tipo (`factura` o `prevision`), sentido (cobro o pago; las de factura, cobro), tercero o cuenta, serie, forma de pago, dirección de cobro, periodicidad, día (o fin de mes), momento (anticipado o vencido), inicio, fin, siguiente fecha, estado, nombre, concepto con variables y horizonte de las previsiones.
  - `recurrencia_linea`: las mismas columnas que `factura_linea_comercial`; más adelante, `producto_id`.
  - `recurrencia_descuento`, como `factura_descuento`.
  - `recurrencia_precio`: cambios de precio programados.
  - `recurrencia_ejecucion`: qué periodo generó qué factura o vencimiento, para no repetirlo y poder deshacerlo.
  - `factura.recurrencia_id`, y el periodo facturado en la factura.
- **Funciones.**
  - `app.guardar_recurrencia`, `app.pausar_recurrencia` o terminarla, y `app.programar_precio` (por línea o en bloque por %).
  - `app.recurrencias_pendientes(empresa, fecha)` y `app.facturar_recurrencias(empresa, fecha, ids)`, que crea borradores con `app.guardar_factura` y avanza la fecha.
  - `app.emitir_facturas(empresa, ids)`: en bloque, una transacción por factura, con los errores por factura.
  - `app.generar_previsiones(empresa, hasta)`.
  - Descartar el borrador, o borrar la previsión sin cobros, devuelve el periodo.
- **API y pantallas.**
  - Módulo `recurrencias` (consultar, preparar, emitir), o dentro de `facturacion` y `cartera` según el tipo.
  - Pantallas: lista con la siguiente fecha y el importe por periodo, ficha con el mismo editor de líneas de la factura y vista previa de la próxima factura, «Facturar el periodo» con la revisión y la emisión en bloque, y las previsiones de pago.
  - Aviso en la ficha si la forma de pago es domiciliada y el cliente no tiene mandato SEPA vigente.
  - La página «Suscripciones» del modelo anterior se sustituye.
- **ETL** de `cuotas` y `cuotaslevel1`: una recurrencia por cliente, periodicidad, grupo y siguiente fecha, con una línea por artículo. Se aplaza hasta que haya importación de clientes (ADR-0038).

## Origen

Conversación del 13/11/2026 con José María: tras las remesas, «pagos recurrentes».
