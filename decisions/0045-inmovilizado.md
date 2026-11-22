---
id: 0045
title: Inmovilizado — fichas de activo, plan de amortización contable y fiscal, asiento mensual y bajas
status: proposed
date: 2026-11-16
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

El inmovilizado es lo último que falta de la ola 1 (ADR-0016): lo usan **108** de los ~160 schemas de GeneXus, casi todos
también sin facturación. Sin él, un cliente de contabilidad no puede migrar.

### Cómo es en GeneXus

**Tablas** (`activofijo*`, por empresa y `ActId`):

- `activofijo`, la **ficha**:
  - nombre;
  - **grupo**: títulos de inmovilizado `GruIdCtaTit` (21x), amortización acumulada `GruAmoCtaTit` (281x) y dotación `GruDotCtaTit` (681x);
  - subcuentas propias de la ficha: inmovilizado `ActInmCtaCod` y amortización acumulada `ActAmoCtaCod`; la dotación va a la `000000` del título;
  - fabricante o marca, número de serie, componentes, localización, observaciones; centro y división (analítica);
  - fecha de inicio de la amortización `ActFec`;
  - vida útil en años `ActAny` o porcentaje `ActPor` (contable), y lo mismo fiscal (`ActAnyFis`, `ActPorFis`);
  - método `ActCri`: `LIN` lineal, `DPC` degresivo de porcentaje constante con el corrector de las tablas oficiales, `DSD` degresivo por suma de dígitos, `NSA` no se amortiza (terrenos);
  - valor residual `ActValRes`;
  - `ActCompleta` (S/N).
- `activofijoactcos`: **costes**. Varias líneas con fecha, concepto, proveedor, unidades, importe y cuenta del tercero; las mejoras son líneas nuevas.
- `activofijoactamo`: **plan anual** contable y fiscal (importe y meses de cada año).
- `activofijoactcon`: **plan mensual contable**: año, mes, importe, contabilizado S/N y asiento (`ActMovId`). La cuota fiscal mensual no se guarda: se recalcula.
- `activofijo2actmod`: **cambios de porcentaje** a partir de una fecha (contable y fiscal, con lo pendiente y la fecha final nueva).
- `activofijoactbaj`: **bajas**: fecha, concepto, unidades, importe, motivo (venta `V` o desguace `D`) y cuenta.
- `activofijoclase` y `clainmo`: **clases** libres para agrupar en los listados.
- `activofijoactdoc`: **documentos** adjuntos (blobs).

**Procesos:**

- **Cálculo** (`Inmovilizado_calculos`):
  - año de 360 días y meses de 30 (febrero también); el primer año, desde el día de inicio;
  - la cuota se calcula por año de vida (del 15/03 al 14/03) y se reparte por ejercicio y mes;
  - lineal: importe × % / 360 × días;
  - DPC: % × coeficiente corrector sobre lo pendiente;
  - DSD: importe / suma de dígitos × dígito del año;
  - en la carga inicial desde Excel, la diferencia con lo ya amortizado se suma al primer ejercicio y se resta del último.
- **Altas pendientes** (`ActFijoVerPendientes`): al contabilizar una factura recibida contra una cuenta de inmovilizado se crea la ficha con `ActCompleta = 'N'` (fecha, proveedor, importe); el usuario la completa.
- **Contabilizar** (`AmortConta`, diario 18):
  - el proceso se lanza para una fecha y crea **un asiento por cada par de cuentas** dotación (681x 000000) / amortización acumulada (281x de la ficha), con la suma del mes de todas las fichas de ese par (por centros si la empresa lleva analítica);
  - marca cada mes como contabilizado y le pone el asiento;
  - `AmortContAnul` lo deshace.
- **Baja** (`ActivoFijoBajas`):
  - amortiza lo pendiente hasta el día antes de la baja (el último mes, por días);
  - propone el asiento de baja: venta con su importe y la cuenta del cobro, o desguace, con la amortización acumulada, el inmovilizado y la diferencia a 671 / 771 (diario 12);
  - el asiento se puede retocar antes de guardar.
