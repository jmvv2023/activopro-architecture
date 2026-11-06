---
id: 0028
title: Módulo de Contabilidad en la plataforma — alcance, fases, pantallas y reglas de periodos
status: proposed
date: 2026-11-06
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

**Para qué.** Contabilidad es el módulo que usan 157 de los 160 clientes (ADR-0016) y la base de la ola 1. Fiscal (303/420, 390/425, 347/415) ya está en la plataforma (ADR-0019 a ADR-0025), pero sus pantallas no dejan ver ni tocar los asientos de los que salen los importes.

**Lo que ya existe en la plataforma** (ADR-0018, migración `20261103000002_contabilidad.sql`):

- Modelo: `cuenta`, `ejercicio`, `periodo` (cerrado contable y de IVA por mes), `asiento` (con `origen` y su indicador `editable`), `apunte` (lado, importe con signo, contrapartida), `registro_iva`, `retencion` y `saldo_mensual`.
- Reglas en la base:
  - el asiento cuadra al commit;
  - periodo o ejercicio cerrado: no se crean ni modifican asientos;
  - los saldos se mantienen por trigger;
  - asientos y apuntes tienen audit log;
  - con el IVA cerrado, los registros de IVA quedan sellados.
- ETL y modo sombra validados con datos reales: paridad de saldos del 100 % en mconta0037 y en 56 de los 78 clientes de la ola 1 (`analysis/2026-11-integridad-contable-clientes.md`).
- **Falta:**
  - número de asiento automático, edición controlada y comprobación del `editable` del origen;
  - API y pantallas;
  - cerrar y abrir meses;
  - cierre y apertura del ejercicio.

**El front antiguo** (`apps/web/src/pages/contabilidad`) es otra cosa:

- trabaja sobre el modelo antiguo de Supabase, por RPC y sin la API;
- tiene Libro Diario, formulario de asiento, sumas y saldos y cuenta de resultados;
- trae estados de asiento (borrador, contabilizado, anulado) que **GeneXus no tiene**.

**Qué hace GeneXus** (KB `APGX16`, `domain/contabilidad-legacy.md`):

| Área | Programas | Qué hace |
|---|---|---|
| Consulta | `VerMovimientos`, `VerMovimSdos`, `VerMovimPlaCta`, `HistMovBusAva`, `ListCtaCorriente` | Mayor de cuenta con saldo anterior (y opción de ver eliminados), plan de cuentas con movimientos, búsqueda avanzada por concepto, rango de grupos, importe y documento |
| Informes | `BSum*`, `Bal_excel*`, `DiarioGral_Excel`, `MovimCta_Excel`, `InfCtasAnuales` | Sumas y saldos, balances, diario general, mayor, cuentas anuales (estos últimos son informes configurables, ADR-0017) |
| Entrada | `IngVarios`, `IngAMVAR`, `IngFRI`/`IngFRA`/`IngFEN`, `IngBanco`, `IngCaja`, `IngNominas1`, `IngPersonalizado`, `IngExistencia` | Un formulario **asistido por tipo de asiento**: el usuario da cuenta, importe, bases y tipos, y el programa arma los apuntes y los registros de IVA e IRPF. Valida la coherencia (no hay ingresos al debe ni gastos al haber, base × tipo = cuota, tipo vigente, IVA solo nacional…) y avisa si la factura está descuadrada |
| Plantillas | `AsiDefinicion*` (2.380 definiciones en los 162 schemas) | Asientos predefinidos (diario 33) |
| Plan de cuentas | `WWTCtaCtble`, `Wpcambictas`, `LisPlanCta` | Alta y edición de cuentas, cambio de cuenta en los apuntes, listados |
| Periodos y ejercicio | `CerrarPeriodo`, `AbrirPeriodo`, `Valfechacon`, `Apertura`, `Cierre`, `Retira*`, `CalcSaldos` | Cierre de meses, ventana de fechas, cierre y apertura del ejercicio y su retirada, recálculo de saldos |
| Importación | `ImportDiario_A3CON`, `_Contaplus`, `_Contasol`, `ImportPlanAcum`, `ImportBalances` | Diarios, plan y acumulados de otros programas |
| Auditoría y adjuntos | `movctasupd` (253.851 filas), `adjmovctas` (476.869 filas, 148 schemas) | Histórico de cambios y documentos adjuntos al asiento |

**Qué asientos se hacen** (exports locales de 6 clientes, % de asientos por diario):

