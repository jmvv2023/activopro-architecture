---
id: 0050
title: Contabilidad analítica por centros, con reparto de costes aparte
status: proposed
date: 2026-11-18
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

La empresa quiere ver su cuenta de resultados por partes: por local, departamento, obra o línea de negocio. Para eso, los gastos e
ingresos se imputan a **centros**. Los costes comunes (la luz o el alquiler de la sede) se **reparten** después entre los demás con un
criterio. En el programa anterior solo la tiene activada una empresa (ver «Uso medido»; H-083).

### Cómo lo hace el programa anterior

- **Activación:** dos marcas por empresa. `EmpCenSN` (lleva centros) y `EmpSucSN` (lleva divisiones).
- El funcionamiento completo, programa por programa, está en `analysis/2026-11-analitica-genexus.md`.
- **Estructura:** `empcen` (centro) y `empdiv` (división, un catálogo **de la empresa**). `empcenlevel1` dice qué divisiones tiene
  cada centro, y la misma división puede estar en varios. Los informes salen por centro o **por división con los centros agrupados**:
  la división es una segunda dimensión que cruza los centros. Hay códigos especiales:
  - centro **9999**: «pendiente de distribuir»;
  - división **999**: pendiente dentro del centro;
  - división **0**: «general», para quien no usa divisiones;
  - centro **9876**: «(todos)» en la cabecera de un documento.
- **Qué cuentas:** las de los grupos que dicen los parámetros `CTAGAS` / `CTAVEN` (en la práctica, 6 y 7), por el primer dígito
  (`CtaAnalitca`).
- **Imputación:** `tasiimpcen` por empresa, ejercicio, asiento, línea, centro y división, con el importe y el lado.
  - El documento lleva un centro en la cabecera, y sus líneas de 6/7 van a él.
  - Una línea se puede partir entre centros a mano.
  - Lo que no se reparte queda en 9999/999 y se distribuye después desde «Pendiente de distribuir».
- **Saldos:** `sdocentros` por centro, división, cuenta y mes. Los mantiene el propio proceso y hay arreglos para regenerarlos
  (`ArreglaSldoAnalitica`, `ArreglaTasiImpCen`).
- **Reparto:** la plantilla `tplaredcen` lleva origen (cuenta + centro/división), % y destino. `prediscentro` reescribe las
  imputaciones de un rango de fechas y las marca `AsiImpRedist`, para poder deshacerlo.
- **Informes:**
  - los informes configurables por centro (`GenBalCentros`, «Personalizado con % analítica», dos periodos);
  - movimientos por centro (`MovimCen`);
  - saldos por centro.
- **El centro también es sucursal:** `tempcenparcentros` guarda cuentas de caja, efectivo, crédito y diferencias por centro para la
  caja diaria, y el `SucCod` del documento es el centro.

### Restricciones de la plataforma

- **Los asientos generados se rehacen en el sitio.** Al rehacerlos (factura corregida, cobro, cierre de caja, amortización…), sus
  apuntes se borran y se vuelven a crear. Una imputación colgada del id del apunte se perdería: hace falta lo mismo que con la
  conciliación (`conciliacion_reenlazar`).
- **Estados financieros (ADR-0017):** el motor trabaja sobre `saldo_mensual` y quedó preparado para filtrar por centro.
- **Repartos:** proponer sin imponer, y que lo automático se pueda deshacer (como los asientos de proceso o el reparto de la cartera).

## Opciones consideradas

**Estructura**
1. **Dos niveles fijos** (centro y división), como ahora, sin los códigos especiales. Fácil de explicar, pero rígido.
2. **Varias dimensiones** (centro, proyecto, línea…). Es lo más potente, pero cada apunte se imputa en cada dimensión y los informes se
   cruzan. Es mucho más complejo de usar y nadie lo pide hoy.
3. **Un árbol de centros.** Se informa a cualquier nivel. Si las divisiones de antes se hacen hijos de su centro, se pierde el total
   de una división en todos los centros, que hoy sí sale.
