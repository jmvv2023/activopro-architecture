# Contabilidad en GeneXus — reglas extraídas de la KB

Extraído del export de la KB (`APGX16`, 03/11/2026) para la migración (ADR-0016, ADR-0018). Describe **cómo funciona hoy**; el modelo nuevo está en ADR-0018.

## Motor de asientos

- **`PAltaMovimiento`** (~4.800 líneas) es el punto único de alta de asientos para todos los programas. Recibe una estructura (`MovPar`) con un `PrgId` que indica el programa de origen y, según él, decide:
  - el diario;
  - los registros de IVA, recargo de equivalencia, IRPF, prorrata y deducible parcial;
  - el IVA intracomunitario y de importación;
  - los apuntes bancarios para la conciliación;
  - los adjuntos.
- **`PUpdMovimiento`** modifica y **`pDltMovimiento`** elimina.
- **`PCrea`** actualiza los saldos (`saldos`, `saldoslevel1`) y **`AltaCtaCorriente`** el índice por cuenta (`ctacorriente`).
- Los asientos múltiples (diarios 12, 14, 15, 17, 19, 34, 35, 36, 48, 50, 51, 82) actualizan saldos y cuenta corriente una sola vez, al final.

## Diarios (`MovDiario`)

No hay tabla de diarios: los valores están fijos en el código. El diario **mezcla dos cosas**: el **origen** del asiento y el **tratamiento de IVA** (tipo de operación, territorio IVA/IGIC, bien de inversión). De él dependen el libro de IVA, el SII y los modelos 303/390.

| Diario | Significado |
|---|---|
| 1 | Caja |
| 2 | Inversión / Nóminas |
| 3 | Facturas emitidas, operaciones interiores |
| 4 | Facturas recibidas, inversiones |
| 5 | Facturas recibidas, agentes de aduana e IVA de importación (servicios) |
| 6 | Facturas recibidas, importaciones |
| 7 | Facturas recibidas, adquisición intracomunitaria de bienes |
| 8 | Varios |
| 9 | Banco |
| 10 | Autoliquidación de IVA |
| 11 | Facturas recibidas, compras, gastos y servicios |
| 12 | Varios, asiento múltiple |
| 13 | Nóminas (FETDB) |
| 14 | Varios múltiple, facturas recibidas (solo guarda el deducible; la cuota se calcula) |
| 15 | Varios múltiple, facturas expedidas |
| 16 | Remesa de pagos (no modificable) |
| 17 / 19 | Caja venta diaria / caja farmacia |
| 18 | Amortizaciones |
| 20 / 21 | Facturas recibidas Canarias: inversiones / compras, gastos y servicios |
| 22 | Facturas expedidas Canarias, operaciones interiores |
| 23 | Facturas recibidas, adquisición intracomunitaria de bienes de inversión |
| 24 | Facturas recibidas, servicios intracomunitarios |
| 25 | Facturas expedidas intracomunitarias |
| 26 | Facturas expedidas, exportaciones |
| 27 | Facturas recibidas, aduanas, importaciones a libre práctica |
| 28 | Facturas expedidas Canarias, exportaciones |
| 29 | Facturas recibidas Canarias, importaciones |
| 30 | Facturas recibidas, agentes de aduana e IGIC de importación |
| 31 / 32 | Regularización de existencias (mensual / apertura) |
| 33 | Asientos personalizados |
| 34 | Remesas de recibos domiciliados (solo consulta) |
| 35 / 36 | Facturas emitidas por el programa de facturación / ídem Canarias (solo consulta) |
| 37 | Albarán de tercero (solo consulta) |
| 38 / 39 | Factura de tercero / ídem Canarias |
| 40 | Facturas recibidas, agentes de aduana e IVA de importación (inversión) |
| 41 | Facturas recibidas, aduanas libre práctica, bienes de inversión |
| 42 | Facturas recibidas, inversión del sujeto pasivo (excepto adquisiciones intracomunitarias) |
| 43 | Ídem, Canarias |
| 44 | Facturas recibidas, importaciones de bienes de inversión |
| 45 | Facturas recibidas, agentes de aduana e IGIC (inversión) |
| 46 | Facturas recibidas, importaciones IGIC de bienes de inversión |
| 47 | Facturas recibidas, ISP operaciones inmobiliarias |
| 48 | Facturación |
| 49 | Facturas emitidas por ISP (chatarra, casilla 61) |
| 50 | Varios múltiple, facturas recibidas Canarias (solo deducible) |
| 51 | Varios múltiple, facturas expedidas Canarias |
| 52 / 53 | Facturas emitidas a tercer país: operación interior / intracomunitaria |
| 82 | Carga inicial de acumulados anuales |
| 88 | (solo en informes del diario general) |
| 91 | Apertura |
| 92 | Cierre de pérdidas y ganancias (regularización) |
| 93 | Cierre de todas las cuentas |
| 94–105 | Agrupaciones internas de los generadores de resúmenes de IVA/IGIC y del 390 |
| 99 | Importado de otro programa contable / movimiento de programa externo |

