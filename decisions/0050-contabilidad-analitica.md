---
id: 0050
title: Contabilidad analítica por centros, con reparto de costes aparte
status: accepted
date: 2026-11-18
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

La empresa quiere ver su cuenta de resultados por partes: por local, departamento, obra o línea de negocio. Para eso, los gastos e
ingresos se imputan a **centros**. Los costes comunes (la luz o el alquiler de la sede) se **reparten** después entre los demás con un
criterio. En el programa anterior la usan nueve empresas de ocho schemas (ver «Uso medido»; H-083).

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
4. **Dos dimensiones independientes:** el centro y, aparte, la línea, con las combinaciones permitidas. Es más general, pero el usuario
   elige dos cosas en cada reparto, y los informes y el reparto de costes se complican.
5. **Árbol con línea transversal** (elegida). Se imputa a un solo nodo. Las hojas que son una combinación sede × línea llevan el atributo
   **línea**, de un catálogo de la empresa. Los informes salen por el árbol, por línea (todas las sedes juntas) o en matriz. Es lo que
   el programa anterior hace con sus combinaciones centro × división, y quien no tiene líneas no lo ve.

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
- La analítica es un **módulo contratado** (`analitica`): va con los planes Estándar, Premium y Asesorías, no con el Básico. Lo da
  de alta Enumbers en la consola; dentro del cliente, el administrador la activa en cada empresa que la quiera. Sin el módulo vigente
  no se propone ni se imputa nada, y lo ya imputado se conserva. *(Cambio del 18/11/2026, decidido por José María: en la primera
  versión era parte de Contabilidad y no se contrataba.)*
- Permisos:
  - `analitica.configurar`: activar, centros, líneas y cuentas analíticas (y, en la fase 2, los criterios de reparto);
  - `analitica.preparar`: imputar, y el centro de una factura o de una ficha de inmovilizado;
  - `analitica.consultar`: pendiente, saldos e imputación de un asiento;
  - `analitica.repartir`: ejecutar, rehacer y deshacer repartos (fase 2).
- **Cuentas analíticas:** prefijos de la empresa, por defecto 6 y 7. Se pueden añadir otros (p. ej. una 2x de inversión por obra) o
  excluir una cuenta concreta.

**Centros**
- `centro`: árbol por empresa (`padre_id`, sin ciclos), con código, nombre por idioma, activo y desde–hasta, y `linea_id`
  opcional.
- `linea_analitica`: catálogo de la empresa (código, nombre por idioma, activa). Es la división de antes: CSMIJ, DOCÈNCIA… que se
  repite en varias sedes.
- **Se imputa a cualquier nivel del árbol.** Lo que se queda en un nodo con hijos es de ese nodo, y en el informe por líneas sale como
  **«Sin detallar»**.
- No hay códigos especiales: lo que falta por imputar se calcula y se enseña como **«Sin imputar»**.

**Imputación**
- Tabla `apunte_centro`: apunte, centro e importe con el signo del apunte.
  - La suma de un apunte no pasa de su importe; lo que falta, sin imputar.
  - Lleva su `origen`: propuesta, manual o migrada.
- Las garantías que tiene que cumplir están en «Garantías de la imputación», más abajo.
- **Reenlazado al rehacer** (trigger diferido, como la conciliación):
  - lo que era solo **propuesta** no se reenlaza: se vuelve a proponer con los datos de ahora (así un centro cambiado en la factura
    llega al asiento);
  - lo **puesto a mano** (o reenlazado de lo puesto a mano): el apunte equivalente del mismo asiento (misma cuenta y lado) recibe la
    imputación;
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

**Garantías de la imputación**

El programa anterior tiene errores en producción en mconta0050: incidencias «Error distribución analítica I y II», de agosto de 2026,
que se arreglan a mano en `tasiimpcen` y regenerando saldos. Dos casos:
- **Pendiente que se queda.** El pendiente es una fila más (9999.999 o 9999.0). Al distribuir la línea entera, a veces la fila de
  pendiente sigue ahí, sobre todo cuando lleva el código de división que no le toca a la empresa. Entonces la línea suma más que el
  apunte y sigue saliendo en «Pendiente de distribuir».