4. **Centro (árbol) y división (catálogo de la empresa)**, las dos opcionales, con las combinaciones permitidas por centro. Es lo de
   hoy, sin códigos especiales.

> **Decidido: el árbol (3).** El 18/11 se midió el uso en producción. Solo una empresa tiene la analítica activada (mconta0050:
> 27 centros, **sin divisiones**). La opción 4 queda como ampliación futura: la imputación admitiría una segunda dimensión sin
> rehacer el modelo.

**Reparto**
1. **Reescribir las imputaciones** con una marca, como ahora. Se pierde el «antes del reparto» y deshacer depende de que nadie haya
   tocado nada en medio.
2. **Calcularlo al informar**, sin guardarlo. No queda constancia de qué se repartió en cada cierre.
3. **Movimientos de reparto aparte** (elegida). Cada ejecución guarda los suyos, se deshace y se rehace, y la imputación original no
   se toca.

**Dónde vive la imputación**
1. **Solo en el documento de origen** (línea de factura, de caja…). No cubre el asiento manual ni la corrección posterior.
2. **Solo en el apunte.** Se pierde al rehacer el asiento.
3. **En el apunte, con su origen y reenlazado al rehacer** (elegida). Los documentos proponen el centro al generar el asiento.

## Decisión

**Configuración por empresa**
- La analítica es parte de **Contabilidad**: el administrador la activa en la configuración de la empresa. No es un módulo
  contratado.
- Permisos:
  - `contabilidad.configurar`: centros, cuentas analíticas y criterios de reparto;
  - `contabilidad.preparar`: imputar;
  - `contabilidad.cerrar`: ejecutar y deshacer repartos.
- **Cuentas analíticas:** prefijos de la empresa, por defecto 6 y 7. Se pueden añadir otros (p. ej. una 2x de inversión por obra) o
  excluir una cuenta concreta.

**Centros**
- `centro`: árbol por empresa (`padre_id`, sin ciclos), con código, nombre por idioma, activo y desde–hasta.
- Solo los centros **sin hijos** reciben imputaciones; los demás agrupan.
- No hay códigos especiales: lo que falta por imputar se calcula y se enseña como **«Sin imputar»**.

**Imputación**
- Tabla `apunte_centro`: apunte, centro e importe con el signo del apunte.
  - La suma de un apunte no pasa de su importe; lo que falta, sin imputar.
  - Lleva su `origen`: propuesta, manual o migrada.
- **Reenlazado al rehacer** (trigger diferido, como la conciliación):
  - el apunte equivalente del mismo asiento (misma cuenta y lado) recibe la imputación;
  - si el importe cambió, se reescala en proporción;
  - si ya no hay equivalente, queda sin imputar con un aviso.
- **Propuesta al generar el asiento**, de más a menos concreta:
  1. el centro de la línea del documento;
  2. el de su cabecera (factura, documento de venta, cierre de caja, cobro);
  3. el del origen: serie de factura, cuenta de tesorería o caja, almacén y ficha de inmovilizado, como la «sucursal» de antes;
  4. el de la cuenta (`cuenta.centro_id`);
  5. si no, sin imputar.
- **Edición:** desde el editor y la ficha del asiento, también en los asientos que no son editables (no cambia la contabilidad). Se
  puede repartir una línea entre centros por importe o por %.
- **Cuándo se puede cambiar:** hasta **cerrar el ejercicio**, también con el mes contable cerrado. Queda auditado.
- **Asientos fuera:** el de cierre, el de regularización y el de apertura no se imputan.

**Saldos**
- `saldo_centro_mensual` por centro, cuenta, mes y clase, mantenido por trigger y recalculable con `app.recalcular_saldos_centro`.
- La comprobación cuadra con `saldo_mensual`: imputado + sin imputar = saldo de la cuenta.

**Reparto**
- **Criterio** `reparto_centro`: origen (centro y cuentas por prefijo, o todas las analíticas) y destinos.
  - Los destinos van con **% fijo** o en **proporción a una base**: los ingresos o gastos de unas cuentas en cada centro en el mismo
    periodo, o una magnitud tecleada por centro (m², personas…).
  - Los criterios llevan orden: el reparto en cascada se hace por pasos.
