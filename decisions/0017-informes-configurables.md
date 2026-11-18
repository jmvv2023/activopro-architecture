---
id: 0017
title: Estados financieros configurables — plantillas estándar globales y personalización por empresa
status: proposed
date: 2026-11-03
updated: 2026-11-18
services: [core, reporting]
supersedes: null
superseded_by: null
---

## Contexto

GeneXus guarda en cada schema la definición de los informes configurables (balances, PyG y similares): `definfcon`, `definfconceptos`, `definfconconceptos`, `definfconconceptoscta`, `definfconallconceptosidiomacon`, `definfconallidi`… Son unos 12 millones de filas en producción, en su mayoría copias idénticas de la plantilla estándar.

Requisito de José María (03/11/2026): **los informes que los clientes tienen personalizados deben seguir funcionando, y la posibilidad de personalizar se mantiene.**

### Cómo calcula GeneXus (GenBalances, balances)

- Un informe (`definfcon`) es una lista de conceptos (`definfconconceptos`) por orden de impresión, con una acción (`InfAcc`):
  - **I**: título.
  - **S**: salto de página.
  - **R**: rótulo.
  - **C**: cuentas.
  - **T**: suma de otros conceptos, hasta 10 niveles. GeneXus los anida con subrutinas repetidas.
- Las cuentas de un concepto C (`definfconconceptoscta`) llevan dos campos:
  - **Qué valor toma** (`CtaTpo`): A apertura, D debe, H haber, AD y AH debe y haber acumulados con la apertura, S saldo, V variación.
  - **Un filtro de signo** (`CtaOp`): T todo, S solo si es positivo (deudor), R solo si es negativo (acreedor).
- Los conceptos T suman a sus hijos. El campo de operación (`DefInfConOp`) existe pero **el motor no lo aplica**. El signo lo da `InfConMostrar`: el concepto se guarda invertido y sus padres suman lo invertido.
- Columnas: el ejercicio hasta un mes y el ejercicio anterior. `DefInfSaldos = N` da solo los movimientos del periodo, sin acumular saldos.
  - `InfConPer` N1, N2 y N3 piden ejercicios anteriores; solo los usan los informes con Excel adjunto (`DefInfExcel`, agrupación 8).
  - `InfConDuplicado` suma el anterior de otro concepto cuando el ejercicio no está aperturado.
- Presentación por concepto:
  - % sobre otro concepto (`InfConPor`);
  - detalle de cuentas (`InfConDetCta`);
  - negrita (`ImpBol`) y sangría (`InfTab`, 1–5);
  - línea de separación (`InfConLineas`);
  - textos por idioma.
- Variantes del mismo motor: por meses (GenBalMes), por centros (GenBalCentros, sobre `sdocentros`) y porcentajes (Bal_por).
- El modelo de cuentas anuales de la empresa está en `empresas.EmpBalance`: 1 normal, 2 PYMES, 3 abreviado.
- El depósito de cuentas (GenInfD2) es un prototipo de 2012 que no se usa.

## Opciones consideradas

1. **Copiar todas las definiciones a cada tenant**, como hoy. Simple, pero cada mejora del estándar hay que propagarla a 160 copias.
2. **Solo plantillas globales.** Incumple el requisito.
3. **Plantillas estándar globales y personalización por empresa.** El estándar vive una vez; una empresa solo guarda lo que ha cambiado.

## Decisión

Se adopta la opción 3:

- **Plantillas estándar globales** (balance, PyG, etc.), mantenidas por Enumbers y versionadas.
- **Una empresa usa el estándar por defecto.** Si personaliza un informe, se crea una **copia propia** a partir de la plantilla, que pasa a ser suya.
- Las mejoras del estándar llegan automáticamente a quien no ha personalizado. A quien sí ha personalizado se le avisa y decide si incorpora el cambio.
- **El motor de cálculo es único** para estándar y personalizados.

### Diseño (18/11/2026)

**El estándar sale de los modelos oficiales del PGC.** Son el balance y la cuenta de pérdidas y ganancias de cuentas anuales normales, abreviadas y PYMES (RD 1514/2007 y 1515/2007), con su numeración y sus textos.
- Están por prefijos de cuenta, así que sirven para cualquier plan.
- Se mantienen en castellano, catalán e inglés (el glosario fija los términos).
- El modelo de cada empresa (normal, abreviado o PYMES) va en su configuración contable.
- El ETL lo toma de `EmpBalance`.

**Modelo.** Las mismas dos tablas para el estándar (global, sin tenant, versionado por `version`) y para la copia de una empresa (con tenant y RLS):

- **Estado:** código, nombre por idioma, clase (`balance`, `pyg`, `otro`), modelo (`normal`, `abreviado`, `pymes` o ninguno), versión, y de qué estándar y versión sale la copia.
- **Línea:** orden, referencia (la numeración oficial, «A.I.1»), texto por idioma, nivel de sangría, negrita, y un tipo:
  - `titulo`: sin importe.
  - `cuentas`: reglas `[{prefijo, valor, signo, restar}]`.
    - `valor`: `saldo`, `debe`, `haber`, `apertura` o `variacion`.
    - `signo`: `todo`, `deudor` o `acreedor`. Se evalúa **por cuenta**, como `CtaOp`: una 4700 deudora va al activo y una 4750 acreedora, al pasivo.
    - `restar`: el «(280)» del modelo oficial.
  - `formula`: términos `[{linea, signo}]` sobre otras líneas del mismo estado. Es el patrón de las plantillas de asiento (ADR-0033): sin parser, sin ciclos (se comprueba al guardar) y con el signo explícito.
  - `salto`: salto de página.