| Cliente | Asientos | Más usados |
|---|---|---|
| mconta0037 | 239.629 | 3 emitidas 36 %, 35 facturación 29 %, 8 varios 12 %, 9 banco 8 %, 1 caja 7 %, 11 recibidas 7 % |
| mconta0013 | 26.323 | 9 banco 46 %, 21 recibidas (Canarias) 41 %, 1 caja 6 %, 18 amortizaciones 3 % |
| mconta0124 | 17.575 | 9 banco 44 %, 8 varios 18 %, 11 recibidas 18 %, 12 varios múltiple 15 % |
| mconta0086 | 2.632 | 9 banco 43 %, 21 recibidas 19 %, 18 amortizaciones 17 %, 8 varios 9 % |
| mconta0032 | 895 | 9 banco 54 %, 21 recibidas 29 %, 36 facturación 7 % |
| mconta0048 | 1.175 | 35 facturación 80 %, 11 recibidas 9 %, 9 banco 7 % |

- En un cliente de la ola 1 (sin facturación), entre el 80 y el 90 % de los asientos son de **banco** y de **facturas recibidas y emitidas** registradas en contabilidad.
- La mayoría de los asientos tiene 2 o 3 líneas; los de más de 6 son raros.

**Regla de fechas de GeneXus** (`Valfechacon`), que no es la de la plataforma:

| Mes contable | Mes de IVA | GeneXus permite |
|---|---|---|
| abierto | abierto | todo |
| abierto | cerrado | solo asientos **sin** cuentas de IVA ni facturas |
| cerrado | abierto | solo asientos **con** cuentas de IVA o facturas |
| cerrado | cerrado | nada |

Además:
- **SII:** a partir del día `SIILIMIT` de cada mes, los asientos con IVA de meses anteriores se bloquean.
- Un asiento **no puede cambiar de ejercicio**.

La plataforma hoy hace otra cosa: con el mes contable cerrado no deja hacer nada, y con el IVA cerrado bloquea solo los registros de IVA. La tercera fila explica cómo trabajan en GeneXus: el asiento de liquidación del IVA (diario 10) y las facturas que llegan tarde se contabilizan con el mes contable ya cerrado. En la plataforma, el cierre del 303 con el mes contable cerrado hoy falla.

## Opciones consideradas

### A. Cómo se introducen los asientos

1. **Editor genérico único.** Asiento multilínea con cuenta, concepto, debe, haber y contrapartida, y registros de IVA e IRPF por línea.
   - Pros: una sola pantalla y una sola regla. Es la vía de los ajustes (ADR-0018: «asientos manuales libres, como hoy»).
   - Contras: registrar una factura recibida pasa de rellenar unos pocos campos a teclear 3 líneas y su IVA. Para el 80–90 % del trabajo diario es un retroceso frente a GeneXus.
2. **Formularios asistidos por tipo, como GeneXus.**
   - Pros: rapidez en lo habitual.
   - Contras: muchas pantallas (más de 10 en GeneXus) y la lógica repartida entre ellas. Sin un editor genérico no hay dónde hacer los ajustes.
3. **Editor genérico más asistentes para los tipos frecuentes.**
   - Los asistentes: factura recibida, factura emitida, banco y caja; nóminas y amortizaciones después.
   - Cada asistente solo **prepara** un asiento normal, que se ve y se puede retocar en el editor antes de guardar.
   - Las reglas viven en la base (cuadre, periodos) y en una función por tipo (`app.preparar_asiento_<tipo>`) que convierte los datos del asistente en apuntes y registros.
   - Pros: un solo modelo, rapidez donde importa y un editor que sirve para todo.
   - Contras: dos piezas que mantener.

### B. Periodos cerrados

1. **Replicar GeneXus**: contable cerrado deja pasar asientos con IVA; IVA cerrado deja pasar asientos sin IVA. Más el bloqueo SII.
2. **Mantener la regla de la plataforma**: contable cerrado bloquea todo; IVA cerrado solo los registros de IVA. Obliga a reabrir el mes contable para contabilizar la liquidación del IVA o una factura tardía.
3. **Intermedia**: contable cerrado bloquea todo **salvo el asiento de liquidación del IVA**, que lo genera la plataforma; IVA cerrado bloquea los asientos con registro de IVA o cuenta de IVA.

### C. Estados de asiento (borrador, contabilizado, anulado) del front antiguo

