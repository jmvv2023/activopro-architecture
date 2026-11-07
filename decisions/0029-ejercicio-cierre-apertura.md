---
id: 0029
title: Ejercicio contable — alta, cierre, reapertura y apertura del siguiente; IVA en ejercicios no naturales; alta de cuentas
status: proposed
date: 2026-11-07
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Es la fase 4 de ADR-0028. Se adelanta a la fase 3 (documentos y asistentes) por tres motivos:

- **El cierre de 2026.** El primer cierre de un cliente en la plataforma llega a principios de 2027.
- **Un fallo que hay que arreglar antes.** El motor de liquidación da por hecho que el ejercicio contable es el año natural. Unas veinte funciones (de `20261105000001_liquidacion_iva.sql` a `20261105000013_prorrata.sql`) buscan el ejercicio con `ejercicio.codigo = año del IVA` para sellar `periodo.cerrado_iva`. Con un ejercicio de julio a junio (`codigo = '20262027'`) no lo encuentran.
- **El editor necesita dar de alta cuentas.** El editor de la fase 2 solo trabaja con las cuentas que ya existen; en el día a día es lo primero que se echa en falta.

**Lo que hace GeneXus** (`domain/contabilidad-legacy.md`, ADR-0018). Tiene cuatro procesos: cierre, apertura, retirar el cierre y retirar la apertura.
- **Cierre.** Exige el ejercicio aperturado, el último mes contable y de IVA cerrados y las amortizaciones contabilizadas. Genera dos asientos con la fecha de fin:
  - regularización (diario 92): grupos 6 y 7 contra la 129;
  - cierre de todas las cuentas (diario 93), contra la cuenta puente `999 000000`.
- **Apertura** (diario 91). Exige el ejercicio anterior cerrado. Lleva los saldos finales a la fecha de inicio y traspasa la 129: las pérdidas a la 121 (con una subcuenta por año) y las ganancias a la 123 (parámetros `PYGCTA`, `PERDICTA` y `GANACTA`).
- **Retirar** borra los asientos y desmarca el ejercicio.
- **Todo es secuencial.** Para retirar el cierre de 2024 con 2026 activo hay que retirar antes el de 2025.

**Lo que ya existe en la plataforma:**
- `ejercicio` con `codigo`, fechas y las marcas `aperturado` y `cerrado`;
- los orígenes `apertura`, `regularizacion` y `cierre`, no editables;
- `saldo_mensual` separa esas clases de los movimientos normales;
- la regla de periodos B1 y los meses con historial (fase 2);
- la anulación conserva el número del asiento.

Lo que falta: las operaciones, su historial y el alta de ejercicios y de cuentas.

**Criterio contable.**
- **Resultado.** Según el Plan General de Contabilidad (PGC, RD 1514/2007), el resultado se queda en la 129 hasta que la junta aprueba su aplicación:
  - 112 y 113, reservas;
  - 121, resultados negativos;
  - 526, dividendos.
  - La 123 no existe en el plan.
- **Duración.** El periodo impositivo del Impuesto sobre Sociedades no puede pasar de doce meses (LIS, art. 27).
- **Grupos 8 y 9.** Los ingresos y gastos imputados a patrimonio neto se regularizan contra su cuenta del subgrupo 13. GeneXus no lo hace.

## Opciones consideradas

### A. Operaciones que ve el usuario
1. **Las cuatro de GeneXus.** Fieles al original, pero el usuario tiene que saber el orden: retirar la apertura, retirar el cierre, corregir, cerrar y aperturar.
2. **Dos: «Cerrar ejercicio» y «Reabrir ejercicio».** Cerrar N genera la regularización y el cierre de N y, a la vez, la apertura de N+1 (o la actualiza). Reabrir N retira la regularización y el cierre. La cadena sigue siendo secuencial.

### B. La apertura de N+1 mientras N está reabierto
1. **Retirarla, como GeneXus.** N+1 se queda sin saldos iniciales mientras se corrige N, y su balance y su mayor no sirven durante ese rato.
2. **Mantenerla, marcada «pendiente de actualizar».** N+1 sigue con la apertura del último cierre válido, con un aviso visible, hasta que se vuelve a cerrar N.

