---
id: 0018
title: Modelo de datos contable de la plataforma nueva (ola 1)
status: accepted
date: 2026-11-03
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

La ola 1 (ADR-0016) migra a los clientes que usan contabilidad sin facturación. El modelo contable es la base de todo lo demás (IVA, cartera, inmovilizado, conciliación, informes). Hechos del sistema actual, confirmados con datos (`analysis/legacy/2026-11-modelo-datos-tenant.md`):

- **Plan de cuentas por empresa**, elegido de un catálogo (pymes, sociedades…) al dar de alta la empresa y ampliable.
  - Títulos de 3 o 4 dígitos y subcuentas de título + 6 dígitos (9 o 10 dígitos en total).
  - Las cuentas de terceros son `4300`/`4000`/`4100` + código de 6 dígitos; en pantalla, el usuario ve el código de 6 dígitos del tercero.
- **No hay cabecera de asiento.** Cada apunte va a un solo lado (debe o haber) y todas las líneas de un asiento tienen la misma fecha.
- **5 asientos descuadrados** en mconta0037 (de 239.629).
- Las facturas y los cobros generan su asiento automáticamente, y **si se modifica la factura se actualiza el asiento**.
- **Cierre por mes y cierre de IVA por mes o trimestre.** Al cerrar el IVA se genera el fichero del 303 y queda cerrado el periodo; se puede reabrir para incorporar algo y volver a cerrar.
- `MovDiario` clasifica el origen del asiento (unos 25 valores).

## Decisión

### Entidades

| Entidad | Ámbito | Contenido |
|---|---|---|
| `plan_modelo` | Global | Planes del catálogo (PGC general, pymes…) con sus títulos |
| `cuenta` | Empresa | Título padre, subcuenta (6 dígitos), código completo, nombre, imputable sí/no, tercero asociado, activa |
| `ejercicio` | Empresa | Fechas de inicio y fin, estado, plan |
| `periodo` | Ejercicio × mes | Cerrado contable, cerrado IVA; cada cierre y reapertura auditado |
| `origen_asiento` | Global | Catálogo de orígenes: manual, caja, banco, remesa, factura emitida, factura recibida, nómina, amortización, existencias, apertura, regularización, cierre, importado… |
| `asiento` | Empresa | Ejercicio, número, fecha, origen, concepto, origen (manual, factura, cobro, amortización, apertura, cierre, regularización…) y referencia al documento de origen |
| `apunte` | Asiento | Línea, cuenta, lado (debe/haber), importe, **cuenta de contrapartida**, concepto, documento, divisa |
| `registro_iva` | Apunte | Tipo (repercutido/soportado), **tipo de operación** (interior, intracomunitaria, exportación, importación, aduanas, ISP, tercer país), **impuesto** (IVA/IGIC), bien de inversión, base, porcentaje, cuota, deducibilidad (total, parcial, prorrata, no deducible), clave de operación, país |
| `retencion` | Apunte | IRPF: clave, base, porcentaje, cuota |
| `declaracion` | Empresa × modelo × periodo | Estado (generada, presentada, reabierta), fichero, histórico de reaperturas |
| `saldo_mensual` | Cuenta × mes | Debe y haber acumulados; derivado |

### Reglas en la base de datos

- Un apunte tiene un solo lado. El **importe lleva signo**: las rectificativas se registran en negativo en el mismo lado (p. ej. `N/FRA.DE RECT.` con debe negativo en la cuenta del cliente). Se admite importe 0 (líneas que soportan registro de IVA con cuota 0).
- **Un asiento cuadra** (Σ debe = Σ haber), comprobado al commit.
  - Excepción: asientos migrados con descuadre heredado, marcados como tales; nunca para asientos nuevos o modificados.
- No se crean ni modifican asientos en periodos cerrados ni en ejercicios cerrados; desbloqueo solo explícito y auditado (ADR-0013, punto 11).
- `saldo_mensual` se actualiza en la misma transacción que los apuntes y se puede recalcular por empresa y ejercicio.

### Diario: se separa en dos conceptos

En GeneXus, `MovDiario` (unos 60 valores fijos en el código, ver `domain/contabilidad-legacy.md`) mezcla el **origen** del asiento con el **tratamiento de IVA** (tipo de operación, IVA o IGIC, bien de inversión). En el modelo nuevo:

- el origen es un campo del asiento (`origen_asiento`);
- el tratamiento de IVA son atributos del registro de IVA.

El libro de IVA, el SII y los modelos se calculan a partir de los atributos del registro de IVA, no de un código de diario. El ETL traduce cada código de diario a origen + atributos con una tabla de correspondencia. `MovCab` no se migra: se deduce del origen.

### Cierre y apertura del ejercicio

Se conservan las reglas actuales (detalle en `domain/contabilidad-legacy.md`):

- **Cierre**, con estas condiciones previas:
  - ejercicio aperturado;
  - último mes contable cerrado;
  - IVA del último mes cerrado;
  - amortizaciones de inmovilizado y de préstamos contabilizadas.

  Genera dos asientos: regularización (grupos 6 y 7 contra la 129) y cierre de todas las cuentas.