- **Lado que no es el del apunte.** La imputación guarda su propio D/H, cuenta, fecha y nombres. En el asiento 945 el apunte es al debe
  de la 631, y sus imputaciones están al haber, una de ellas duplicada en 9999. El informe «Movimientos que no cuadran» lo detecta
  después, pero nada lo impide.

La plataforma lo impide por construcción, no por un informe de descuadres:

1. **El pendiente no se guarda.** «Sin imputar» = importe del apunte − suma de sus imputaciones, y se calcula siempre. No hay filas
   de pendiente que puedan quedarse.
2. **La imputación no copia nada del apunte.** No guarda lado, cuenta, fecha ni nombres: los toma del apunte por su clave. El importe
   lleva el signo del apunte; un trigger rechaza el signo contrario.
3. **Un centro, una vez por apunte:** `unique (apunte_id, centro_id)`. La suma de las imputaciones de un apunte nunca pasa de su
   importe; lo comprueba un trigger diferido al confirmar la transacción.
4. **Se escribe entera, en un solo paso.** `app.guardar_imputacion(empresa, apunte, lista)` sustituye la imputación completa del
   apunte, con el apunte bloqueado (`for update`). Así no hay altas sueltas que dejen restos, ni dos usuarios pisándose. La aplicación
   no escribe en la tabla.
5. **Solo lo que se puede imputar:**
   - apuntes de cuentas analíticas de la empresa;
   - centros activos de la misma empresa;
   - nunca los asientos de apertura, regularización o cierre, ni los anulados (al anular, la imputación se va con los apuntes).
6. **Nada huérfano:**
   - el apunte borrado se lleva su imputación;
   - al rehacer un asiento en el sitio, el trigger reenlaza la imputación o la deja sin imputar con aviso;
   - cambiar una cuenta a no analítica avisa de las imputaciones que tiene y no las borra en silencio.
7. **Saldos por trigger, comprobables.** `saldo_centro_mensual` + sin imputar = `saldo_mensual` de las cuentas analíticas.
   - `app.comprobar_analitica(empresa, ejercicio)` lo verifica: tiene que dar cero diferencias.
   - Los tests lo comprueban tras cada operación (imputar, rehacer un asiento, anular, reenlazar, reparto).
8. **Auditoría.** Cada cambio de imputación queda en el audit log con usuario y motivo, también con el mes contable cerrado.

**Saldos**
- `saldo_centro_mensual` por centro, cuenta, mes y clase, mantenido por trigger y recalculable con `app.recalcular_saldos_centro`.
- La comprobación cuadra con `saldo_mensual`: imputado + sin imputar = saldo de la cuenta.

**Reparto** (detalle decidido el 18/11/2026)
- **Criterio** (`reparto_criterio`, con orden):
  - **origen:** el saldo de un centro (solo lo suyo, no lo de sus hijos) **o lo sin imputar**, de unas cuentas (por el principio del
    código) o de todas las analíticas;
  - **destinos** (`reparto_destino`): centros de cualquier nivel, nunca el de origen;
  - **base:** % fijo por destino (si suman menos de 100, el resto se queda en el origen), **en proporción a unas cuentas** (su saldo
    en cada destino en el mismo periodo, con los pasos anteriores) o **en proporción a una magnitud** tecleada por centro (m²,
    personas…; `magnitud_analitica` y `magnitud_valor` con fecha desde: vale el valor vigente al final del periodo).
