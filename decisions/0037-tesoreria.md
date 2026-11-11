---
id: 0037
title: Tesorería — cuentas de caja y banco, movimiento como documento, extracto bancario, conciliación y previsión
status: proposed
date: 2026-11-11
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Tercer módulo del orden acordado (ADR-0034): **terceros → cartera → tesorería → remesas → caja**. La cartera (ADR-0035) ya tiene vencimientos y el documento de cobro o pago (`cobro_pago`), con su asiento y sus aplicaciones, y dejó dicho que la tesorería cobraría y pagaría con ese mismo documento.

La tesorería es lo que pasa en la caja y en el banco:

- qué cuentas tiene la empresa;
- qué entra y qué sale (el movimiento);
- qué dice el banco (el extracto);
- que lo uno cuadre con lo otro (la conciliación);
- qué va a pasar (la previsión).

### Lo que hay en GeneXus

De 162 schemas:

| Tabla | Para qué | Schemas con datos | Filas |
|---|---|---|---|
| `bancos` / `bancosbcta` | Banco (ficha de tercero) y sus cuentas: IBAN, cuenta contable, numeradores de cheques y pagarés, sufijos de las normas 19/34/58 | 47 / 45 | 171 / 201 |
| `prgama`, `prgctascab`, `prgcontrapartidas` | «Programas» de asiento (CAJA, BANCO, VARIOS, REMESAEF, IMPAGADO, TARJCOB…): qué cuentas valen en la cabecera y en la contrapartida, serie y numeración del documento | 162 | ~29.000 cada una |
| `cuadreban` | Copia de cada apunte de una cuenta de banco, con la marca de punteado (`CuaVinc`) y la fecha del extracto. Se llena sola; en los schemas revisados no se puntea desde 2020–2023 | 134 | 630.337 |
| `tmpficban`, `tmpficban1` | Extracto norma 43 cargado (temporal: se borra en cada carga) | 16 / 149 | 66.960 / 614 |
| `tplann43`, `tmpficbanconceptos`, `tmpficbanoperacion` | «Plan N43»: por cuenta, operación común y concepto propio del banco, la cuenta de contrapartida, la clave y el centro | 153 | 22.301 / 18.874 / 24.732 |
| `conbanco` | Conciliación automática (líneas del extracto vinculadas a apuntes) | 3 | 21.736 |

**Cómo funciona:**

- **Asiento de banco o caja.** El usuario elige la cuenta de cabecera de las que admite el programa BANCO o CAJA (`PValCtaPrg`) y teclea la contrapartida. Si es de un cliente o proveedor, se abre el popup de la cartera para aplicar el cobro o pago. Si se cierra sin hacerlo, queda en `cyppdtes`, lo que en TORRO resultaron ser restos (ADR-0035).
- **Punteo.** `PAltaMov2` / `PUpdMovimiento` / `pDltMovimiento` copian cada apunte de banco en `cuadreban`. El punteo (`PunConBan`) marca el apunte con la fecha del extracto. Es una copia de los apuntes mantenida a mano.
- **Extracto norma 43.** `ProFicBan` lee el fichero en registros de 80 posiciones: cabecera 11, movimiento 22, conceptos complementarios 23, final 33. Lo deja en `tmpficban`, que se borra en cada carga.
- **Conciliación.** `VinFicBan` vincula líneas del extracto con apuntes por importe y fecha y las guarda en `conbanco`. Las líneas que no se vinculan pueden contabilizarse con el plan N43. Casi nadie usa la conciliación automática (3 schemas).
- **Previsiones.** Es una consulta de la cartera.

**Fuera de GeneXus:**

- `ms-activopro-import` importa extractos (Excel) y facturas de comercio electrónico a MySQL.
- Los bancos españoles empiezan a dar el extracto en **CAMT.053** (ISO 20022, XML), además de la norma 43.

## Opciones consideradas

### 1. Cuentas de tesorería de la empresa

1. **Tabla `cuenta_tesoreria`.** Cada una con:
   - su cuenta contable (570, 572, 5201…);
   - su clase: caja, banco, tarjeta, póliza de crédito o confirming;
   - IBAN y BIC, y el banco como tercero (rol banco);
   - identificador de acreedor SEPA y sufijos, para las remesas;
   - numeradores de cheques y pagarés;
   - si está activa.

   Sustituye a `bancosbcta` y a las listas de cuentas de los programas BANCO y CAJA.
2. **Seguir deduciéndolo del plan:** banco es la 572 y caja la 570. No hay dónde guardar el IBAN, el BIC ni el identificador SEPA, que las remesas necesitan.

### 2. El movimiento de banco o caja

1. **Un asiento por movimiento, con todas sus contrapartidas, como en GeneXus.**
   - Un mismo apunte de banco puede pagar a tres proveedores y una comisión.
   - Choca con ADR-0035: cada `cobro_pago` tiene su asiento y lo rehace en el sitio. Tres pagos no pueden compartir un asiento sin que uno rehaga el de los otros.
2. **El movimiento agrupa documentos.** Un movimiento de tesorería (`movimiento_tesoreria`) lleva:
   - cuenta, fecha, fecha valor, importe y concepto;
   - lo que lo explica: uno o varios `cobro_pago` (de la cartera, cada uno con su asiento, origen `tesoreria`) y, para lo que no es cartera (comisiones, nóminas, impuestos, traspasos), un asiento de origen `banco` / `caja`.

   El banco ve un solo cargo; la contabilidad tiene un asiento por documento. La cartera no cambia.
3. **Sin documento propio:** el «asistente de banco» crea asientos y cobros sueltos, como GeneXus. No queda nada que una el cargo del banco con lo que lo explica, y conciliar es emparejar a ciegas.

### 3. Extracto bancario

