---
id: 0030
title: Registro de facturas — la factura recibida y la emitida registrada como documento, base de la facturación futura
status: proposed
date: 2026-11-08
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Es el arranque de la fase 3 de ADR-0028 (documentos y asistentes). ADR-0028 decidió que la factura recibida es un documento y que su asiento se genera solo. Dejó pendientes los datos por defecto del tercero (pendiente 3) y qué hacer con las facturas migradas de GeneXus (pendiente 2).

**Lo que hay hoy en la plataforma.** No existe el objeto «factura». Como en GeneXus, sus datos están repartidos por el asiento:
- en el apunte: `documento_serie`, `documento_numero`, `documento_fecha`, `factura_numero` y `factura_fecha`;
- colgando del apunte: `registro_iva` (base, tipo, cuota, cuota deducible, operación, deducibilidad, bien de inversión, destino) y `retencion`;
- el tipo de operación lo decide en GeneXus el diario (`domain/contabilidad-legacy.md`): 11 compras y gastos, 4 inversiones, 7 adquisición intracomunitaria, 42 inversión del sujeto pasivo, 6 importaciones, etc. En la plataforma ya es un atributo del registro (`registro_iva.operacion`, ADR-0018).

**Lo que tendrá que absorber más adelante** (José María, 08/11/2026): el módulo de facturación tiene que poder llevar rectificativas, albaranes, presupuestos y facturación periódica o recurrente. Además:
- VeriFactu (ADR del micro) exige que la factura emitida por el sistema no se modifique: se corrige con una rectificativa o un registro de anulación;
- la factura electrónica (SPFE, ADR-0006) emite y recibe facturas que tienen que acabar en el mismo libro;
- el SII (ADR propio, pendiente) declara los libros registro de recibidas y emitidas.

**Norma.** El art. 64 del Reglamento del IVA obliga a numerar por orden las facturas recibidas y a anotarlas en el libro registro. El art. 15 del Reglamento de facturación y el art. 80 LIVA regulan las rectificativas, con los motivos que el SII y VeriFactu codifican como R1 a R5.

## Opciones consideradas

### A. Qué es el documento

1. **Una tabla por tipo** (`factura_recibida`, `factura_emitida`). Simple al principio. Pero la facturación, la factura electrónica y el SII tendrían que conocer las dos y repetir lo que comparten: tercero, fechas, líneas de impuesto, rectificativas, estado.
2. **Un registro de facturas único** con su sentido (recibida o emitida). Es el modelo de los libros registro del SII y de VeriFactu. Lo que venga después (facturación, factura electrónica, buzón, OCR) produce o consume un registro, sin un modelo de factura propio.

### B. Cómo encaja la facturación futura

1. **El registro de facturas es también el documento de venta**, con sus líneas de artículo, albaranes y presupuestos. Mezcla lo comercial (artículos, cantidades, stock, entregas parciales) con lo fiscal y contable. Un presupuesto o un albarán no son facturas y no deben estar en el libro.
2. **Dos capas.**
   - **Documento comercial** (ola 2): presupuesto, albarán, factura comercial con líneas de artículo y la plantilla de facturación recurrente.
   - **Registro de factura** (este ADR): lo fiscal y contable.
   - Solo la factura comercial, al emitirse, crea su registro (y su registro VeriFactu). El presupuesto y el albarán nunca crean registro ni asiento. La recurrente genera facturas comerciales, y estas sus registros.

## Decisión

José María confirmó el 08/11/2026 la **opción A2** (registro único) y el orden de trabajo de abajo. Lo demás se propone para revisarlo antes de implementar:
- la opción B2 (dos capas);
- el modelo;
- el asiento;
- los datos por defecto del tercero;
- el alta del tercero desde el formulario;
- las facturas migradas.

### Modelo

**`factura` (el registro).**
- `sentido` (recibida / emitida) y `tercero_rol_id` (proveedor, acreedor o cliente; ADR-0024). La factura guarda además el NIF, el nombre y el país con que se registró, porque la ficha puede cambiar y el libro no.
- **Tipo**, con el catálogo del SII y de VeriFactu:
  - F1, completa;
  - F2, simplificada;
  - F3, sustitutiva de simplificadas;
  - R1 a R5, rectificativas;
  - más el documento aduanero (DUA) para las importaciones en recibidas.