- **Apertura**: requiere el ejercicio anterior cerrado. Traslada los saldos finales; el resultado de la 129 va a la 121 (pérdidas, subcuenta por ejercicio) o a la 123 (ganancias). Las cuentas son configurables por empresa.
- **Deshacer** cierre y apertura sigue siendo posible, auditado.
- **Cambio:** los asientos de apertura y cierre no necesitan la cuenta puente `999 000000`; sus apuntes no llevan contrapartida. En el ETL, la contrapartida `999 000000` de esos diarios se migra como vacía.

### Contrapartida

- En GeneXus, **todas** las líneas de `movctas` (760.233 de 760.233 en mconta0037) tienen cuenta al debe y cuenta al haber; el importe va a un solo lado. Una es la cuenta del apunte y la otra su contrapartida, que el mayor muestra en la columna CTRPDA.
- La contrapartida no siempre se puede deducir (en un asiento de varias líneas, la del cliente es la venta y no el IVA), así que se **guarda en cada apunte**. Los asientos automáticos la fijan al generarse; en los manuales se propone y el usuario la puede cambiar.

### Asientos automáticos: las mismas puertas que hoy, ninguna nueva

Criterio de José María (03/11/2026): no se puede ser del todo rígido (clientes y asesores hacen ajustes, también fiscales, bajo su responsabilidad), pero tampoco dejar hacer de todo, porque los descuadres acaban llegando al cierre del ejercicio. **Se mantienen las puertas abiertas que existen hoy y no se abren nuevas**, para no acabar en ajustes a medida.

- **Asientos manuales:** libres, como hoy. Es la vía para los ajustes contables y fiscales.
- **Asientos de documentos que hoy son de solo consulta** (facturación, remesas de cobro y de pago, albaranes de tercero; diarios 16, 34, 35, 36 y 37): no editables. Se corrigen desde el documento, que regenera el asiento.
- **Asientos automáticos que hoy son editables** (banco, caja, amortizaciones, existencias, nóminas…): siguen siendo editables, y la edición queda registrada en el audit log.
- Cada origen de asiento tiene en el catálogo un indicador de editable sí/no que reproduce el comportamiento actual. Cambiarlo es una decisión de producto, no una opción por cliente.
- **No se añaden** una acción genérica de "desvincular" ni la aceptación de diferencias entre documentos con tolerancia. Si se plantean, se tratan aparte como decisión de producto.
- **Precisión:** los precios unitarios admiten más de 2 decimales (los proveedores usan 3 o más); los importes de línea y totales se redondean a 2. No es una puerta nueva: evita diferencias de redondeo.

### Códigos de cuenta

- Código completo de **10 posiciones fijas**: título en 4 (con espacio a la derecha si es de 3 dígitos) + subcuenta de 6. Ejemplos: `705 000000`, `572 000001`, `4312000000`. Es el formato que ya muestra ActivoPro en el mayor; ordena bien y permite filtrar por prefijo (grupos, rangos en informes).
- La interfaz muestra y acepta el código como lo usa hoy cada pantalla (por ejemplo, el código de 6 dígitos del tercero).

## Migración

- **Títulos y subcuentas** de `tctactble` → `cuenta`. El plan modelo se identifica comparando con `defctactable`.
- **Contrapartida**: cuenta del apunte según `MovTipo` (`D` → `MovDCta*`, `H` → `MovHCta*`); la otra es la contrapartida. Confirmado en mconta0037: las líneas `D` solo tienen importe al debe y las `H` solo al haber.
- **Asientos**: cabecera derivada de las líneas de `movctas` con el mismo ejercicio y `MovId`; fecha y diario comunes.
- **IVA e IRPF**: `movctaslevel1` y `movctaslevel2` → `registro_iva` y `retencion`.
- **Periodos**: `paramejerlevel1` → `periodo`.
- **Origen de cada asiento** (factura, cobro…): se deriva del diario y de los vínculos de los documentos. En la ola 1 no hay facturación, así que la mayoría serán manuales o de cartera.
- **Paridad**: `saldo_mensual` recalculado frente a `saldoslevel1`, por empresa, cuenta y mes. Segunda comprobación: el mayor (saldo anterior y movimientos por cuenta y periodo) generado por ambos sistemas.

## Consecuencias

- El asiento pasa a ser una entidad con cabecera y origen: se puede navegar de asiento a documento y viceversa.
- Las reglas de cuadre y de periodos cerrados pasan de la aplicación a la base de datos.

## Pendiente

- Tabla de correspondencia diario → origen + atributos de IVA (se construye con `domain/contabilidad-legacy.md` y se valida en el modo sombra con libros de IVA y modelos).
- Diarios 14 y 50 guardan solo el deducible y la cuota se calcula: el ETL la reconstruye.
- Los asientos del diario 99 (importados) no actualizan los saldos de GeneXus: el comparador los excluye o los trata aparte.
- Al migrar: los asientos automáticos de orígenes editables que se modificaron a mano en GeneXus se importan tal cual, como editados; el modo sombra los identifica al comparar con lo que generaría el documento.

## Origen

Conversación con José María del 03/11/2026 y comprobaciones sobre mconta0037.