- **Ejecución** `reparto_ejecucion`: un periodo (mes, trimestre o año) y el estado del criterio en ese momento. Guarda
  `reparto_movimiento` (cuenta, centro, importe: sale del origen, entra en los destinos; el redondeo, al de más peso).
- Ejecutar otra vez el mismo periodo **rehace** la ejecución; **deshacer** la borra con su motivo.
- Los informes enseñan lo imputado, los repartos y el total.

**Informes**
- Los estados de ADR-0017 por centro: un filtro de centro o rama, y una vista con **una columna por centro** (más «Sin imputar» y el
  total).
- Sumas y saldos y mayor por centro.
- Movimientos de un centro con sus repartos.
- Lo que hay sin imputar, para ir imputándolo: la bandeja de «pendiente de distribuir».
- Todo exportable por ADR-0049.

**Migración del programa anterior**
- **Centros:** `empcen` → nodo; `empcenlevel1` → hijo cuando la empresa lleva divisiones. Las divisiones 0 y 999 no son centros: lo de
  la 999 o la 0 de un centro con hijos queda en el padre, y no se imputa.
- **Imputaciones:** `tasiimpcen` → `apunte_centro` por asiento y línea. Lo de 9999, sin imputar.
- **Repartos:**
  - lo ya repartido (`AsiImpRedist = 'S'`) se carga como imputación de origen `migrada`, porque el programa anterior no guarda el
    antes;
  - `tplaredcen` → criterios de % fijo, sin ejecuciones.
- **Centro como sucursal:** los parámetros de sucursal (`tempcenparcentros`) no se cargan; en la plataforma son cuentas de tesorería
  y caja. Su centro queda como centro por defecto de esa cuenta.
- **Modo sombra:** saldos por centro frente a `sdocentros`.

**Fases**
1. Centros, cuentas analíticas, imputación (editor, ficha del asiento, sin imputar), propuesta desde facturas y la cuenta, saldos y
   estados por centro.
2. Repartos (criterios, ejecución, deshacer) e informes con repartos.
3. Propuesta desde el resto de orígenes, ETL y modo sombra.

## Consecuencias

- Desaparecen los códigos especiales y los procesos de «arreglo» de saldos: los saldos los mantiene la base y se recalculan.
- El reenlazado al rehacer asientos es la pieza delicada: se prueba con cada generador (factura, cobro, caja, amortización,
  existencias, liquidación).
- La imputación no toca la contabilidad general ni el IVA: abrir la edición hasta el cierre del ejercicio no rompe la regla B1.
- La segunda dimensión (proyecto, obra…) queda fuera. Si llega, `apunte_centro` admite una columna de dimensión sin rehacer el
  modelo.

## Uso medido (18/11/2026)

Consulta de `analysis/2026-11-analitica-genexus.md` en todos los schemas.

**Solo mconta0050 tiene la analítica activada** (empresa 1):
- 27 centros, sin divisiones;
- 45.941 imputaciones de 2008 a 2026, todas de los grupos 6 y 7;
- 378 redistribuidas, con 42 filas de plantilla de reparto;
- −1.707,05 en 9999;
- 26 fichas de inmovilizado con centro.

La cifra de «28 schemas» de EVOLUTIVOS era de schemas con las tablas, no de uso.

Consecuencias para el diseño:
- el árbol basta;
- la migración es de una sola empresa: centros, imputaciones, plantilla de reparto como criterio y centro de las fichas de
  inmovilizado;
- el modo sombra se hace con ella.

## Pendiente

- Confirmar con el cliente de mconta0050 qué informes por centro usa (`GenBalCentros` con dos periodos, `MovimCen`).

## Origen

Conversación con José María del 18/11/2026. Decidido: árbol de centros, reparto en movimientos aparte, parte de Contabilidad,
imputación editable hasta el cierre del ejercicio.