- Además, cada línea puede llevar:
  - `invertir`: se muestra con el signo cambiado; el pasivo y los ingresos, en positivo.
  - `porcentaje_de`: % sobre otra línea.
  - `detalle`: enseña sus cuentas.

**Motor:** `app.calcular_estado(empresa, estado, ejercicio, hasta, columnas)`, en la base y sobre `saldo_mensual`.
- **Columnas:** el ejercicio desde su inicio hasta el mes pedido, y el mismo tramo del ejercicio anterior. La columna % se calcula sobre la línea indicada.
- **Por cuenta y regla:**
  - `apertura` = asiento de apertura;
  - `debe` y `haber` = movimientos sin apertura;
  - `saldo` = apertura + movimientos;
  - `variacion` = movimientos.
- **Sin el cierre ni la regularización.** Así la PyG y el resultado del balance (129 más grupos 6 y 7) salen igual antes y después de cerrar.
- **Resultado:** cada línea con su importe por columna y, si se pide, sus cuentas.
- **Comprobaciones del cálculo:**
  - el activo cuadra con el pasivo (aviso);
  - cuentas con saldo que no entran en ninguna línea del balance (aviso, con la lista);
  - cuentas de 6 y 7 fuera de la PyG.
- La dimensión **centro** queda prevista: un filtro opcional que hoy no se usa (ver «Analítica»).

**Personalizar:** «Personalizar» copia el estándar vigente a la empresa, y esa copia pasa a ser la que se usa.
- Se edita en la plataforma (líneas, reglas, fórmulas, textos) y «Probar» calcula sin guardar.
- «Volver al estándar» borra la copia.
- Si sale una versión nueva del estándar de la que se copió, la pantalla lo avisa y enseña las diferencias; la empresa decide.
- Una empresa puede crear estados propios desde cero (clase `otro`).

**Salida:**
- **Pantalla Contabilidad → Estados financieros:** ejercicio, mes y comparación con el anterior. Cada importe abre sus cuentas y cada cuenta, su mayor.
- **PDF y Excel** por Informes (ADR-0049).
- **Libro de inventarios y cuentas anuales** (Código de Comercio, art. 28), en Libros con folios:
  - las sumas y saldos al final de cada trimestre;
  - el inventario de cierre, que es el balance con el detalle de sus cuentas;
  - el balance y la PyG del ejercicio.

**Fuera de esta fase:**
- Las columnas por meses y por centro.
- El estado de cambios en el patrimonio neto, el de flujos de efectivo y la memoria.
- El depósito de cuentas (D2/XBRL): un formato oficial más que mantener, y en GeneXus no se usa.
- Los informes con Excel adjunto (`DefInfExcel`): se mide si alguien los usa antes de migrarlo.

## Migración

- Para cada informe de cada empresa, el ETL compara su definición con la plantilla estándar de GeneXus:
  - **si es idéntica**, la empresa queda apuntando al estándar de la plataforma de su modelo (`EmpBalance`);
  - **si difiere**, se migra como informe personalizado de esa empresa. La traducción es:
    - C → `cuentas`, con `CtaTpo` como valor y `CtaOp` como signo;
    - T → `formula`, con el signo que resulta de `InfConMostrar` y de cómo suma GeneXus, no de `DefInfConOp`;
    - I, R → `titulo`; S → `salto`.
- **Paridad**: el modo sombra (ADR-0016) compara los importes de cada informe entre GeneXus y la plataforma nueva, tanto estándar como personalizados.

## Analítica

GeneXus **sí tiene** contabilidad analítica:
- centros (`empcen`);
- imputación de cada línea de asiento a un centro y una división, con importe y marca de redistribución (`tasiimpcen`);
- saldos por centro, división y mes (`sdocentros`);
- estos mismos informes por centro (GenBalCentros).

La usan unos 28 schemas. No entra en esta fase, pero es lo siguiente: un ADR propio antes de migrar a esos clientes. El motor de estados queda preparado para filtrar y agrupar por centro.

## Consecuencias

- Los ~12 millones de filas replicadas se reducen al estándar más las personalizaciones reales.
- Se conserva la personalización y se mantiene la capacidad de personalizar.
- El estándar es el oficial del PGC: lo que cambie el PGC lo cambia Enumbers una vez.

## Pendiente

- Medir cuántas empresas tienen informes personalizados. Hace falta un export de `definfcon*` del schema de referencia y de algunos clientes.
- Confirmar si las cuentas de `definfconconceptoscta` son títulos o subcuentas concretas del plan de cada empresa. El ETL las pasa a prefijos.
- Medir el uso de `DefInfExcel` (agrupación 8) y de `InfConPer` N1–N3.

## Origen

Conversación con José María del 03/11/2026. Diseño del 18/11/2026: estándar de los modelos oficiales del PGC; columnas actual, anterior y %; editor con «Probar» en esta fase; la analítica justo después.