1. **Mantenerlos tal cual**: el asiento nace en borrador y pasa a contabilizado o anulado.
2. **Quitarlos**: como en GeneXus, un asiento existe o no, y el borrado queda en el audit log.
3. **Separar lo que resuelve cada estado** (análisis en la decisión): «anulado» como estado del asiento; «borrador» fuera del libro; «pendiente de revisar» en el documento de origen.

## Decisión

Puntos confirmados por José María el 06/11/2026: A, B (con la lectura de abajo), numeración y mostrar eliminados. Los estados (C) los deja a análisis; la propuesta está más abajo.

### Cómo nacen los asientos

| Origen | Cómo | Editable |
|---|---|---|
| **Facturas** (emitidas y recibidas) | Automático y sin intervención: el documento genera su asiento con las cuentas que le corresponden (tercero, gasto o ingreso, impuesto, retención) | No. Se corrige el documento y el asiento se regenera (como la facturación hoy) |
| **Asientos múltiples y varios** (gastos varios, ajustes…) | Formulario: el editor genérico de asientos | Sí |
| **Banco, caja, nóminas, amortizaciones** | Asistentes y procesos de cada módulo | Sí (como hoy, ADR-0018) |

**La factura recibida es un documento**, no un asiento tecleado. Llega por tres vías:

- **a) Buzón de facturas**: llegan al sistema y quedan pendientes de revisar.
- **b) Papel**: el usuario la digitaliza o la teclea en un formulario.
  - Búsqueda rápida de proveedor o acreedor (nombre, NIF, código).
  - Al elegirlo, el formulario carga lo que ese tercero tiene definido: cuenta de gasto, tipo de IVA o IGIC, retención, forma de pago.
  - En GeneXus ya existe: `AcrCtaCodGasto`, `AcrIvaTpoCod`, `AcrIgicTpoCod`, `AcrIRPF`/`TipIrpfCod`, `ForPagCod` en la ficha del acreedor. En la plataforma va en la configuración por rol del tercero (`tercero_rol`, ADR-0024).
- **c) PDF o imagen**: `ms-activopro-ocr` lee el documento y rellena el mismo formulario. Se deja para la integración final de los micros.

Las tres vías acaban en el mismo formulario y el mismo documento. Al confirmarlo, el asiento se genera solo.

**Consecuencia para ADR-0018.** El catálogo de orígenes tiene `factura_recibida` y `factura_emitida` (contabilidad) como editables, porque en GeneXus se teclean como asientos (`IngFRI`, `IngFEN`).
- Los asientos de los documentos nuevos tienen orígenes propios, **no editables**.
- Los migrados de GeneXus, que no tienen documento, conservan su origen editable.
- Pendiente: si el ETL debe crear el documento de factura a partir de esos asientos (ver «Pendiente»).

### Periodos cerrados: la regla de GeneXus (B1)

| Mes contable | Mes de IVA | Se puede |
|---|---|---|
| abierto | abierto | todo |
| abierto | cerrado | asientos sin IVA |
| cerrado | abierto | solo asientos con IVA |
| cerrado | cerrado | nada |

- **«Con IVA»**: el asiento tiene algún registro de IVA o algún apunte a una cuenta de impuesto (las de liquidación y las de los tipos impositivos).
- Un asiento no cambia de ejercicio.
- El asiento de liquidación del IVA deja de exigir el mes contable abierto: entra por la tercera fila, como en GeneXus.

### Numeración y eliminados

- **Número**: correlativo por orden de alta dentro del ejercicio (máximo + 1 con bloqueo), sin renumerar. El diario ordena por fecha y número.
- **Mostrar eliminados en el mayor**: sí, en la fase 2. Con la propuesta de estados de abajo, es un filtro sobre los anulados.

### Estados del asiento: análisis y propuesta (C3)

El front antiguo tiene tres estados: borrador, contabilizado y anulado. GeneXus no tiene ninguno. Cada uno resuelve un problema distinto, así que conviene separarlos.

**Anulado.** Es lo que GeneXus hace al borrar, pero mejor guardado.
- GeneXus borra la fila y la guarda en `movctasupd`; su opción «mostrar eliminados» la reconstruye desde ahí.
- Con un estado `anulado`:
  - el asiento conserva su número, así que el diario no tiene huecos sin explicación;
  - queda visible con un filtro;
  - sale de saldos, libros y modelos.
- Anular exige motivo, el periodo abierto (según la regla de B) y un origen editable.
- Los de documento se anulan anulando el documento.
- Para el usuario es lo mismo que hoy (el asiento deja de contar); por debajo, la trazabilidad es mejor.
- **Se adopta.**