- **Números.**
  - En recibidas, el número que pone el proveedor.
  - En emitidas, serie y número.
  - Además, el número de registro interno, correlativo por ejercicio y sentido (art. 64 RIVA), que no se renumera, como el de asiento.
- **Fechas.**
  - Expedición.
  - Operación, opcional y solo si es distinta.
  - Registro contable: es la del asiento y la que decide el periodo del 303, como hoy.
- `estado`: pendiente → contabilizada → anulada. Pendiente es lo que llega del buzón o del OCR, o se guarda a medias. No tiene asiento.
- `origen`: manual, buzón, OCR, facturación, migrada.
- `documento_comercial_id`: vacío hasta la ola 2.
- `emitida_en`, solo en emitidas:
  - `externa`: emitida con otro programa y solo registrada, como en la ola 1;
  - `plataforma`: emitida por la facturación, inmutable por VeriFactu.
- `forma_pago`. Los vencimientos quedan para tesorería.

**`factura_linea`.**
- Cuenta de gasto o ingreso, base, impuesto (IVA / IGIC), porcentaje y cuota.
- Recargo de equivalencia.
- Operación (el catálogo de `registro_iva.operacion`: la línea sustituye al diario de GeneXus), deducibilidad, bien de inversión y destino para la prorrata especial.
- La cuota deducible no se teclea: la calcula el trigger de `registro_iva` como hoy (ADR-0021 y ADR-0022).

**`factura_retencion`.** Clave, base, porcentaje y cuota.

**`factura_rectificada`.**
- Enlaza la rectificativa con la factura o facturas que rectifica. Una rectificativa puede rectificar varias, como permiten el SII y VeriFactu.
- Guarda también los datos de la rectificada cuando no está en el libro (número y fecha), por ejemplo una recibida de antes de la plataforma.
- La rectificativa lleva el motivo (R1–R5) y si es por sustitución o por diferencias.

### El asiento

- `app.contabilizar_factura` genera el asiento. Su origen es propio, no editable (`factura_recibida_doc` / `factura_emitida_doc`). Se compone así:
  - el tercero por el total;
  - las líneas por su base, más la cuota no deducible si la hay;
  - la cuota deducible a la cuenta del impuesto, con su `registro_iva`;
  - la retención a la 4751 en recibidas (practicada) y a la 473 en emitidas (soportada);
  - en ISP e intracomunitarias, la autorrepercusión: soportado contra repercutido.
- Las cuentas de impuesto salen de la configuración fiscal de la empresa por impuesto, tipo y operación.
- **Corregir.** Se corrige la factura y su asiento se rehace en el sitio, conservando su número: el patrón de los asientos de proceso (ADR-0029).
- **Periodos.** La regla B1 (ADR-0028) se comprueba sobre la factura. Con el IVA del mes cerrado, la factura queda bloqueada y se corrige con una rectificativa.
- **Facturas emitidas por la plataforma.** Nunca se modifican; se rectifican.
- **Anular.** Anular la factura anula su asiento, que conserva el número (`app.anular_asiento`).
- **Avisos al registrar:**
  - **duplicada:** mismo NIF, número y año en recibidas. En emitidas externas, misma serie y número: es un error, no un aviso;
  - **fuera de plazo:** la fecha de registro pasa de cuatro años desde la de expedición, el plazo de deducción del art. 99.3 LIVA;
  - **tipo no vigente:** `TIPO_NO_VIGENTE`, como el borrador del 303.

### Datos por defecto del tercero (pendiente 3 de ADR-0028)

- La configuración va por rol (`tercero_rol`):
  - cuenta de gasto o de ingreso;
  - impuesto, tipo y operación;
  - retención (clave y porcentaje);
  - forma de pago.
- Es lo que GeneXus guarda en la ficha del acreedor (`AcrCtaCodGasto`, `AcrIvaTpoCod`, `AcrIgicTpoCod`, `AcrIRPF`, `ForPagCod`). El ETL la carga de ahí.
- **Proponer sin imponer** (ADR-0029). El formulario parte de la configuración del rol. Si no la hay, parte de la última factura de ese tercero, como `AcrConIdUlt` en GeneXus. Si el rol no tiene configuración, ofrece guardarla con un clic. Nunca la cambia por su cuenta.

### Alta del tercero desde el formulario

Si el NIF no existe:
- se valida con `app.nif_valido`;
- se crea el tercero y su rol;
- se propone la siguiente subcuenta libre de la 400 (proveedor), la 410 (acreedor) o la 430 (cliente), que el usuario puede cambiar (`app.alta_cuenta`, ADR-0029).

