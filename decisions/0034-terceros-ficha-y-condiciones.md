---
id: 0034
title: Terceros — una identidad con varios roles, condiciones de pago en la ficha y cálculo de vencimientos
status: proposed
date: 2026-11-11
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

### Orden de los módulos

El flujo operativo es **factura → vencimientos → cobro o pago (banco o caja) → conciliación y remesas**. Construirlo en ese orden evita rehacer piezas: el banco tiene que casar vencimientos, y los vencimientos salen de las condiciones de la ficha. Por eso los asistentes de banco y caja de la fase 3 de ADR-0028 pasan detrás de este orden:

1. **Terceros** (este ADR).
2. **Cartera.**
3. **Tesorería**: el movimiento de banco o caja como documento, el extracto y la conciliación.
4. **Remesas.**
5. **Caja diaria y caja de farmacia.**

El criterio, de José María: que prime la eficiencia (no reconstruir partes) y la coherencia del flujo, no cuántos clientes usan cada pieza.

### Lo que hay en GeneXus

**Seis fichas en tablas distintas, con los datos comunes repetidos en cada una:** `clientes`, `proveedor`, `acreedores`, `bancos`, `empleados` y `otros`. Lo propio de cada una:

- **Cliente** (`clientes`, `clidir`, `clicob`, `climandatos`, `cliest`):
  - forma de cobro y condiciones de vencimiento, también **por dirección**: una cadena hotelera paga distinto en cada hotel (TORRO, mconta0037);
  - IBAN y mandatos SEPA;
  - recargo de equivalencia y exento de IVA;
  - estado con bloqueo de ventas, límite de crédito y riesgo asegurado;
  - datos de facturación: tarifa, rappels, portes, copias, agrupar albaranes, facturación periódica, ruta.
- **Proveedor y acreedor:** forma de pago, condiciones de vencimiento, cuenta bancaria, recargo, IRPF con su clave, y cuenta de gasto y tipo de impuesto por defecto. El proveedor tiene además datos de compras.
- **Otros:** como el acreedor, sin condiciones. Hoy no lo usa nadie: estaba pensado para módulos futuros, como un CRM.
- **Empleado:**
  - datos contables: NIF, cuenta bancaria, 465/460;
  - datos laborales: número de la Seguridad Social, fecha de nacimiento, estado civil, hijos, categoría, contrato, salario bruto y neto y porcentaje de IRPF. Solo los usan la ficha (`TEmpleado`) y el listado a Excel. Las nóminas (`IngNominas1`, `IngNomFet`, las plantillas de ADR-0033) contabilizan totales calculados fuera.
- **Banco:** la entidad y, en `bancosbcta`, las cuentas de la propia empresa (IBAN, 572, sufijos SEPA, numeración de cheques y pagarés).

**Formas de cobro y pago:** dos catálogos por empresa, `forcob` (con descuento por pronto pago, gastos financieros y riesgo) y `forpag`.

### Cómo calcula GeneXus los vencimientos

Lo hacen `AltaPrevC` / `AltaPrevP` al contabilizar la factura; el manual lo explica en el apartado 3.2, «Previsión de pagos».

- **Fecha de partida:** la fecha de la factura o, si no la hay, la de la operación. Si la factura trae un primer vencimiento, manda ese.
- **Plazos:** el importe se divide entre los plazos y el resto de céntimos va al último.
- **Primer vencimiento:** a «días hasta el primero».
- **Siguientes:** cada «días entre vencimientos».
- **Cómputo**, por empresa (`TPOPCOB`):
  - **comercial:** los múltiplos de 30 son meses; una factura de fin de mes vence a fin de mes, y el 28 de febrero cuenta como fin de mes;
  - **natural:** se suman días.
- **Días de pago (dos como mucho):** la fecha se mueve hacia delante al primero que no haya pasado; si han pasado los dos, al primero del mes siguiente, sin pasarse del último día del mes.
- **Si ya hay algo cobrado**, no se recalcula.

## Opciones consideradas

**1. Identidad.**
- a) Una ficha por tipo con sus datos, como GeneXus.
- b) **Una identidad (`tercero`) con los datos comunes y un rol por papel (`tercero_rol`).** Es lo que empezó ADR-0024. **Elegida.**

**2. Condiciones de vencimiento.**
- a) Catálogo de condiciones reutilizables («30-60-90, días 10 y 25»): limita lo que hoy se configura por ficha y por dirección.
- b) **En la ficha (rol) y, si hace falta, en la dirección de cobro, como GeneXus.** **Elegida.**

**3. Forma de pago.**
- a) Texto libre.
- b) **Catálogo por empresa con un medio normalizado.** Es lo que piden Facturae/UBL (código de medio de pago) y las remesas. **Elegida.**

**4. Datos laborales del empleado.**
- a) No migrarlos hasta que exista un módulo de nóminas (minimización de datos personales).
- b) **Migrarlos en una tabla aparte con permiso propio y auditoría de accesos.** No se pierde lo que tienen los clientes y quedan listos para unas nóminas futuras, sin que los vea quien solo lleva la contabilidad. **Propuesta**; decide José María.

## Decisión

### Identidad: `tercero`

- Uno por NIF en la empresa, como en ADR-0024.
- **Tipo de documento de identificación:**
  - NIF español;
  - NIF-IVA, pasaporte, documento oficial del país de residencia, certificado de residencia, otro, no censado.

  Son los códigos que usan el 349, el SII y la factura electrónica.
