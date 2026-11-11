---
id: 0035
title: Cartera de cobros y pagos — vencimientos de la factura, cobros y pagos como documento con aplicaciones, efectos y riesgo
status: proposed
date: 2026-11-11
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Segundo módulo del orden acordado en ADR-0034: **terceros → cartera → tesorería → remesas → caja**. La cartera es lo que se debe y lo que nos deben, vencimiento a vencimiento. La alimentan las facturas (ADR-0030/0031) con las condiciones de la ficha (ADR-0034). Después la consumen la tesorería (el movimiento de banco o caja que cobra o paga) y las remesas.

### Lo que hay en GeneXus

**Uso.** De 162 schemas:

| Tablas | Schemas con datos | Filas |
|---|---|---|
| `carteradecobros` / `ccbvto` / `ccbvtocob` | 94 / 96 / 80 | 275.700 / 296.152 / 215.222 |
| `carterapagos` / `cpgvto` / `cpgvtopag` | 112 / 112 / 98 | 250.929 / 260.285 / 175.070 |
| `carteraefectos` (efectos a cobrar) | 68 | 44.903 |
| `cyppdtes` (importes pendientes de aplicar) | 93 | 66.566 |
| `remesacobro` / `remesapago` | 6 / 7 | 3.869 / 1.367 |

Los efectos y los importes pendientes de aplicar se usan casi tanto como la propia cartera. Las remesas, poco.

**Modelo de GeneXus:**

- **Cabecera de la cartera.** `carteradecobros` va por cliente y factura: fecha, serie y número, importe, divisa, asiento y forma de cobro. `carterapagos` va por cuenta del proveedor o acreedor y lleva, además, los datos de la transferencia.
- **Vencimientos.** `…vto`: línea, fecha e importe. Para pagos, también la fecha y el número de remesa.
- **Cobros y pagos aplicados.** `…vtocob` / `…vtopag`: importe, fecha y número de cobro (contador `COB`), forma de cobro, cuenta de tesorería, asiento y un importe «sin riesgo» (`CcbVtoCobRis`).
- **Generación.** `AltaPrevC` / `AltaPrevP`, al contabilizar la factura, con las condiciones de la ficha (ADR-0034). Si ya hay algo cobrado no se recalcula.
- **Cobrar** (pantalla `Cobros`):
  - se eligen los vencimientos, la cuenta (caja, banco o varios) y la forma de cobro;
  - se crea el asiento: debe la cuenta elegida, haber el cliente;
  - el importe se reparte entre los vencimientos elegidos;
  - lo que sobra se apunta como cobro de más en el último vencimiento.
- **Pagar** funciona igual que cobrar. El manual (3.1) añade: el pago de más queda como pago a cuenta, y desde Bancos y Caja (4.3) el asiento se aplica a las facturas pendientes; lo que no se aplica queda en «Importes pendientes de aplicar» (`cyppdtes`).
- **Efectos:**
  - un cobro con cheque, pagaré, letra (aceptada o no) o confirming crea un efecto en `carteraefectos`, con su vencimiento, número y banco;
  - después se ingresa en banco (`Actuaefe`), de dos maneras: directo, o pasando por efectos a cobrar;
  - puede acabar impagado (`Impagado`, `CefDev`).
- **Riesgo:**
  - un cobro por remesa de descuento (norma 58) o un efecto ingresado mantienen el riesgo hasta el vencimiento más los días de riesgo de la forma de cobro (`ForCobRis`);
  - después `RebajaRiesgo` cancela el riesgo con un asiento: deudas por efectos descontados (`REMESAR3`, 5208) contra efectos descontados (`REMESAR2`, 4311);
  - efectivo, tarjeta y transferencia no generan riesgo.
- **Anular** un cobro o un pago lo deshace y crea el asiento inverso.

## Opciones consideradas

