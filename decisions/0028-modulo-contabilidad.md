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

1. **Mantenerlos.**
2. **Quitarlos**: como en GeneXus, un asiento existe o no. Borrar queda en el audit log. Lo pendiente de contabilizar vive en su documento (factura, extracto bancario), no en un asiento a medias.

## Decisión (propuesta)

### Alcance y fases

Fase 1: **consulta.** Es de solo lectura y verificable contra GeneXus con los clientes cargados por el ETL.
- Plan de cuentas.
- Diario.
- Asiento en detalle.
- Mayor.
- Balance de sumas y saldos.

Fase 2: **asiento manual y periodos.**
- **Editor genérico** de asientos (opción A3, primera pieza).
- Número automático.
- Edición y borrado según el `editable` del origen.
- Cerrar y abrir meses con la regla que se decida en B.

Fase 3: **asistentes.**
- Factura recibida, factura emitida, banco y caja.
- Plantillas de asiento (las `AsiDefinicion` de GeneXus: se migran las que difieren del estándar, como los informes del ADR-0017).

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
- **Tolerancia de descuadre** (`TOLDESC`): los asientos nuevos cuadran al céntimo (ADR-0018). El asistente de factura avisa de la diferencia y propone dónde llevarla; no la acepta en silencio.
- **Estados borrador, contabilizado y anulado** del front antiguo (opción C2): no existen en GeneXus y serían una puerta nueva.

### Coexistencia con el front antiguo

- Al publicar la fase 1, `/contabilidad` pasa a la plataforma (`RUTAS_PLATAFORMA`) y se retiran el Libro Diario y el balance de sumas y saldos antiguos.
- La cuenta de resultados antigua sigue hasta que llegue ADR-0017.
- El formulario antiguo se retira con la fase 2.

## Pendiente de decidir (José María)

1. **Introducción de asientos (A).** Propuesta: A3, editor primero y asistentes en la fase 3. ¿De acuerdo? ¿Qué asistentes primero: factura recibida y banco?
2. **Periodos cerrados (B).** Propuesta: **B1, replicar GeneXus**. Es la puerta que existe hoy, explica cómo se contabilizan la liquidación y las facturas tardías, y B2 obligaría a reabrir meses que hoy no se reabren.
   - Lo que exige: la plataforma tiene que saber cuándo un asiento «tiene IVA o facturas». Propuesta: tiene algún registro de IVA o algún apunte a una cuenta de impuesto (las cuentas de liquidación y las de los tipos impositivos, ADR-0022).
   - ¿Se replica también el bloqueo SII (`SIILIMIT`) ya en la fase 2, o va con el módulo del SII?
3. **Estados del front antiguo (C).** Propuesta: C2, quitarlos.
4. **Numeración.** GeneXus numera por orden de alta dentro del ejercicio, sin renumerar, y borrar deja huecos. Propuesta: lo mismo (número = máximo + 1 del ejercicio, con bloqueo). El diario impreso ordena por fecha y número. ¿Algún cliente pide renumerar por fecha al cierre?
5. **Mostrar eliminados en el mayor** (opción de `VerMovimientos`). Propuesta: sí, desde el audit log, en la fase 2.

## Consecuencias

- La fase 1 sirve también como comprobación de paridad: con un cliente cargado, el mayor y las sumas y saldos se pueden comparar a ojo con GeneXus antes de escribir nada.
- Las reglas de periodos y de qué se puede editar quedan en la base. El editor y los asistentes no pueden saltárselas.
- Si se elige B1, hay que revisar la función de cierre de la liquidación (hoy exige el mes contable abierto para reabrir) y escribir los tests de las cuatro combinaciones.
- El editor de asientos es la pieza de UI más exigente del módulo. Se diseña con capturas y se revisa contigo antes de dar por cerrada la fase 2.

## Origen

Conversación con José María del 06/11/2026; análisis de la KB (`Valfechacon`, `CerrarPeriodo`, `IngVarios`, programas de contabilidad) y de los exports locales de mconta0013, 0032, 0037, 0048, 0086 y 0124.