### C. Rehacer un asiento de proceso
1. **Anularlo y crear otro.** Cada cierre deja asientos anulados, y la apertura deja de ser el asiento 1 de su ejercicio.
2. **Rehacerlo en el sitio.** El asiento conserva su número y su contenido anterior queda en el historial del ejercicio (versión, usuario, fecha y motivo).

### D. La 129 en la apertura
1. **Como GeneXus:** pérdidas a la 121 y ganancias a la 123, con cuentas configurables.
2. **Como el PGC:** abre como 129. La aplicación del resultado es otro asiento, con un asistente más adelante.

### E. La apertura de N+1 al volver a cerrar N
1. **Botón «Actualizar apertura»**, que enseña las diferencias antes de aplicarlas.
2. **Automática, dentro del cierre de N.** Avisa y pide motivo si enero de N+1 ya está cerrado.

## Decisión

Se eligen A2, B2, C2, D2 y E2 (confirmadas D2 y E2 por José María). D2 sustituye la regla de la 129 que ADR-0018 conservaba de GeneXus.

### Alta de ejercicio

Por defecto va del 1 de enero al 31 de diciembre, y se admiten otros periodos:
- el primero de la empresa empieza cualquier día (la constitución); los demás, el día siguiente al fin del anterior, sin huecos ni solapes;
- termina el último día de un mes;
- no pasa de doce meses de calendario, así que un mes del calendario aparece como mucho una vez en el ejercicio (la clave de `periodo` es el mes);
- el código es el año (`2027`) o los dos años (`20262027`);
- crea sus meses abiertos y el asiento de apertura vacío, que reserva el número 1 (ver más abajo).

Un ejercicio se elimina solo si no tiene más asientos que su apertura. Es lo único que queda de «retirar la apertura».

### Cerrar el ejercicio N

**Condiciones.** Las que falten se muestran como una lista de comprobaciones antes de cerrar:
- todos los meses contables cerrados;
- el IVA cerrado en todos los meses con registros de IVA (si una empresa no tiene IVA, no se le pide);
- sumas y saldos cuadrado al céntimo; si hay descuadres heredados de GeneXus, se listan y el cierre no se hace;
- N−1 cerrado, si existe en la plataforma;
- sin saldo en los grupos 8 y 9; si lo hay, se avisa (su regularización contra el 13 queda pendiente);
- las amortizaciones no se comprueban hasta que exista ese módulo.

**Asientos**, con la fecha de fin, sin contrapartida y sin la cuenta puente (ADR-0018):
1. **Regularización:** el saldo de cada subcuenta de los grupos 6 y 7 contra la cuenta de resultados de la empresa (129 000000 por defecto).
2. **Cierre:** el saldo de cada subcuenta con saldo.

Antes de confirmar, la pantalla enseña el resultado del ejercicio.

**Apertura de N+1** (si N+1 existe), en la misma transacción. Rellena o rehace el asiento de apertura de N+1 con la fecha de inicio: los saldos de cierre de los grupos 1 a 5 invertidos, con la 129 incluida, que abre como 129 (D2).
- Si enero de N+1 tiene la contabilidad cerrada, la apertura se rehace igualmente. No lleva IVA, así que no toca ninguna declaración. El cierre avisa y pide motivo (E2).
- Si N+1 ya tiene la aplicación del resultado y la 129 deja de quedar a cero, el cierre avisa.

**Marcas y cadena.** N queda cerrado y N+1 aperturado. Si N+1 estaba reabierto, el cierre recuerda que hay que volver a cerrarlo.

### Reabrir el ejercicio N

- **Condiciones:** N+1 no está cerrado. Si lo está, el programa dice «Para reabrir 2024 hay que reabrir antes 2025» y ofrece hacerlo; nunca reabre en cascada sin preguntar. Exige motivo.
- **Efecto:**
  - la regularización y el cierre se vacían, conservando su número; el contenido pasa al historial;
  - N queda abierto;
  - la apertura de N+1 queda como está, marcada `apertura_pendiente` (B2).
