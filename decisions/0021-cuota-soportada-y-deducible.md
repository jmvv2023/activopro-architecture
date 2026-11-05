---
id: 0021
title: El registro de impuesto guarda la cuota entera y la cuota deducible
status: accepted
date: 2026-11-05
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

En GeneXus la cuota de un registro de IVA/IGIC (`MovIvaCuota`) significa cosas distintas según la operación:

- **Compras con prorrata (`PR`) o deducción parcial (`DP`):** la cuota ya es solo la parte deducible. La parte no deducida se reconstruye al liquidar como base × tipo − cuota (`GenResIva`, `GenResIgic`).
- **ISP e importaciones de una empresa en prorrata (régimen 6):** la cuota es la entera y la deducible se calcula al liquidar como cuota × `MovImpNomAux` / 100. `MovImpNomAux` es el porcentaje de prorrata del ejercicio guardado en el apunte al darlo de alta. En los demás diarios ese mismo campo guarda otras cosas (importes, 999999).

Lo comprobado con datos (modo sombra, IGIC):

| Cliente | Ejercicio | `MovImpNomAux` | Lo que hizo GeneXus |
|---|---|---|---|
| mconta0013 | 2022 | 82 % | deducible 0,98 × 82 % = 0,80 |
| mconta0032 | 2025 | 0 %, sin prorrata dada de alta | deducible 0: 341,32 € de cuota de ISP sin deducir en el 1T2025 |
| mconta0086 | 2020–21 | 0 %, sin prorrata entonces | deducción total |

Dos fallos de GeneXus a raíz de esto:
- **La parte no deducida de las ISP e importaciones no aparece en el resumen.** `&pornodedu` se usa antes de asignarse, así que no suma a la línea de prorrata (900) ni a la de no deducibles (0103).
- **Un ejercicio en prorrata sin porcentaje dado de alta deduce al 0 %**, sin aviso.

El 303/390/420/425 necesitan lo deducido. Las páginas de prorrata (390 páginas 05 y 07, 303 página 04, sus equivalentes del IGIC) y la regularización de final de año necesitan además el soportado entero.

## Opciones consideradas

1. **Dos cuotas en cada registro: `cuota` (entera) y `cuota_deducible` (lo que se deduce).** Cada cifra significa siempre lo mismo y las declaraciones suman la deducible. La no deducida es la diferencia, que es lo que piden prorrata y regularización. La traducción de los dos casos de GeneXus queda solo en el ETL.
2. **Solo el porcentaje deducible, y la cuota deducible calculada al liquidar.** Es un cambio menor. Pero la cuota seguiría significando dos cosas según la operación, y la regularización tendría que reconstruir el soportado.

## Decisión

Opción 1, decidida por José María el 2026-11-05. `registro_iva.cuota` es siempre la cuota de la operación (repercutida o soportada, entera). `registro_iva.cuota_deducible` es lo que se deduce.

## Consecuencias

- **En la base de datos** (migración `20261105000011_cuota_deducible`):
  - `cuota_deducible` solo existe en registros deducibles con deducibilidad total, parcial o prorrata;
  - en total la mantiene un trigger igual a la cuota;
  - en parcial y prorrata la da quien escribe el registro, con el mismo signo que la cuota y sin superarla.
- **`app.resumen_impuesto`:** devuelve en `cuota` lo declarable (la deducible en los deducibles) y en `cuota_soportada` la entera. El 303, el 390 y el asiento de liquidación no cambian.
- **ETL** (`etl/src/iva.ts`, `cuotas()`):
  - PR y DP: entera = base × tipo, deducible = `MovIvaCuota`.
  - ISP e importaciones en un ejercicio en prorrata: entera = `MovIvaCuota`, deducible = cuota × `MovImpNomAux` / 100.
  - Ejercicio en prorrata = empresa con `EmpRegIva` = 6 y, ese año, prorrata dada de alta o registros `PR`. GeneXus solo guarda el régimen actual, así que es la mejor aproximación con los datos; con ella cuadran los tres clientes.
  - El 0 % en prorrata se carga como 0 %, que es lo declarado, y queda como anomalía (`iva_cuota_deducible`).
- **Reglas de IVA de las ISP/importaciones** (diarios de `GenResIva`): sin validar con un cliente real de IVA con prorrata; no hay ninguno hoy.
- **Modo sombra tras el cambio:**
  - mconta0032: 3/3 trimestres de IGIC;
  - mconta0086: 27/27;
  - mconta0013: 32/45 grupos y 39/45 resultados; las diferencias restantes se revisan en el hilo del IGIC;
  - sin regresión en los clientes de IVA.
- **Pendiente:**
  - el porcentaje de prorrata por ejercicio (provisional y definitivo) como dato de la empresa en la plataforma;
  - la regularización de final de año;
  - las páginas de prorrata.

  Se diseñan en el hilo del IGIC (420/425) y se heredan en el 303/390.

## Origen

Conversación con José María, 2026-11-05 (modo sombra de mconta0013, mconta0032 y mconta0086).