**1. Qué es un cobro o un pago.**
- a) Como en GeneXus: una línea por vencimiento, y lo que sobra, en el último vencimiento o en una tabla aparte de pendientes.
- b) **Un documento (`cobro_pago`) con su asiento y sus aplicaciones a vencimientos.** Lo que no se aplica queda en el propio documento como pendiente de aplicar, sin tabla aparte. La tesorería (el siguiente ADR) cobrará y pagará creando este mismo documento desde un movimiento de banco o caja, sin rehacerlo. **Propuesta.**

**2. Generación desde la factura.**
- a) Solo a mano.
- b) **Automática al contabilizar.** Toma las condiciones de la dirección de cobro de la factura (si tiene condiciones propias) o las del rol, y la forma de pago de la factura. Usa `app.vencimientos_propuestos` y el total a cobrar de la factura (con la retención ya restada). **Propuesta.**

**3. Factura modificada con algo cobrado.**
- a) Como GeneXus: no se recalcula y la cartera puede quedar distinta de la factura sin que nadie lo vea.
- b) **No se recalcula, pero queda el aviso `CARTERA_DESCUADRADA`** (suma de vencimientos ≠ total de la factura) en la factura y en la cartera, hasta que el usuario ajuste los vencimientos pendientes. **Propuesta.**
- c) Bloquear la modificación.

**4. Efectos.**
- a) Dejarlos para el ADR de remesas.
- b) **Incluirlos aquí: el efecto es un estado del cobro**, con su ciclo y sus asientos. Los usan 68 schemas, y sin ellos un cobro con pagaré no se puede registrar bien. **Propuesta.** El descuento y la gestión de cobro por remesa se quedan para el ADR de remesas.

## Decisión (propuesta)

### Vencimientos: `vencimiento`

- **Campos:**
  - empresa y sentido (cobro o pago);
  - papel del tercero y cuenta del tercero (430, 400, 410…);
  - factura (puede no haberla) y dirección de cobro;
  - forma de pago;
  - número dentro de la factura, fecha e importe (negativo en los abonos);
  - concepto y origen: `factura`, `manual` o `migrado`.
- **Pendiente** = importe − aplicado. El estado (pendiente, parcial, cobrado o pagado, vencido) se calcula, no se guarda.
- **Generación:**
  - `app.generar_vencimientos(factura)` se llama desde `app.contabilizar_factura`;
  - se rehace en el sitio si la factura cambia y no hay nada aplicado; si hay algo aplicado, aviso `CARTERA_DESCUADRADA`;
  - una factura con aplicaciones no se anula: primero se anulan sus cobros o pagos.
- **Edición** (`app.guardar_vencimientos`): partir, juntar, cambiar fechas y forma de pago. La suma tiene que ser el total de la factura, salvo en los vencimientos manuales sin factura, que son la previsión de un gasto o ingreso.
- **Rectificativas:** sus vencimientos negativos se compensan con los positivos del mismo tercero en un cobro o pago de importe 0, como «matar factura y abono» en GeneXus.

### Cobros y pagos: `cobro_pago` y `aplicacion`

- **El documento** (`cobro_pago`):
  - número correlativo por ejercicio y sentido;
  - fecha, papel del tercero, forma de pago;
  - cuenta de tesorería (caja, banco) o de efectos;
  - importe y concepto;
  - asiento.
- **Las aplicaciones** (`aplicacion`): documento, vencimiento e importe. Lo que queda sin aplicar es un anticipo o pago a cuenta, y se aplica más tarde a los vencimientos que lleguen.
- **El asiento:**
  - lo genera `app.contabilizar_cobro_pago`, con un origen nuevo no editable;
  - cobro: debe la cuenta de tesorería o de efectos, haber la cuenta del tercero;
  - pago: debe la cuenta del tercero, haber la de tesorería;
  - una línea por cada cuenta del tercero que intervenga;
  - se rehace en el sitio si el documento cambia, y aplican las reglas de periodos (B1).
- **Anular** quita las aplicaciones (los vencimientos vuelven a estar pendientes) y anula el asiento, que conserva su número, como un asiento anulado (ADR-0028).
- **Vista:** `app.cartera(empresa, sentido, a_fecha, filtros)` da lo pendiente por tercero y vencimiento, con antigüedad y lo vencido. Calcula lo que estaba pendiente en una fecha pasada, contando solo las aplicaciones hasta esa fecha.