- **Ejecución por periodo** (`reparto_ejecucion`): «repartir octubre» (o un trimestre, o el año) ejecuta **todos los criterios
  activos en su orden** (cascada: cada paso ve lo que dejaron los anteriores). Los periodos de las ejecuciones vivas no se solapan.
  - Guarda los criterios como estaban y `reparto_movimiento` por paso, cuenta y centro (sale del origen, entra en los destinos, con su
    signo; el redondeo, al de más peso). La imputación original no se toca.
  - Antes de ejecutar se ve la **vista previa** (el mismo cálculo sin guardar).
  - **Rehacer** recalcula en el sitio; **deshacer** la deja deshecha con su motivo. Nada de eso con el ejercicio cerrado.
  - **Desfasada:** si al recalcular ya no sale lo mismo (se ha imputado o corregido algo, o se ha cambiado un criterio), se avisa
    para rehacerla. Un criterio sin base en el periodo (todo a 0) no reparte y queda como aviso de la ejecución.
- Permisos: `analitica.configurar` (criterios y magnitudes) y `analitica.repartir` (ejecutar, rehacer y deshacer).
- Los saldos por centro enseñan lo imputado, los repartos y el total.

**Informes** (hechos el 18/11/2026)
- Los estados de ADR-0017 por centro, salvo el balance (no se reparte por centros): el motor toma los importes de lo imputado a unos
  centros (y de los repartos vivos del tramo) en lugar de los saldos.
  - **Una columna por centro** de un nivel del árbol (cada uno con su rama) **o por línea** (todas las sedes juntas), más «sin
    detallar» (lo imputado a los centros de arriba) o «sin línea», **«sin imputar» = el total menos las columnas** (lo que falta por
    imputar y las cuentas que no son analíticas) y el total, que es el estado de la contabilidad: las columnas suman siempre el total.
  - **Un centro (su rama) o una línea**, frente al mismo tramo del ejercicio anterior, con las cuentas de cada línea.
  - Con o sin los repartos («después de repartir»).
- **Movimientos de un centro o una línea**: el resumen por cuenta (las sumas y saldos del centro) y apunte a apunte con el saldo de
  la cuenta, con los repartos.
- Todo exportable por ADR-0049 (las columnas del informe por centros salen de los centros de la empresa).
- Pendiente: la matriz sede × línea en una sola tabla (hoy, por centros al nivel de las hojas o por líneas).

**Migración del programa anterior**
- **Centros:** `empcen` → nodo. Con divisiones, `empdiv` → `linea_analitica`, y cada combinación de `empcenlevel1` (salvo la 0 y
  la 999) → hoja hija de su sede con esa línea.
- **Imputaciones:** `tasiimpcen` → `apunte_centro` por asiento y línea.
  - Lo de la división 0 o 999 de un centro, a la sede (sin detallar).
  - Lo de 9999 y 9876, sin imputar.
- **Repartos:**
  - lo ya repartido (`AsiImpRedist = 'S'`) se carga como imputación de origen `migrada`, porque el programa anterior no guarda el
    antes;
  - `tplaredcen` → criterios de % fijo, sin ejecuciones.
- **Centro como sucursal:** los parámetros de sucursal (`tempcenparcentros`) no se cargan; en la plataforma son cuentas de tesorería
  y caja. Su centro queda como centro por defecto de esa cuenta.
- **Modo sombra:** saldos por centro frente a `sdocentros`.

**Fases**

Lo primero es que la configuración y las imputaciones que haga el usuario queden bien; los informes pueden esperar (José María,
18/11/2026).

1. **Configuración e imputación:**
   - centros y líneas, y cuentas analíticas;
   - imputación desde el editor y la ficha del asiento;
   - bandeja de «sin imputar» y «sin detallar» para distribuir;
   - propuesta desde las facturas, la cuenta y la ficha de inmovilizado;
   - reenlazado al rehacer asientos;
   - saldos y `app.comprobar_analitica`;
   - una consulta mínima de saldos por centro, para comprobar.
2. **Repartos:** criterios, ejecución y deshacer.
3. **Informes:** estados por centro y por línea, matriz, sumas y saldos y mayor por centro.
4. **Migración:** propuesta desde el resto de orígenes, ETL y modo sombra.