- **Los meses siguen cerrados.** El usuario abre solo el que necesita, con motivo, y la regla B1 de ADR-0028 hace el resto. Los meses con el IVA cerrado siguen sellados: un ajuste con IVA obliga a reabrir esa liquidación. Así lo ya declarado no cambia en silencio.

### Asientos de proceso

- Son los de origen `apertura`, `regularizacion` y `cierre`. Hay uno de cada por ejercicio (`ejercicio.asiento_apertura_id`, `asiento_regularizacion_id`, `asiento_cierre_id`).
- Se rellenan, se rehacen y se vacían solo con las funciones del ejercicio. La regla B1 no les afecta: los gobierna el estado del ejercicio.
- **Números.** La apertura nace vacía con el número 1 al dar de alta el ejercicio. La regularización y el cierre toman número la primera vez que se cierra el ejercicio y lo conservan. Un asiento de proceso vacío sale en el diario como «pendiente».
- **Primer ejercicio de la empresa** (sin ejercicio anterior en la plataforma): su apertura se puede escribir en el editor, solo con cuentas de los grupos 1 a 5. Sirve para los saldos iniciales de un cliente que viene de otro programa o para el asiento de constitución.
- **Historial.** Cada cierre, reapertura y actualización de la apertura queda en `ejercicio_evento`: tipo, usuario, fecha, motivo y el contenido anterior de los asientos (como `anulado_contenido`).

### Aplicación del resultado

Con D2 la 129 abre como 129. Repartirla es un acuerdo de la junta (normalmente en los seis meses siguientes al cierre, LSC art. 164) o, en un empresario individual, del titular. Por eso el programa no lo hace solo: lo propone, el usuario lo confirma y queda en su propio asiento.

**Asistente «Aplicación del resultado»**, para el ejercicio N ya cerrado y aperturado N+1:
- **Datos:** fecha del acuerdo, que cae en N+1.
- **Con pérdidas:** propone el 100 % a la 121, con un clic. Opcionalmente las compensa con reservas (113 → 121) o con aportaciones de socios (118 → 121).
- **Con beneficios:** reparte entre la 112 (reserva legal), la 113, la 1141 (estatutarias), la 121 (compensar pérdidas anteriores), la 120 (remanente) y la 526 (dividendo).
  - Avisa de la dotación mínima de la reserva legal: el 10 % del beneficio hasta que llegue al 20 % del capital (LSC art. 274).
  - Avisa si se reparten dividendos con pérdidas pendientes y un patrimonio neto inferior al capital (LSC art. 273).
  - Son avisos, no bloqueos: lo decide la junta.
- **Empresario individual:** la 129 va contra la cuenta del titular.
- **Control:** el reparto tiene que sumar el saldo de la 129 al céntimo.
- **Asiento:** origen nuevo `aplicacion_resultado`, uno por ejercicio (`ejercicio.asiento_aplicacion_id`), en N+1. Si se rehace con el asistente, conserva su número y su historial, como los demás asientos de proceso. Si al volver a cerrar N la 129 cambia, el cierre avisa de que la aplicación ya no cuadra y propone rehacerla.

**Reglas sobre el patrimonio neto:**
- **La 129 solo se mueve** con la regularización, el cierre, la apertura y la aplicación del resultado. El editor no deja usarla, salvo en la apertura del primer ejercicio de la empresa.
- **Las cuentas 120 y 121 y los subgrupos 11 y 10** pueden moverse legítimamente fuera de la aplicación del resultado: compensaciones, ampliaciones y reducciones de capital, corrección de errores de ejercicios anteriores contra reservas (PGC, NRV 22). Por eso solo se avisa. Al usarlas en el editor aparece: «Los movimientos de patrimonio neto suelen venir de un acuerdo de la junta; si es la aplicación del resultado, usa el asistente».
- **Resultado pendiente de aplicar:** la portada y la lista de ejercicios avisan si la 129 de N−1 sigue con saldo pasados seis meses del fin de N−1. La comprobación previa al cierre de N también lo señala, como aviso.

### IVA en ejercicios no naturales