1. **El extracto se guarda.** `extracto` (cuenta, periodo, saldos inicial y final, formato, fichero) y `extracto_linea`:
   - fechas de operación y valor;
   - importe con signo;
   - código común (AEB) y concepto propio;
   - textos y referencia;
   - una huella para no cargar dos veces la misma línea.

   Se carga norma 43 y CAMT.053 con un parser propio, en un paquete de la plataforma sin acceso a la base.
2. **Como GeneXus:** una tabla temporal que se vacía en cada carga. Se pierde el rastro de qué se concilió con qué.
3. **Que lo cargue ms-activopro-import.** Otro servicio escribiendo en la base de la plataforma. Va contra ADR-0027 (un solo backend) y contra los servicios autónomos.

### 4. Conciliación

1. **Enlace entre la línea del extracto y lo que la explica.** `conciliacion`: línea de extracto ↔ apuntes de la cuenta de banco, uno o varios en cada lado, con la fecha y el usuario.
   - Sin extracto se puede puntear igual: un apunte marcado con la fecha del extracto en papel, como `cuadreban`.
   - Lo conciliado y lo pendiente salen de consultas: no hay copia de los apuntes.
2. **Copia de apuntes con marca, como `cuadreban`.** Duplica datos y hay que mantener la copia en cada alta, cambio y baja de asiento.

### 5. Propuestas para lo que no concilia

1. **Reglas de la empresa**, que generalizan el plan N43. Una regla tiene:
   - condiciones: cuenta, código común, texto que contiene, signo e importe;
   - lo que propone: contrapartida, tercero y concepto.

   Además, el programa propone por su cuenta:
   - un **cobro o pago de cartera** si hay vencimientos pendientes del tercero que suman el importe, por referencia o por importe;
   - la contrapartida más usada antes con un texto parecido.

   Todo se propone y el usuario confirma («proponer sin imponer»).
2. **Solo el plan N43**, por código común y concepto propio. Muchos movimientos de hoy llevan un código genérico y la información en el texto.

### 6. Previsión de tesorería

1. **Consulta, sin tablas.**
   - Parte del saldo contable de las cuentas de tesorería.
   - Suma los vencimientos pendientes de la cartera, cobros y pagos, por su fecha.
   - Suma los efectos en cartera, por su vencimiento.
   - Da la previsión por día, semana o mes, con el detalle.
   - Los vencimientos manuales sin factura (ADR-0035) ya sirven para lo previsto que no tiene factura: nóminas, impuestos.
2. **Tabla de previsiones aparte.** Duplica lo que ya hacen los vencimientos manuales.

## Decisión (propuesta, pendiente de José María)

1. **`cuenta_tesoreria`** para las cuentas de caja y banco de la empresa, con IBAN, BIC, banco, datos SEPA y numeradores.
2. **El movimiento agrupa documentos.**
   - `movimiento_tesoreria` es la cabecera.
   - Se explica con `cobro_pago` (cartera; origen `tesoreria`) y asientos de origen `banco` / `caja` para lo que no es cartera.
   - Sustituye a los programas BANCO y CAJA. `cyppdtes` deja de tener sentido: si no se aplica, el cobro queda sin aplicar en la cartera, a la vista.
   - Los traspasos entre cuentas propias van en un único asiento que lleva los dos movimientos.
3. **El extracto se guarda.** Norma 43 y CAMT.053 se leen con un parser propio en `packages/bancos`. El Excel queda para después, con un mapeo de columnas.
4. **Conciliación por enlace**, con punteo manual sin extracto. Sin copia de apuntes.
5. **Reglas de la empresa y propuestas del programa**, siempre confirmadas por el usuario. La cartera va primero: un cobro o pago que cuadra con vencimientos pendientes.
6. **Previsión como consulta** sobre la cartera y los saldos.

Pantallas:

- portada de Tesorería, con el saldo de cada cuenta, lo pendiente de conciliar y la previsión de 30 días;
- movimientos de la cuenta, con alta del movimiento con sus documentos;
- carga del extracto y conciliación lado a lado (extracto ↔ contabilidad);
- reglas y previsión.

## Consecuencias

- **Migración.** Tablas nuevas, todas con RLS:
  - `cuenta_tesoreria`, `movimiento_tesoreria` y su enlace a `cobro_pago` y `asiento`;
  - `extracto`, `extracto_linea`, `conciliacion`, `regla_tesoreria`.

  Los orígenes de asiento `banco` y `caja` ya existen.
- **Cartera.** `cobro_pago.origen = 'tesoreria'` ya está previsto. El cobro de la pantalla de cartera sigue igual y puede asociarse después a un movimiento al conciliar.
- **ETL.**
  - Cuentas de `bancosbcta` y de los programas BANCO y CAJA (`prgctascab`).
  - Plan N43 como reglas.
  - Los punteos de `cuadreban` no se cargan. José María contó `CuaVinc` el 11/11/2026 en mconta001, mconta0037 y mconta0071, y no hay punteos en los últimos ejercicios:
    - en mconta001 y mconta0071, nada desde 2020;
    - en mconta0037, se puntearon 351 de 2.334 apuntes en 2023 y ninguno desde 2024.

    La conciliación empieza limpia con el primer extracto que se cargue.
  - `tmpficban` no se carga: es temporal.
- **ms-activopro-import.** Sigue para GeneXus. La plataforma no depende de él.
- **Remesas** (el ADR siguiente) usarán `cuenta_tesoreria` (IBAN, identificador SEPA, sufijos) y el movimiento para el abono o cargo de la remesa.
- **Caja** (el último) añadirá arqueos y cierres sobre las cuentas de clase caja.

## Origen

Orden acordado en ADR-0034 y ADR-0035. Propuesta del 11/11/2026, tras cerrar cartera y líneas comerciales.
