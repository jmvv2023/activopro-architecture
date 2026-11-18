---
id: 0051
title: Retenciones (111, 115, 190, 180) y pago fraccionado (130) — una sola fuente, pantalla de casillas y fichero solo si el modelo está entero
status: proposed
date: 2026-11-18
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

### Lo que hace GeneXus

- **Informe anual de retenciones e ingresos a cuenta.** Lo agrupa por clave («Profesionales nuevos (3 años)»…). Por cada perceptor da NIF, nombre, código postal y población, retribución, % y retención, con el total por clave y el general. Con eso, el cliente o su asesor preparan el 111, el 115, el 190 o el 180 fuera del programa.
- **Datos.** Cada retención es una línea de `movctaslevel2`: base, %, cuota, clase y el código `MovIrpfCod`. Ese código apunta a `tipirpf` / `tipirpf1`, por empresa: descripción, modelo trimestral y anual, clave del 190, porcentaje por fechas y cuentas.
- **Modelos.** GeneXus no calcula ni genera ninguno de estos.

### Lo que hay en la plataforma

- **Fuente única: `retencion`, en el apunte.** La escriben:
  - la factura, con `factura_retencion`: en la recibida, al haber de la 4751 (la practicamos); en la emitida, al debe de la 473 (nos la practican);
  - el asiento manual;
  - el ETL, con el código de GeneXus.
- **Catálogo central `clave_retencion`** (`20261224000001_claves_retencion.sql`). Es obligatorio solo en la factura. Contrastado con el diseño oficial del 190 (registro de perceptor, subclaves), tiene errores:
  - **F01 y F02 están cruzadas.** F01 son premios literarios, científicos o artísticos no exentos; F02, cursos, conferencias y similares.
  - **La clave F no es una actividad: es rendimiento del trabajo.** En el 111 va a las casillas de trabajo.
  - **Faltan claves:** F03–F07, G07 y K01–K03.
  - **G04 hay que repasarla.** El diseño la define como el tipo del art. 95.1.d) del Reglamento.
- **Perceptor.** La retención no lo lleva. En la factura es su tercero, pero un asiento de nóminas suele ser uno para todos los empleados.
- **Patrón de declaraciones.** El 303/420, el 390/425 y el 347/415 ya tienen las piezas:
  - borrador calculado en la base;
  - ajustes con motivo;
  - versiones inmutables;
  - cierre, con el sellado del IVA en el 303;
  - complementaria o sustitutiva;
  - ficheros a partir del diseño oficial guardado como datos (`registroAeat.ts`, `disenos/*.json`).
- **Salida.** Listados y «Generar» en PDF, Excel y CSV (ADR-0049).

### Restricciones

- **Mantenimiento.** Cada formato de la AEAT que se soporta hay que mantenerlo en cada cambio. Solo se ofrece un fichero cuando el modelo sale entero de la plataforma.
- **Nada a medias.** Lo que no se pueda hacer completo queda como evolutivo.
- **Pantalla antes que PDF.** Muchos clientes sacan PDF porque la pantalla no les da una vista clara. Cada modelo se ve en pantalla (casilla, concepto, valor), y «Generar» queda para quien lo quiera impreso o en Excel.
- **Nóminas.** No se hacen en la plataforma: llegan como asientos.

## Opciones consideradas

### Retenciones del trabajo (nóminas, clave A y siguientes)

1. **Todo en la plataforma.** 111 y 190 completos, con los datos personales del empleado: situación familiar, hijos, discapacidad, contrato… Duplica lo que ya tiene el programa de nóminas, y esos datos cambian por ley cada año.
2. **111 completo y el 190 de trabajo importado del fichero de nóminas.** Es menos carga de datos, pero sigue siendo un formato ajeno que mantener.
3. **Fuera de alcance.** La plataforma calcula lo suyo (profesionales, premios, imagen, ganancias forestales, alquileres). Una clave «Trabajo» solo informativa marca las retenciones de los asientos de nómina, para el informe y el control.

### Cierre del 111 y del 115

1. **Control y aviso**, como el 425.
2. **Sellado, como el 303.** Al cerrar el periodo, sus retenciones quedan bloqueadas hasta reabrirlo con motivo.

### Ficheros

1. **Solo borrador con casillas.**
2. **Fichero oficial en los modelos que salen enteros.** El diseño va como datos versionados por vigencia, y el código de cada modelo solo asigna casillas.

## Decisión

### Alcance

- **Contabilidad y fiscalidad, sin el trabajo (opción 3).**
  - La clave «Trabajo» del catálogo solo informa: no calcula ninguna casilla.
  - Las casillas de trabajo del 111 (01–06) se teclean como un ajuste, con lo que diga el programa de nóminas.
  - El borrador enseña al lado lo contabilizado con la clave «Trabajo» y avisa si no coincide.
  - Si hay retenciones de trabajo en la contabilidad, el fichero del 111 exige esas casillas tecleadas: el valor, o confirmar que son 0.
  - El 190 lleva solo nuestros perceptores. Si en el ejercicio hay retenciones de trabajo, el 190 no está entero: se ve en pantalla y se puede sacar con «Generar», pero no se ofrece fichero, y un aviso explica que lo presenta quien lleva las nóminas, añadiendo estos perceptores.
- **130.** Solo estimación directa, normal y simplificada. La sección II (agrícolas) y el 131 (módulos) quedan para un evolutivo si hay demanda.
- **123 y 193** (capital mobiliario) fuera, aunque la clave CMI exista.

### Datos (fase 1)

