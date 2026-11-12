---
id: 0038
title: Remesas — cobro por adeudo directo SEPA y pago por transferencia SEPA, como documento que agrupa vencimientos de la cartera
status: accepted
date: 2026-11-12
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Cuarto módulo del orden acordado (ADR-0034): **terceros → cartera → tesorería → remesas → caja**. Lo que ya hay:

- **Cartera (ADR-0035):** vencimientos de cobro y pago, y el documento de cobro o pago (`cobro_pago`) con su asiento y sus aplicaciones. También están los efectos (en cartera, ingresado, impagado) y la devolución como impagado (4315, vencimiento nuevo de origen `impagado`).
- **Terceros (ADR-0034):**
  - cuentas bancarias del tercero (IBAN validado) y la cuenta de cargo o de abono de cada relación;
  - mandatos SEPA del cliente (referencia, CORE/B2B, recurrente o único, firma, último cobro, caducidad a los 36 meses sin uso);
  - formas de pago con medio `domiciliacion` y la marca `remesable`.
- **Tesorería (ADR-0037):**
  - la cuenta de banco con IBAN, BIC, identificador de acreedor SEPA y sufijo;
  - el movimiento de banco, que agrupa cobros y pagos de la cartera, cada uno con su asiento contra el banco;
  - el extracto y la conciliación.

Una remesa es exactamente eso: **un cargo o abono del banco que agrupa muchos cobros o pagos**.

### Lo que hay en GeneXus

- **Remesa de recibos** (`Remesacobro`, `Remesard*`):
  - cabecera con banco, fechas de emisión y de cargo, norma, sufijo, presentador y acreedor original;
  - líneas por vencimiento con el mandato, el IBAN/BIC, la secuencia (`RemSeqTp`) y la marca de devolución.
- **Presentación** (`Presenremrec`): fichero `AdeudoDirectoSEPAxml` (pain.008) o el antiguo `Norma19rec`.
- **Liquidación** (`Remesardcon`), en dos modos (`ParamRemRec`, parámetros `REMESAR1…7`):
  - **gestión de cobro**: banco contra 4312 «efectos comerciales en gestión de cobro», y 4312 contra cada cliente;
  - **descuento**: 4311 «efectos descontados» contra 5208 «deudas por efectos descontados».
  - En los dos, comisiones y otros gastos con IVA, intereses sin IVA y una factura de gastos del banco con la numeración de las recibidas.
- **Devoluciones**: marca en la línea (`RemLinDev`) y asiento de impagado.
- **Órdenes de pago por transferencia** (`Remesapago`, `Remesatr*`): fichero `TransferenciaSEPAxml` (pain.001) o el antiguo `Norma341`, y contabilización del pago.
- **Remesa de efectos** (`Remesaef`): ingreso de efectos en el banco. En la plataforma ya lo cubre `app.liquidar_efecto` (ADR-0035).

Las normas 19 y 34 de texto de la AEB dejaron de admitirse con SEPA (2014–2016). Los bancos españoles aceptan los XML ISO 20022 pain.008.001.02 y pain.001.001.03, y la mayoría también las versiones de 2019.

## Opciones consideradas

### 1. Qué es una remesa

1. **Documento `remesa`** (cobro o pago), con estado y líneas, una por vencimiento con su importe:
   - Estados: borrador → generada (fichero) → presentada → liquidada (cobros y pagos hechos) → con devoluciones.
   - Un vencimiento no puede estar en dos remesas vivas.
   - Al liquidar se crea **un movimiento de tesorería** con un cobro o pago por tercero, y la conciliación lo enlaza con la línea del extracto.
2. **Solo el fichero**: elegir vencimientos y descargar el XML, sin guardar nada. No impide remesar dos veces el mismo recibo, ni sabe qué se devolvió.

### 2. Formatos

1. **Solo SEPA XML:** pain.008 para adeudos (CORE y B2B) y pain.001 para transferencias, en las versiones de 2009 (las que acepta todo banco) con la de 2019 elegible por cuenta. El generador va en un paquete sin acceso a la base, como `@activopro/bancos`.
2. **También las normas 19 y 34 de texto.** Ningún banco las admite ya.

### 3. Contabilización de la remesa de cobros

1. **Al cobro, en la fecha de cargo:** la liquidación crea el movimiento de tesorería y cada cobro va contra el banco. Entre la presentación y el cargo, los vencimientos quedan reservados (estado «en remesa»), sin asiento.
2. **Como GeneXus, con cuenta puente:** al presentar, 4312 contra clientes; al liquidar, banco contra 4312. Son dos asientos por remesa, y el saldo de la 4312 hay que vigilarlo.

### 4. Descuento (anticipo) de remesas

1. **Ahora, como segundo modo de la liquidación** (decidido):
   - el banco anticipa contra 5208 «deudas por efectos descontados»;
   - al vencimiento sin devolución, 5208 contra 4311;
   - con devolución, 5208 contra banco e impagado.
   - Usa el mismo riesgo de cliente que ya hay (`app.riesgo_cliente`).
2. **Más adelante:** solo gestión de cobro.

### 5. Gastos de la remesa