**Borrador.** Tiene un uso real, pero no debe vivir en el libro.
- El uso real: alguien empieza un asiento múltiple largo (gastos varios) y quiere guardarlo a medias.
- Si el borrador fuera un asiento:
  - habría que eximirlo del cuadre;
  - habría que excluirlo de saldos y modelos;
  - habría que decidir qué número lleva;
  - y los borradores olvidados descuadrarían lo que el usuario ve con lo que cuenta el sistema.
- Es justo la puerta que ADR-0018 quiere cerrar: los descuadres que llegan al cierre.
- **Propuesta**: un **asiento en preparación** fuera del libro (tabla propia, del usuario que lo crea).
  - No tiene número, no cuenta en nada y puede estar descuadrado.
  - La portada de Contabilidad avisa de los que hay.
  - Al guardarlo pasa por todas las reglas y se convierte en asiento.

**Contabilizado.** Es simplemente el asiento: no hace falta como estado.

**Pendiente de revisar.** Vive en el documento, no en el asiento.
- Las facturas del buzón o del OCR están pendientes hasta que alguien las confirma.
- Ese estado es de la factura recibida (pendiente → contabilizada → anulada).
- El asiento solo existe cuando la factura está confirmada.

Si con el uso hace falta otra cosa (como reconoce José María, algunas decisiones cambiarán), estos estados se pueden ampliar sin tocar el libro.

### Alcance y fases

Fase 1: **consulta.** Es de solo lectura y verificable contra GeneXus con los clientes cargados por el ETL.
- Plan de cuentas.
- Diario.
- Asiento en detalle.
- Mayor.
- Balance de sumas y saldos.

Fase 2: **asiento manual y periodos.**
- **Editor genérico** de asientos: el formulario de los asientos múltiples y varios.
- Asientos en preparación.
- Número automático.
- Edición y anulación según el `editable` del origen.
- Cerrar y abrir meses con la regla de GeneXus.

Fase 3: **documentos y asistentes.**
- Factura recibida como documento: formulario con búsqueda rápida y datos por defecto del tercero, buzón, asiento automático. El OCR se integra al final, con los micros.
- Factura emitida registrada en contabilidad (la ola 1 no factura en ActivoPro), con el mismo patrón.
- Asistentes de banco y caja.
- Plantillas de asiento: las `AsiDefinicion` de GeneXus; se migran las que difieren del estándar, como los informes del ADR-0017.

Fase 4: **ejercicio y plan de cuentas.**
- Alta de ejercicio, cierre (regularización y cierre), apertura y su retirada, recálculo de saldos.
- Alta y edición de cuentas y cambio de cuenta en los apuntes.

**Fuera de este ADR:**
- informes configurables: balance, PyG y cuentas anuales (ADR-0017);
- importación de diarios de otros programas;
- analítica;
- divisas;
- adjuntos: dependen del almacenamiento de documentos (ADR-0005, por revisar para la plataforma).

### Pantallas (fase 1 y 2)

Con el sistema de diseño de `apps/web/src/ui`. El código de cuenta sale siempre en 10 posiciones (`705 000000`, ADR-0018) y se acepta como lo teclea el usuario hoy (`4300.1` → `4300 000001`).

- **Portada de Contabilidad**:
  - indicadores del ejercicio: asientos, último mes cerrado, mes de IVA cerrado, asientos con descuadre heredado;
  - accesos a Diario, Mayor, Sumas y saldos, Plan de cuentas y Periodos.
- **Diario**:
  - una fila por asiento (número, fecha, origen, concepto, importe) que se despliega en sus apuntes;
  - filtros: ejercicio, fechas, origen, cuenta, importe y texto;
  - paginado en el servidor (mconta0037: 240.000 asientos).
- **Asiento**:
  - cabecera (número, fecha, origen y el documento del que sale si lo hay);
  - líneas con cuenta, concepto, debe, haber y contrapartida; IVA e IRPF de cada línea en un panel lateral;
  - indicador de descuadre en vivo;
  - teclado primero: Tab entre campos, Intro para línea nueva, atajo para cuadrar con la última línea;
  - de solo lectura si el origen no es editable, con enlace al documento.
- **Mayor**:
  - buscador de cuenta por código, nombre o NIF del tercero;
  - saldo anterior, movimientos con contrapartida y saldo acumulado, totales;
  - cuenta anterior y siguiente con el teclado;
  - desde cada línea se abre su asiento.