- Nombre fiscal y comercial.
- Dirección fiscal: vía, código postal, localidad, provincia INE y país.
- Teléfono, correo, web, idioma (ADR-0032) y observaciones.
- **Contactos** en `tercero_contacto`: nombre, cargo, teléfono y correo.

### Papeles: `tercero_rol`

- **Roles:** cliente, proveedor, acreedor, banco, empleado y **otro**. «Otro» no tiene datos propios.
- **Comunes:** fecha de alta y de baja, y bloqueo con su motivo (lo que en GeneXus es el estado del cliente).
- **Cobro y pago** (cliente, proveedor y acreedor):
  - forma de pago (`forma_pago_id`);
  - **condiciones**: `plazos`, `dias_primer_vencimiento`, `dias_entre_vencimientos` y `dias_pago`, este último con dos días como mucho, igual que GeneXus;
  - cuenta bancaria predeterminada;
  - gastos de cobro.
- **Riesgo** (cliente): límite de crédito, riesgo asegurado y riesgo de la empresa. La cartera los usará.
- **Fiscal:** recargo de equivalencia, exento y el IRPF con su clave. Los valores por defecto de la factura (cuenta, impuesto, tipo, operación, retención) ya existen (ADR-0030).
- **Banco:** BIC/SWIFT. Las cuentas propias de la empresa irán con la tesorería.

### Direcciones: `rol_direccion`

- De envío o de cobro, con nombre, dirección, contacto, teléfono y correo.
- Una dirección de cobro puede llevar **su propia forma de pago, sus condiciones y su cuenta bancaria**, que sustituyen a las del rol (`clidir`, `clicob`).
- Lo logístico (rutas, horarios, transportista) se queda para la logística.

### Cuentas bancarias y mandatos SEPA

- **`tercero_cuenta_bancaria`**: IBAN validado, BIC y titular. Son del tercero; el rol y la dirección eligen cuál usar.
- **`mandato_sepa`**, del rol cliente sobre una cuenta:
  - referencia única en la empresa;
  - esquema CORE o B2B;
  - recurrente o único;
  - fecha de firma, fecha del último cobro y estado: activo, revocado o caducado (36 meses sin usarse);
  - documento firmado.

### Formas de pago: `forma_pago`

- Catálogo por empresa con un nombre por idioma y el **medio normalizado**: efectivo, transferencia, domiciliación SEPA, cheque, pagaré, efecto, tarjeta, confirming, compensación u otro.
- Uso: cobro, pago o ambos; si se puede remesar; descuento por pronto pago y gastos financieros.
- Sustituye a `forcob` / `forpag`, y al texto libre que hoy guarda `tercero_rol` para la factura.

### Cálculo de vencimientos

- **`empresa_config` guarda el cómputo**, comercial o natural (`TPOPCOB`).
- **`app.vencimientos_propuestos(fecha_base, importe, condiciones, cómputo[, primer_vencimiento])`** devuelve la lista de vencimientos con número, fecha e importe. Es una función pura que replica GeneXus y lleva como tests los doce casos del manual (3.2) y los del código.
- La usarán la cartera (el siguiente ADR) y la vista previa de la ficha.

### Datos laborales del empleado: `empleado_laboral`

- Si se elige la opción 4b, contiene: número de la Seguridad Social, fecha de nacimiento, estado civil, hijos, categoría, tipo de contrato, fechas de alta y baja laboral, salario bruto y porcentaje de IRPF.
- **Solo se leen con `app.datos_laborales`**, con el permiso `terceros.datos_laborales` (del administrador por defecto), y cada lectura queda registrada.
- La aplicación no puede leer la tabla directamente.

### Fuera de este ADR

- Los datos de venta y compra (tarifas, rappels, portes, copias, facturación periódica, agrupar albaranes): van con Facturación y productos.
- Las cuentas propias en bancos: van con la tesorería.

### Módulo, API y pantallas

- **Permisos** del módulo `terceros`:
  - `consultar`;
  - `preparar` (fichas);
  - `configurar` (formas de pago y cómputo);
  - `datos_laborales`.
- **Pantallas:**
  - **Lista:** búsqueda por nombre, NIF o código y filtro por papel.
  - **Ficha:** cabecera con la identidad y una pestaña por papel, con «Añadir papel».
  - **Condiciones con vista previa:** «una factura de hoy por 1.000 € vencería el 20/12 por 500 € y el 20/01 por 500 €».
  - **Direcciones, cuentas bancarias y mandatos.**
- Los textos nacen en castellano, catalán e inglés (ADR-0032).

### ETL

Carga las seis fichas, sus direcciones, cobros y mandatos y los catálogos `forcob` / `forpag`:
- **Medio normalizado:** se deduce de la forma de pago y la que no se pueda deducir queda como anomalía.
- **Fusión por NIF:** como en ADR-0024; las discrepancias, como anomalía.
- **Datos personales:** solo en local, como hasta ahora.

## Consecuencias

- **Facturas existentes:** la factura de ADR-0030 deja de llevar la forma de pago como texto: apunta al catálogo, y los textos actuales se convierten.
- **Vencimientos:** la cartera ya tendrá todo lo que necesita para generarlos.
- **Un tercero, varios papeles:** cliente y proveedor a la vez comparten identidad, contactos y cuentas bancarias, sin datos que se contradigan.
- **Pendiente de José María:** opción 4 (datos laborales).

## Origen

Conversación del 11/11/2026 con José María:
- una sola identidad;
- condiciones en la ficha y por dirección de cobro (TORRO);
- «otros» como un rol más;
- los datos laborales, con permiso especial;
- el apartado 3.2 del manual (https://jmvazquez.eu/activopro.html).
