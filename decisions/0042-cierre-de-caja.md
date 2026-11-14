---
id: 0042
title: Cierre de caja — ventas del día por tipo, cobros, pagos, entregas y arqueo, sobre la tesorería
status: proposed
date: 2026-11-14
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Último paso del orden acordado en ADR-0034 (terceros → cartera → tesorería → remesas → **caja**). En GeneXus hay dos pantallas
fijas que generan un asiento de caja:

- **Caja venta diaria** (`IngCajaDiaria`, programa `CAJAV`, diario 17): fecha, centro, serie y número, tickets desde–hasta,
  total de ventas y hasta seis bases con su tipo y cuota (registro de IVA repercutido, libro E o F, clave de operación J), y las
  casillas tarjeta, ingreso en banco, cambio de moneda (fondo de caja), dos pagos según comprobante con texto y diferencia de
  arqueo. El total de ventas tiene que cuadrar con bases + cuotas dentro de la tolerancia `TOLDESC`. La cuenta de cabecera (la
  caja) y las de cada casilla se validan contra el programa (`PValCtaPrg`).
- **Caja farmacia** (`IngCajaFar`, `CAJAFAR`, diario 19): lo mismo y además Seguridad Social y mutuas, clientes cobrados,
  entregas a cuenta (fiado) y la taxa de la Generalitat (el euro por receta).

La diferencia de arqueo se teclea; el saldo de la caja se enseña pero no interviene. En la mayoría de schemas las dos pantallas
están bloqueadas en el perfil por defecto: las usan pocos clientes (comercio y hostelería al detalle, farmacias).

Lo que ya tiene la plataforma: cuentas de tesorería de clase caja y tarjeta (ADR-0037), movimientos con traspasos entre cuentas
propias y con cobros y pagos de la cartera (ADR-0035), el registro de IVA y la regla de periodos B1 (ADR-0028).

## Decisión

1. **Un solo documento, el cierre de caja**, configurable por empresa, en lugar de dos pantallas. Cada cierre es de una cuenta de
   tesorería de clase caja y una fecha, con **turno** (varios por día; lo normal es uno) y número por ejercicio al cerrarlo.
2. **Ventas del día por tipo** (resumen de tickets): serie y tickets desde–hasta, y una línea por tipo con base y cuota (propuesta
   por el tipo y editable, con aviso si se separa) y su cuenta de ventas; también exentas y «sin desglose» (minorista en recargo de
   equivalencia: va entera a ventas, sin registro). Generan el registro de IVA o IGIC repercutido, operación interior, clave J.
3. **Conceptos de caja** configurables (`caja_concepto`): código, nombre por idioma, entrada o salida y destino:
   - **tesorería**: traspaso entre la caja y otra cuenta propia (tarjeta o TPV, ingreso en el banco, fondo de cambio). Es un
     movimiento de tesorería con su traspaso, que en el banco se concilia con el extracto;
   - **tercero**: cobro de un cliente o pago a un proveedor o acreedor, documento de la cartera que puede aplicar vencimientos;
   - **cuenta**: contrapartida contable (gastos pagados en efectivo, Seguridad Social y mutuas, fiado a la cuenta del cliente,
     taxa por receta).
   Toda empresa puede crear el juego general (tarjeta, banco, fondo de cambio, cobro de cliente, pago a proveedor, pago de gastos)
   o el de farmacia (además Seguridad Social y mutuas, fiado y taxa).
4. **Arqueo**: se teclea el efectivo contado (o el desglose de billetes y monedas) y la diferencia es contado − teórico, donde
   teórico = saldo de la caja antes del cierre + ventas + entradas − salidas. Va a una cuenta de faltantes (659) o de sobrantes
   (759), configurables. El saldo anterior es el contable de la cuenta de caja a la fecha, sin lo del propio cierre ni lo de los
   turnos siguientes del día. Queda guardado; si lo anterior cambia después, el cierre avisa de que está desfasado.
5. **Lo que genera** al cerrarse: su asiento (origen `cierre_caja`, no editable: caja contra ventas, impuestos y diferencia de
   arqueo) y un movimiento de tesorería por línea de concepto (traspaso, cobro o pago, o contrapartida). Borrador → cerrado →
   anulado; el cerrado se corrige en el sitio (rehace su asiento y sus movimientos) y se anula con motivo. Un movimiento conciliado
   bloquea la corrección como en la tesorería. Los periodos, por la regla B1.
6. **Permisos de Tesorería**: cerrar caja es `tesoreria.preparar`; los conceptos y las cuentas, `tesoreria.configurar`.

## Opciones descartadas

- **Las dos pantallas como en GeneXus**: duplican lógica y fijan casillas que cada negocio usa de otra manera.
- **Solo el asiento**: el ingreso en el banco no se podría conciliar con el extracto ni el pago a un proveedor aplicaría su
  vencimiento.
- **Diferencia de arqueo tecleada**: el programa ya sabe el saldo de la caja; el usuario cuenta, no calcula.

## Consecuencias

- VeriFactu: los tickets los registra el TPV, que es el sistema de facturación; el cierre es el apunte contable del resumen.
- 347 y 415: el resumen de tickets (registros con clave J) queda excluido como `resumen_tickets`; son ventas a clientes sin
  identificar, que no se declaran ni deben avisar como operaciones sin tercero.
- Si la empresa no tiene cuenta de impuesto para un tipo de las ventas, el cierre crea la del plan (4770 / 4777, subcuenta 00ttnn),
  como hace la tesorería con sus cuentas por defecto.
- Sin ETL: los asientos de caja de GeneXus ya entran con la contabilidad (origen `caja`, editables como hasta ahora).
- Centros y analítica, cuando la plataforma los tenga.

## Origen

Conversación con José María del 14/11/2026 (orden de módulos de ADR-0034; decisiones: documento configurable, movimientos de
tesorería, arqueo por contado y varios turnos por día).