### Facturas simplificadas (F2) sin tercero

José María, 08/11/2026: el cliente de un ticket no está dado de alta ni se va a dar. Se registran unos datos mínimos, ninguno obligatorio, y la factura va contra la cuenta genérica de clientes varios. En GeneXus es el parámetro `CGENFAC`, `4300 999999` (`domain/verifactu.md`): una factura contra esa cuenta es F2.

**Sin tercero.**
- La F2 y su rectificativa (R5) son las únicas facturas que se registran sin `tercero_rol_id`.
- Llevan en la propia factura el nombre, el NIF y el domicilio, todos opcionales.
- No se crea ficha ni subcuenta.

**Cuenta genérica.**
- La de clientes varios se configura por empresa en `empresa_config_contable`. Por defecto es `430 999999`, y el ETL la carga de `CGENFAC`.
- En recibidas hay una de acreedores varios para los tickets de gasto. Por simetría se propone `410 999999`, que el usuario puede cambiar.
- El asiento va contra esa cuenta en lugar de la subcuenta del tercero.

**Límite** (art. 4 del Reglamento de facturación).
- La simplificada se admite hasta 400 € con IVA incluido, o hasta 3.000 € en las actividades del art. 4.1.b (comercio minorista, hostelería, transporte de personas…).
- Los dos importes van como parámetros de la plataforma (`parametro_plataforma`, versionados).
- Pasar del límite es un aviso, no un bloqueo: proponer sin imponer.

**Simplificada cualificada** (art. 7.2 del Reglamento de facturación).
- Si el destinatario es empresario y pide su NIF y domicilio en la factura, sigue siendo F2.
- Si la factura la registra quien la recibe, la cuota solo es deducible con ese NIF y la cuota separada (art. 97 LIVA). Una F2 recibida sin el NIF de la empresa propone el IVA como no deducible, con aviso.

**347 y VeriFactu.**
- Sin NIF, o con un NIF de relleno, la factura no va al 347 (ADR-0023).
- En VeriFactu, la F2 y la R5 no llevan destinatarios (error AEAT 1190).
- Las emitidas de la ola 2 tienen su serie propia de simplificadas (`SERSIMPL` en GeneXus).

### Facturas migradas de GeneXus (pendiente 2 de ADR-0028)

- Primero se mide, con la copia local, cuántos asientos de los diarios de facturas se dejan reconstruir como factura sin ambigüedad: un tercero, número y fecha, el IVA cuadrado con las bases.
- Con ese dato se decide si el ETL crea los registros (origen `migrada`).
- Hasta entonces, los migrados siguen siendo asientos editables, como hoy.

### Orden de trabajo (confirmado)

1. Factura recibida manual: formulario, tercero, asiento automático y libro de facturas recibidas.
2. Factura emitida registrada, con el mismo patrón.
3. Plantillas de asiento (las `AsiDefinicion` de GeneXus).
4. Asistentes de banco y caja.
5. Buzón y OCR, con la factura electrónica y los micros.

## Consecuencias

- Hay un libro de facturas que el 347, el SII, la factura electrónica y la facturación pueden leer sin reconstruirlo desde los asientos.
- Lo de hoy (`registro_iva`, `retencion`, los modelos 303, 390 y 347) sigue igual: el asiento generado lleva sus registros de IVA como cualquier otro. Los modelos no cambian.
- Conviven dos formas de factura (documento y asiento migrado) hasta decidir sobre las migradas.
- La ola 2 añade el documento comercial encima del registro, sin cambiarlo: presupuesto → albarán → factura, con entregas parciales y recurrentes.
- La configuración por rol del tercero empieza a existir; la usarán también los asistentes de banco y la facturación.

## Pendiente

- La capa comercial (presupuestos, albaranes, recurrentes): su propio ADR con la ola 2.
- El SII: su propio ADR (ADR-0028, pendiente 1). Este modelo ya lleva los datos que pide: tipo, fechas, rectificadas, número de registro.
- Adjuntar el PDF de la factura: depende del almacenamiento de documentos (ADR-0005).
- Vencimientos y pagos: con tesorería.

## Origen

Conversación del 2026-11-08 con José María al empezar la fase 3 de ADR-0028. Confirmó el registro único (A2) y el orden de trabajo, y pidió que el modelo pueda absorber más adelante rectificativas, albaranes, presupuestos y facturación periódica o recurrente.