1. **Catálogo corregido** contra el diseño oficial vigente del 190.
   - Se añaden las claves que faltan y la «Trabajo» informativa.
   - Cada clave dice el modelo trimestral y anual, la clave y subclave del 190 y la sección del 111: trabajo, actividades, premios, ganancias forestales o imagen.
   - Las claves no se borran: se cierran con `hasta`.
   - Las facturas ya guardadas con una clave mal asignada se corrigen con migración, porque es un error del catálogo, no un dato del cliente.
2. **Clave del catálogo obligatoria en toda retención nueva o cambiada**, también la del asiento manual.
3. **Perceptor en la retención** (`retencion.tercero_rol_id`).
   - Obligatorio en las practicadas.
   - La factura lo pone sola. En el asiento manual lo propone la cuenta del apunte o de la contrapartida, con la misma regla que el 347, y si no lo pide el editor.
4. **ETL.**
   - Traducción de `MovIrpfCod` al catálogo con `tipirpf.TipIrpfClave` y sus modelos (`ARI` = arrendamiento). Lo que no se pueda traducir queda como anomalía.
   - Perceptor por la regla del 347.
   - Modo sombra `comparar-retenciones`: por ejercicio, perceptor y clave, frente a los movimientos de IRPF de GeneXus.

### Cálculo

- **Una sola función en la base** da las retenciones de un periodo: practicadas o soportadas, con clave, modelo, sección, perceptor, base, % y cuota.
- **Avisos:** sin clave, sin perceptor, NIF no válido y % distinto del habitual de la clave.
- El informe y todos los modelos salen de ella. No hay un segundo cálculo.

### Presentación

- **Cada modelo es una pantalla de casilla, concepto y valor**, con sus avisos y el detalle que da cada casilla (perceptores, retenciones), siguiendo el diseño de las pantallas del 303 y el 390.
- **«Generar»** (ADR-0049) lo saca en PDF, Excel o CSV.
- **Informe de retenciones como listado** (`retenciones`):
  - por año, trimestre o mes; practicadas o soportadas;
  - agrupado por clave y perceptor, con total por clave y general;
  - el modelo de cada clave.
  - Es lo que hoy hace GeneXus, más los avisos.

### Declaraciones

- **111 y 115.** Versiones, ajustes con motivo, cierre, presentación con justificante y complementaria. Comportamiento del 303:
  - el cierre sella las retenciones practicadas del periodo con claves de ese modelo, hasta reabrirlo con motivo;
  - el cierre rechaza casillas que ya no cuadran con los datos;
  - reabrir conserva la versión anterior;
  - periodicidad trimestral, o mensual si la empresa es gran empresa (dato nuevo en la configuración fiscal).
- **190 y 180.** Versiones, con control frente al recálculo y complementaria o sustitutiva.
  - El 180 lleva los inmuebles del arrendador (referencia catastral, situación, dirección) en la relación de proveedor o acreedor.
  - La retención con clave de alquiler lleva el inmueble cuando el arrendador tiene más de uno.
- **130.**
  - Acumulado desde el 1 de enero: ingresos del grupo 7 y gastos del grupo 6, con una lista de cuentas excluidas propuesta y editable por empresa.
  - En simplificada, el 5 % de gastos de difícil justificación, con su límite.
  - [05]: retenciones soportadas del año. [06]: pagos de los 130 anteriores.
  - Deducción del art. 110.3.c con el rendimiento del año anterior si está en la plataforma; si no, se teclea.
  - Dato nuevo en la ficha fiscal: estimación directa normal o simplificada.
  - Sin sellado: su base es toda la contabilidad. Control frente al recálculo y complementaria, como el 425.
- **Sin asiento.** El 4751 se cancela al pagar, desde Tesorería.
- **Almacén.** Las declaraciones nuevas se guardan en un solo almacén por versiones (modelo, empresa, periodo, casillas, detalle, fichero, estado, justificante, sustitutiva de); el 303, el 390 y el 347 siguen donde están.

### Ficheros

- **Fichero oficial en los cinco modelos, cada uno solo cuando sale entero.**
  - Diseño como datos (`disenos/drNNNeAAAA.json`) con su vigencia, escrito por `registroAeat.ts`.
  - Test con el ejemplo oficial de cada diseño.
  - La versión guardada recuerda el diseño con que se generó, para poder volver a sacarla idéntica.
  - Un cambio de la AEAT es un JSON nuevo con su fecha, no código nuevo.

### Fases

Cada fase se entrega completa, con tests y manual, antes de empezar la siguiente:

1. Datos e informe de retenciones, con el modo sombra.
2. 111 y 115.
3. 190 y 180.
4. 130.

## Consecuencias

- **Fase 1.** Ya cubre lo que hace hoy GeneXus, con avisos que detectan antes lo que haría salir mal un modelo.
- **Asientos manuales.** Pedir clave y perceptor les añade un paso. Es lo que permite el 190, y la mayoría de las retenciones llegan por factura.
- **Catálogo.** Corregirlo cambia la clave de facturas ya guardadas en la demo; no hay clientes en la plataforma.
- **Nóminas.** Una empresa con empleados sigue necesitando su programa de nóminas para el 190: la plataforma le da sus perceptores en pantalla y en Excel, pero no el fichero.
- **Pantalla como borrador.** Una pantalla de casillas parece la declaración, y alguien puede copiarla tal cual. Por eso enseña siempre si es un borrador o una versión cerrada, y lleva los avisos a la vista, no escondidos.
- **Pendiente** (evolutivos, si hay demanda):
  - importar el 190 del programa de nóminas;
  - sección II del 130 y 131;
  - 123 y 193;
  - 200 (pagos a cuenta del IS) con las retenciones soportadas.

## Origen

Conversación con José María, 18-11-2026: alcance sin el trabajo, ficheros sin «ponernos la soga», 130 en estimación directa, cierre como el 303, pantalla de casillas con «Generar», y fases progresivas de máxima calidad.