Los asientos de los diarios 16, 34, 35, 36 y 37 se marcan como "solo consulta, no modificar, no borrar": pertenecen a su documento de origen.

## `MovCab`

Indica en qué lado (`D`/`H`) está la cuenta "principal" del asiento. En los asientos bancarios: "indica dónde está la cuenta del banco". Vacío en el resto. En el modelo nuevo se deduce del origen y de la cuenta, así que no se migra como campo propio.

## Saldos

- `saldos` guarda por cuenta y ejercicio los acumulados de apertura (`AcCtaApD/H`) y cierre (`AcCtaCiD/H`); `saldoslevel1`, los de cada mes.
- El asiento de cierre de todas las cuentas (diario 93) **no** actualiza saldos.
- Los asientos del diario 99 (importados) **no** actualizan saldos. El comparador del modo sombra lo tiene en cuenta.

## Periodos y fechas permitidas

- **Cierre de periodo** (`CerrarPeriodo`): marca meses como cerrados, contables (`EjerMesCer`) o de IVA (`EjerMesCerIVA`).
- **Ventana de contabilización** (`Devfechacon`): solo se puede contabilizar entre el mes siguiente al último mes cerrado y el final del último ejercicio abierto. Puede haber varios ejercicios abiertos a la vez.
- El código de ejercicio tiene 4 caracteres (`2013`) u 8 si el ejercicio no es natural (`20132014`).

## Cierre del ejercicio (`Cierre`)

**Condiciones:**
- el ejercicio está aperturado;
- el último mes contable está cerrado;
- el IVA del último mes está cerrado;
- las amortizaciones de inmovilizado y de préstamos del año están contabilizadas;
- existe la cuenta de pérdidas y ganancias.

Si el ejercicio siguiente ya está aperturado, se recomienda retirar esa apertura y volver a hacerla después del cierre.

**Genera dos asientos**, con fecha de fin de ejercicio:
1. **Regularización** (diario 92): el saldo de cada subcuenta de los grupos 6 y 7 contra la 129. Marca el ejercicio como cerrado (`EjerCerr`) y guarda el asiento (`EjerAsiPyG`).
2. **Cierre de todas las cuentas** (diario 93): el saldo de cada subcuenta contra una cuenta puente `999 000000` con importe 0 en la contrapartida.

## Apertura del ejercicio (`Apertura`)

- **Condición:** el ejercicio anterior está cerrado.
- **Asiento de apertura** (diario 91), con fecha de inicio de ejercicio: el saldo final de cada subcuenta del ejercicio anterior, contra la cuenta puente `999 000000`.
- **El saldo de la 129 se traspasa:**
  - si son pérdidas, a la 121 + subcuenta derivada del ejercicio (`00` + año), que se crea si no existe ("RESULTADO NEGATIVO EJERCICIO …");
  - si son ganancias, a la 123 000000.
- Las cuentas son configurables por empresa con los parámetros `PYGCTA`, `PERDICTA` y `GANACTA`.
- Marca el ejercicio como aperturado (`EjerAper`, `EjerAsiAper`).

## Deshacer

`Retiracierre` y `Retiraapertura` eliminan los asientos generados y desmarcan el ejercicio. El procedimiento esperado para rehacer un cierre: retirar la apertura siguiente → retirar el cierre → corregir → cerrar → aperturar.

## Parámetros de empresa (`pdefecto`, `Getparametro`)

Unos 20 parámetros, entre ellos:
- cuentas de cierre (`PYGCTA`, `PERDICTA`, `GANACTA`);
- sujeto a SII (`SIIPRES`);
- configuración SMTP (`SHOST`, `SPORT`, `SUSERN`…);
- FTP;
- suplidos;
- contrapartidas bancarias (`BANCTR1/2`).

Son parametrización de empresa (ADR-0015, capa 2).