### Efectos

- **Cuándo hay efecto:** cuando el medio de la forma de pago es cheque, pagaré, efecto o confirming. El cobro va entonces a la cuenta de efectos de la empresa (por defecto 4310 a cobrar y 4010 a pagar, configurables) y lleva el efecto: número, vencimiento del efecto y banco librado.
- **Estados del efecto:** en cartera → ingresado en banco (gestión de cobro o al cobro: debe banco, haber 4310) → cobrado. Si no se paga, impagado: 4315 contra banco, y el vencimiento vuelve a estar pendiente por el importe impagado, con los gastos aparte.
- **Descuento** (4311 / 5208) y gestión de cobro por remesa: van al ADR de remesas. El modelo deja sitio para ese estado.
- **En pagos:** pagaré o letra emitidos. El pago va a la 4010; al vencer, 4010 contra banco.

### Riesgo del cliente

- **`app.riesgo_cliente(rol, fecha)`** = lo pendiente + los efectos no vencidos (ingresados o descontados) hasta su vencimiento más los días de riesgo de la forma de pago. Es una columna nueva, `forma_pago.dias_riesgo` (`ForCobRis`).
- **Aviso** `RIESGO_SUPERADO` al emitir o registrar la factura si se pasa del límite de la ficha. El bloqueo de ventas ya existe en el rol (ADR-0034).

### Configuración

`empresa_config_tesoreria` añade:
- las cuentas de efectos a cobrar y a pagar;
- la cuenta de impagados;
- la de gastos de devolución.

### Módulo, API y pantallas

- **Módulo `cartera`**, con los permisos `consultar`, `preparar` (cobrar, pagar, editar vencimientos) y `configurar`.
- **Pantallas:**
  - **Cartera de cobros y de pagos:** pendiente, vencido, por tercero y a una fecha.
  - **Cobrar o pagar:** se eligen vencimientos y el importe se reparte; se ve lo que sobra como pendiente de aplicar.
  - **Pendientes de aplicar.**
  - **Efectos:** en cartera, ingresar, impagar.
  - **Vencimientos de la factura:** dentro de la propia factura.
- Textos en es/ca/en.

### ETL

- **De dónde sale:** `carteradecobros` y `carterapagos` con sus vencimientos, y los cobros y pagos agrupados por su número (`CcbVtoCobNum` / `CpgVtoPagNum`) y su asiento (`…Movid`).
- **Qué se carga:**
  - los efectos de `carteraefectos`;
  - los pendientes de aplicar de `cyppdtes`;
  - los días de riesgo de `forcob`.
- **Modo sombra:** lo pendiente por tercero frente a lo que da GeneXus.

## Preguntas abiertas para José María

1. **¿Cobro y pago como documento que la tesorería reutiliza (opción 1b)?** El movimiento de banco que cobra una factura sería ese mismo documento.
2. **¿Efectos en este ADR (opción 4b)?** El descuento y la remesa irían al ADR de remesas.
3. **¿Aviso, y no bloqueo, cuando se modifica una factura con cobros (opción 3b)?**

## Consecuencias

- La factura pasa a tener vencimientos, y la cartera queda lista para la tesorería y las remesas.
- Lo pendiente de aplicar deja de ser una tabla aparte: es lo que le queda a cada cobro o pago.
- `app.contabilizar_factura` y `app.anular_factura` cambian: generan los vencimientos, y la factura no se puede anular si tiene cobros.

## Origen

Conversación del 11/11/2026 con José María (orden de los módulos, ADR-0034). Análisis de la KB de GeneXus: `Cobros`, `Actuacob`, `Comosecobro`, `Altaefeacob`, `Actuaefe`, `RebajaRiesgo`, `CyPaltapdte`, `AltaPrevC` / `AltaPrevP`. Manual de ActivoPro, apartados 3.1, 3.2 y 4.3.