- **Diferencias contable–fiscal** (`InmoDififerencia`): por año, para el Impuesto sobre Sociedades.
- **Cierre del ejercicio:** GeneXus exige las amortizaciones del año contabilizadas (ADR-0029 lo dejó pendiente de este módulo).
- **Listados:** ficha, tabla de amortización, inventario (Excel), amortización contabilizada y auditoría.

### Lo que ya tiene la plataforma

- El plan de cuentas con títulos y subcuentas (`app.alta_cuenta`, `app.siguiente_subcuenta`).
- Asientos no editables de un origen, rehechos en el sitio con su número; un ejemplo es el asiento de existencias (ADR-0041, fase 4).
- La regla de periodos B1 (ADR-0028).
- La factura recibida con líneas por cuenta (ADR-0030) y la clase de operación `bien_inversion` del IVA.
- Las comprobaciones del cierre (`app.comprobaciones_cierre`, ADR-0029).

## Opciones consideradas

### A. Unidad de cálculo

1. **Replicar GeneXus**: año de 360 días y meses de 30, por año de vida repartido en ejercicios.
   - Pros: el ETL y el modo sombra cuadran céntimo a céntimo.
   - Contras: arrastra una convención.
2. **Días naturales.**
   - Pros: más exacto.
   - Contras: no cuadra con lo migrado y obliga a explicar cada diferencia.

### B. Plan guardado o calculado

1. **Plan mensual guardado** (contable y fiscal), recalculado desde el primer mes sin contabilizar cuando cambia la ficha (coste, vida útil, porcentaje, baja).
   - Pros: lo contabilizado no se toca; se consulta sin recalcular; el modo sombra compara mes a mes.
2. **Solo calculado** (una función que da el plan a una fecha).
   - Contras: para saber qué se ha contabilizado hay que guardar algo igual.

### C. Asiento de amortización

1. **Como GeneXus:** un asiento por par de cuentas y mes con la suma de las fichas.
2. **Un asiento por mes** con una línea de dotación y una de amortización acumulada por cada par de cuentas (las mismas sumas), enlazado a los meses de las fichas que incluye, como el de existencias.
   - Pros: un número de asiento por mes, que se rehace en el sitio si cambia una ficha y el mes está abierto.
3. **Un asiento por ficha y mes.**
   - Contras: miles de asientos.

### D. Cuentas

1. **Como GeneXus:** subcuenta de inmovilizado y de amortización acumulada por ficha; dotación a la `000000` del título.
2. **Configurable por grupo:** subcuenta por ficha o compartida.

### E. Altas desde la factura

1. **Alta pendiente automática** al contabilizar una recibida con una línea a una cuenta de inmovilizado (grupos 20–23, menos 239), que se completa después (como GeneXus).
2. **Alta desde la factura**, en el mismo formulario.
3. **Solo manual.**

### F. Amortización fiscal

1. **Plan fiscal guardado al lado del contable** y el informe de diferencias por año para el Impuesto sobre Sociedades, sin asientos de impuesto diferido.
2. **Solo contable.**

## Decisión

José María eligió el 16/11/2026: **A1** (360 días, como GeneXus), **C2** (un asiento por mes), **E1** (ficha pendiente automática
desde la factura, que enseña que la ha creado) y **F1** (contable y fiscal). Con ellas, **B1** (plan mensual guardado) y **D1**
(subcuentas por ficha, dotación a la 000000 del título).

**Fases:** 1, fichas, plan y asiento mensual; 2, altas desde la factura, bajas y cambios de vida útil; 3, informes y diferencias
fiscales; 4, ETL y modo sombra.

**Fase 2**, decidido el 16/11/2026:
- **Altas desde la factura recibida:** una ficha por completar por cada línea a una cuenta de inmovilizado (grupos 20 a 23, menos
  la 239), con fecha, proveedor, importe y enlace a la línea. Si la línea va a la subcuenta de una ficha que ya existe, se le añade
  como mejora. Corregir la factura rehace el coste; anularla lo quita, y la ficha se borra si seguía por completar.
- **Venta:** el asiento de baja lleva la amortización acumulada al debe, el inmovilizado al haber, el precio contra una cuenta del
  cobro (propuesta la 543 000000, créditos por enajenación de inmovilizado) y la diferencia a 671 / 771. Si la venta se factura,
  la línea de la emitida va a esa misma cuenta. Es como GeneXus (importe y cuenta).