## Consecuencias

- Desaparecen los códigos especiales y los procesos de «arreglo» de saldos y de imputaciones: los saldos los mantiene la base, y la
  imputación no puede quedar descuadrada con su apunte.
- El reenlazado al rehacer asientos es la pieza delicada: se prueba con cada generador (factura, cobro, caja, amortización,
  existencias, liquidación).
- La imputación no toca la contabilidad general ni el IVA: abrir la edición hasta el cierre del ejercicio no rompe la regla B1.
- Una dimensión independiente más (proyecto, obra…) queda fuera. Si llega, `apunte_centro` admite una columna de dimensión sin
  rehacer el modelo.

## Uso medido (18/11/2026)

Consultas de `analysis/2026-11-analitica-genexus.md`, lanzadas en los 12 schemas con centros o divisiones.

**La usan de verdad diez empresas:**

| Schema | Empresa | Centros | Líneas | Imputaciones a centro | Fichas de inmovilizado con centro | Reparto |
|---|---|---|---|---|---|---|
| mconta0103 | 1 | 4 | — | 54.245 | 125 | — |
| mconta0002 | 1 | 5 | 7 | 47.822 | 475 | — |
| mconta0050 | 1 | 27 | — | ~45.900 | 26 | 42 filas, 378 redistribuidas |
| mconta0016 | 1 | 3 | — | 20.583 | 60 | — |
| mconta0017 | 1 | 106 | — | 8.551 | 71 | — |
| mconta0057 | 1 | 4 | — | 5.816 | 234 | — |
| mconta0035 | 1 | 6 | — | 443 | — | — |
| mconta0016 | 2 | 2 | — | 400 | — | — |
| mconta0015 | 1 | 2 | — | 117 | 18 | — |

En ninguna hay imputaciones fuera de los grupos 6 y 7, y en las medidas el centro en las facturas emitidas es raro (48 y 26).

**mconta0002** es la única con divisiones, y las usa como **línea transversal**:
- CSMIJ, DOCÈNCIA y GENERAL están en varias sedes (Gràcia, Montcada i Reixac, Sant Andreu, Sant Pau, Centre General);
- todas tienen imputaciones en 2026;
- además tiene unas 4.400 imputaciones en la división 0 o 999 de una sede.

De ahí el árbol con línea y la imputación a cualquier nivel.

**Activadas sin uso:**
- **mconta0109**: sin centros; 8.115 imputaciones (2017–2026), todas en 9999 (4.736.541,07).
- **mconta0138**: sin centros; 2.052 imputaciones (2019–2026), todas en 9999 (1.192.183,91).
- **mconta0072**: 2 centros; de sus 2.487 imputaciones (2014–2023), 9 van a un centro, 62 al código 9876 (que no debería estar en la
  tabla) y el resto a 9999. Dejó de imputar en febrero de 2023.

Las tres se migran **sin analítica**; si el cliente la quiere, se activa y empieza de cero. **mconta0033** tiene las tablas, pero
ninguna empresa la activó.

**Otras observaciones:**
- Los «parámetros de sucursal» salen siempre 10 por centro: los copia el programa al dar de alta un centro, desde los del 9999. No
  indican uso como sucursal.
- La cifra de «28 schemas» de EVOLUTIVOS era de schemas con las tablas, no de uso.

## Pendiente

- Confirmar con los clientes que la usan qué informes por centro les importan (`GenBalCentros` con dos periodos, `MovimCen`); con
  mconta0002, el informe por línea.
- Confirmar con los de mconta0109, mconta0138 y mconta0072 que se migran sin analítica.

## Origen

Conversación con José María del 18/11/2026. Decidido:
- árbol de centros con línea transversal e imputación a cualquier nivel («sin detallar»);
- reparto en movimientos aparte;
- parte de Contabilidad;
- imputación editable hasta el cierre del ejercicio.