- **Sumas y saldos**:
  - nivel: grupo, subgrupo, título o subcuenta;
  - meses desde–hasta;
  - con o sin apertura, regularización y cierre (las clases de `saldo_mensual`);
  - debe, haber y saldo deudor o acreedor, con totales que cuadran;
  - desde cada cuenta se abre su mayor.
- **Plan de cuentas**: árbol de grupos, títulos y subcuentas con el saldo del ejercicio y buscador.
- **Periodos**: los meses del ejercicio con su estado contable y de IVA, y las acciones de cerrar y abrir con motivo. El IVA se cierra y se abre desde la liquidación, como hoy.

### API y permisos

- Rutas `/contabilidad/...` en `apps/api/src/contabilidad/`, con el mismo patrón que fiscal: lógica en la base, contrato con esquema y tipos generados.
- Permisos nuevos en el catálogo (ADR-0015):
  - `contabilidad.consultar`;
  - `contabilidad.preparar` (asientos);
  - `contabilidad.cerrar` (periodos y ejercicio);
  - `contabilidad.configurar` (plan de cuentas y parámetros, solo administrador).
- El módulo se contrata como `contabilidad` en `tenant_modulo`.

### Lo que no se replica de GeneXus

- **Cuenta puente `999 000000`** en apertura y cierre (ya en ADR-0018).
- **Tolerancia de descuadre** (`TOLDESC`): los asientos nuevos cuadran al céntimo (ADR-0018). El formulario de factura avisa de la diferencia y propone dónde llevarla; no la acepta en silencio.
- **Borrar asientos**: se anulan (conservan el número). El borrador del front antiguo pasa a ser un asiento en preparación, fuera del libro.

### Coexistencia con el front antiguo

- Al publicar la fase 1, `/contabilidad` pasa a la plataforma (`RUTAS_PLATAFORMA`) y se retiran el Libro Diario y el balance de sumas y saldos antiguos.
- La cuenta de resultados antigua sigue hasta que llegue ADR-0017.
- El formulario antiguo se retira con la fase 2.

## Pendiente

1. **Bloqueo del SII** (`SIILIMIT`, asientos con IVA de meses anteriores a partir del día límite). Lectura de «todo lo demás de acuerdo»: va con el módulo del SII, no en la fase 2. Confirmar.
2. **Facturas migradas de GeneXus.** Los asientos de facturas recibidas y emitidas tecleados en GeneXus (diarios 3, 11, 21…) no tienen documento. Opciones:
   - migrarlos como asientos editables, como están: simple, pero conviven dos formas de factura;
   - que el ETL cree también el documento: un único libro de facturas, pero cada asiento migrado tiene que reconstruirse como factura, y el modo sombra lo tiene que verificar.
   - Se decide al abordar la fase 3, con datos de cuántos se dejan reconstruir.
3. **Datos por defecto del tercero.** Qué se guarda por rol (cuenta de gasto o ingreso, tipo de impuesto, retención, forma de pago, último concepto) y cómo se aprende: GeneXus guarda el último concepto usado (`AcrConIdUlt`). Al diseñar la fase 3.
4. **Buzón de facturas.** Cómo llegan: correo, carpeta, plataforma de factura electrónica (ADR-0006, SPFE). Con el módulo de factura electrónica.

## Consecuencias

- La fase 1 sirve también como comprobación de paridad: con un cliente cargado, el mayor y las sumas y saldos se pueden comparar a ojo con GeneXus antes de escribir nada.
- Las reglas de periodos y de qué se puede editar quedan en la base. El editor y los asistentes no pueden saltárselas.
- La regla de GeneXus para los periodos obliga a revisar el cierre y la reapertura de la liquidación (hoy exigen el mes contable abierto) y a escribir los tests de las cuatro combinaciones.
- La factura recibida como documento adelanta parte del modelo de facturas al módulo de Contabilidad: se diseña para que sirva luego a facturación (ola 2) y a la factura electrónica (ADR-0006).
- El editor de asientos es la pieza de UI más exigente del módulo. Se diseña con capturas y se revisa contigo antes de dar por cerrada la fase 2.

## Origen

Conversación con José María del 06/11/2026 (respuestas sobre facturas, formularios, periodos y estados); análisis de la KB (`Valfechacon`, `CerrarPeriodo`, `IngVarios`, programas de contabilidad) y de los exports locales de mconta0013, 0032, 0037, 0048, 0086 y 0124.