- **Cambio de vida útil o porcentaje** desde una fecha: es un cambio de estimación, prospectivo (PGC, NRV 22.ª). Lo pendiente a
  esa fecha se reparte en la vida que queda con el nuevo porcentaje o los nuevos años.
- **Amortización hasta la baja:** la baja contabiliza antes, en los asientos mensuales de siempre, los meses pendientes hasta el
  día antes, con el último por días. El asiento de baja solo lleva coste, amortización acumulada, cobro y resultado. Con meses
  posteriores ya contabilizados, la baja no se hace hasta anularlos.

**Modelo:**
- `grupo_inmovilizado` (títulos de inmovilizado, amortización acumulada y dotación; método, vida útil y porcentaje propuestos, del coeficiente de las tablas oficiales).
- `activo` (la ficha, con contable y fiscal, `completa`).
- `activo_coste` (alta y mejoras; enlace a la línea de la factura).
- `activo_cambio` (vida útil o porcentaje desde una fecha).
- `activo_plan` (mes, contable, fiscal, asiento).
- `activo_baja` (fecha, parcial por importe o total, venta o desguace, importe y cuenta de la venta).
- `asiento_amortizacion` (mes → asiento).
- Clases libres: etiquetas.

**Procesos:**
- `app.calcular_plan_activo` (A1).
- `app.contabilizar_amortizacion(empresa, hasta)` (los meses pendientes hasta esa fecha, un asiento por mes) y `app.anular_amortizacion`.
- `app.baja_activo`: amortiza hasta el día antes y genera el asiento de baja, no editable, que se corrige rehaciéndolo.
- Aviso en el cierre: «amortizaciones pendientes».

**Pantallas:**
- Inmovilizado: fichas con lo pendiente de completar, la ficha con su tabla y su asiento, y contabilizar hasta un mes.
- Bajas.
- Grupos.
- Informes: inventario, amortización del ejercicio, diferencias fiscales.

**ETL** de `activofijo*`, con el modo sombra: lo amortizado por ficha frente al saldo de su 281.

Fuera, de momento:
- analítica por centros (no está en la plataforma);
- documentos adjuntos (con el almacenamiento de ficheros);
- préstamos (36 schemas, ADR aparte);
- regularización del IVA de bienes de inversión por prorrata.

## Consecuencias

- Completa la ola 1: un cliente de contabilidad con inmovilizado puede migrar.
- El cálculo de GeneXus queda como regla de la plataforma (360 días). Si se quiere cambiar, será una decisión aparte para las fichas nuevas.
- El cierre del ejercicio podrá avisar de las amortizaciones pendientes.

## Origen

Conversación del 16/11/2026 (sesión del manual de la plataforma), al terminar la ola 1 del manual.

## Ampliación (22/11/2026): corregir una ficha contabilizada y amortización atrasada (H-119)

Incidencia de un cliente: para cambiar fichas con 2025 contabilizado había que anular la amortización mes a mes, y una ficha dada de
alta con meses ya contabilizados no se podía amortizar en ellos sin un asiento manual.

- **Corregir la ficha es corregir un error**: al guardarla, el plan se recalcula entero y la amortización ya contabilizada de los
  meses abiertos se rehace en el sitio (el asiento de cada mes conserva su número y solo cambia lo de esa ficha). El cambio de vida
  útil desde un mes sigue siendo prospectivo (cambio de estimación).
- **Los meses cerrados no se tocan**. Lo que el plan pide en ellos y no está en ningún asiento (meses sin contabilizar y el desfase
  de una corrección) es **amortización atrasada**, que ya no se reparte en silencio al final del plan.
- **Regularización**: un asiento en un mes abierto y no futuro con lo atrasado de cada ficha, con motivo obligatorio, **contra la
  dotación del ejercicio (68x, por defecto) o contra reservas (113)**, a elegir en cada regularización (decisión de José María,
  22/11/2026). Uno por mes; se anula con motivo mientras su mes esté abierto. En el 130, contra la dotación es gasto del periodo en
  que se registra (art. 11.3 LIS); contra reservas, no.
- **Anular desde un mes en adelante** de una vez, además de mes a mes.