- Los meses de un periodo de IVA se resuelven por fecha. El 3T de 2026 es julio, agosto y septiembre de 2026, sea cual sea el ejercicio contable que los contiene. Si el ejercicio cierra el 31 de julio, ese trimestre sella julio en N y agosto y septiembre en N+1.
- Una función común (`app.meses_iva(empresa, año, periodo)` → ejercicio y mes) sustituye a todas las búsquedas por `codigo`.
- El 390, el 347 y el 425 siguen siendo de año natural.
- Tests con un ejercicio de julio a junio.

### Plan de cuentas

- **Títulos** (3 o 4 dígitos, colgando de su grupo y subgrupo del PGC): permiso `contabilidad.configurar`.
- **Subcuentas** (6 dígitos bajo un título que existe): también con `contabilidad.preparar`, porque se crean al contabilizar. El editor ofrece «Crear 629 000003» cuando el código no existe.
- **El nombre** se cambia libremente; **el código**, no.
- **Una cuenta con apuntes, registros de IVA o saldos** no se borra: se desactiva y el buscador deja de ofrecerla para asientos nuevos.
- **Cambiar una cuenta en los apuntes** (el traspaso de GeneXus): de la cuenta A a la B en un rango de fechas, con motivo. Solo en asientos de origen editable y con la regla B1, como cualquier modificación.
- El enlace de la cuenta con un tercero, desde la ficha de proveedor o acreedor, va con la fase 3.

### Pantallas y permisos

- **Ejercicios.** Lista con el estado de cada uno (abierto, cerrado, apertura pendiente de actualizar), alta, eliminar, «Cerrar ejercicio» (comprobaciones, resultado, confirmación) y «Reabrir ejercicio» (motivo), con su historial.
- **Plan de cuentas.** El de la fase 1, con alta, cambio de nombre y desactivación.
- **Permisos:**
  - `contabilidad.cerrar`: meses, cerrar y reabrir el ejercicio, alta y eliminación de ejercicios;
  - `contabilidad.configurar`: títulos y cuenta de resultados (solo administrador);
  - `contabilidad.preparar`: alta de subcuentas y asistente de aplicación del resultado.

### Clientes migrados

- El ETL carga los ejercicios con sus marcas y enlaza los asientos de los diarios 91, 92 y 93 con el ejercicio.
- Sus aperturas antiguas, con la 121 o la 123, se quedan como vinieron.
- La regla D2 se aplica desde el primer cierre hecho en la plataforma. El saldo que tenga la 123 lo aplica el usuario, como cualquier resultado pendiente.

## Consecuencias

- **Para el usuario.** Dos acciones en lugar de cuatro, y un orden que el programa explica en vez de exigir que se sepa. N+1 nunca se queda sin saldos iniciales. La apertura es siempre el asiento 1 y no hay duplicados. Los informes de N+1 se actualizan en cuanto se vuelve a cerrar N.
- **Auditoría.** Rehacer en el sitio no pierde información: cada versión de los asientos de proceso queda en `ejercicio_evento`.
- **Lo declarado.** El IVA declarado sigue protegido por el sellado de meses y la regla B1. La apertura de N+1 puede cambiar con su contabilidad cerrada, y por eso se avisa y se registra.
- **D2 cambia el comportamiento respecto a GeneXus.** El asistente de «Aplicación del resultado» sustituye al traspaso automático: el reparto lo decide la junta, y el programa lo propone, lo comprueba y lo registra.
- **Hay que tocar el motor de liquidación** (búsqueda por fecha) y el ETL (enlace de los asientos de proceso).

**Pendiente:**
- la regularización de los grupos 8 y 9;
- comprobar las amortizaciones cuando exista el módulo;
- los informes de balance y cuenta de pérdidas y ganancias (ADR-0017).

## Origen

Conversación del 2026-11-07 con José María sobre el cierre y la apertura del ejercicio. Partía del flujo de GeneXus (cuatro operaciones secuenciales) y de su propuesta de flujo (corrección en N, nuevo cierre, actualización de la apertura). Se eligen A2, B2 y C2; D2 y E2 se proponen a la espera de confirmación.