1. **Contrapartidas del mismo movimiento:** comisiones (626), intereses (665/669) y gastos de devolución, con el IVA solo si el banco lo factura; en ese caso, la factura recibida se registra aparte y se concilia.
2. **Factura de gastos obligatoria como en GeneXus.** Las comisiones bancarias suelen estar exentas, así que forzarla complica el caso habitual.

### 6. Devoluciones (cobros)

1. **Devolver una línea de la remesa:**
   - Desde la conciliación (la línea del extracto «devolución recibo») o a mano.
   - Anula la aplicación del cobro de ese vencimiento y lo deja como impagado (4315 y vencimiento nuevo de origen `impagado`, como `app.impagar_efecto`).
   - Gastos de devolución a la 626, repercutibles al cliente como cargo en el nuevo vencimiento.
2. **Devolución solo contable** (un asiento a mano), que deja la cartera sin saber qué se devolvió.

### 7. Mandatos y secuencia

1. **Validar al generar:**
   - mandato vigente (`app.mandato_vigente`), IBAN válido, identificador de acreedor de la cuenta;
   - CORE y B2B no se mezclan en un mismo fichero.
   - Secuencia: RCUR para los recurrentes (desde 2016 no hace falta FRST) y OOFF para los únicos.
   - Al presentar, se pone la fecha del último cobro del mandato.
2. **Sin validar:** el banco rechaza el fichero o los recibos.

## Decisión

Decidido por José María el 12/11/2026, todo:

- **4.1 Descuento ahora**, como segundo modo de la liquidación.
- **2.1 Solo SEPA XML.**
- **Recurrencias en un ADR propio**, después de este.

Y, confirmado después del razonamiento:

- 1.1 Remesa como documento.
- 3.1 Cobro en la fecha de cargo, sin cuenta puente (razonamiento abajo).
- 5.1 Gastos como contrapartidas del movimiento.
- 6.1 Devolución de la línea, que la deja impagada.
- 7.1 Validación de mandatos.

### Por qué sin cuenta puente en la gestión de cobro (3.1)

- **Contable.**
  - La 431x del PGC es para créditos formalizados en efectos (letras, pagarés). Un recibo SEPA domiciliado no es un efecto: es una orden de adeudo sobre un mandato.
  - Mientras el banco no abona, el derecho de cobro sigue siendo el mismo frente al mismo cliente. Incluso después del abono, en CORE el deudor puede pedir el reembolso en 8 semanas.
  - Pasarlo a la 4312 al presentar es una reclasificación dentro de clientes que no cambia el activo ni el riesgo. El balance es igual de correcto con el saldo en la 430, y lo es también a fin de ejercicio con remesas presentadas y sin cargar.
- **Funcional.**
  - Que el recibo está «en gestión de cobro» lo dice la cartera: el vencimiento queda reservado, con estado «en remesa», y aparece así en la cartera, el riesgo y la previsión con la fecha de cargo. No hace falta una cuenta para saberlo.
  - Un solo asiento por cobro, en la fecha de cargo, que es la del abono en el extracto: la conciliación es directa.
  - No hay saldo de 4312 que vigilar ni que cuadrar con la cartera. En GeneXus ese saldo se descuadra cuando se anula o modifica una remesa.
- **El descuento sí cambia la contabilidad.** El banco adelanta dinero, que es una financiación. Al liquidar:
  - el banco contra la 5208;
  - los clientes a la 4311, efectos descontados (el cliente sigue debiendo y el riesgo no se transfiere).
  - Al vencimiento sin devolución, la 5208 contra la 4311.
  - Con devolución, la 5208 contra el banco, y el cliente pasa a impagado.

## Consecuencias

- **Modelo.**
  - Tablas `remesa` y `remesa_linea` (RLS).
  - `remesa_linea` enlaza el vencimiento, el mandato (cobros) o la cuenta bancaria del tercero (pagos), el importe y el estado de la línea (incluida, devuelta).
  - La remesa liquidada enlaza su `movimiento_tesoreria`.
- **Funciones.**
  - `app.guardar_remesa`: propone los vencimientos remesables pendientes hasta una fecha, por forma de pago y banco.
  - `app.generar_remesa`: valida y devuelve los datos del fichero.
  - `app.presentar_remesa`, `app.liquidar_remesa` (con gastos y, si se decide, descuento), `app.devolver_linea` y `app.anular_remesa` (solo sin liquidar).
- **Paquete del fichero.** Los XML pain.008 y pain.001 los genera un paquete (`@activopro/sepa` o dentro de `@activopro/bancos`), con tests contra los esquemas XSD oficiales y los caracteres permitidos por SEPA, como `LetrasSEPA`.
- **API y pantallas.**
  - Módulo `remesas` con sus permisos (consultar, preparar, presentar).
  - Pantallas: portada (remesas por estado e importes), alta con la propuesta de vencimientos, detalle con validaciones y descarga del fichero, liquidación y devoluciones.
  - Desde la conciliación de Tesorería, la línea del extracto que coincide con una remesa presentada propone liquidarla.
- **ETL:** remesas de GeneXus solo como histórico de las líneas (qué vencimiento fue en qué remesa y si se devolvió), sin reconstruir ficheros. Con la prioridad del momento, se aplaza hasta que haya importación de clientes.

## Origen

Conversación del 12/11/2026 con José María: tras tesorería, «remesas y pagos recurrentes».
