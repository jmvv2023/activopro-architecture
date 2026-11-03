# Primera prueba del modo sombra — mconta0048 (03/11/2026)

Primera ejecución del ETL de contabilidad y del comparador de saldos (`jmvv2023/activopro-platform`) con datos reales: copia local de mconta0048 (Enumbers), exportada con `etl/legacy-export/exportar-contabilidad.cmd`.

## Carga

| Concepto | Cantidad |
|---|---|
| Empresas reales | 1 (las 3 preparadas traen NIF `<NIF>` y se descartan) |
| Cuentas | 1.201 |
| Ejercicios | 3 |
| Asientos | 1.175 |
| Apuntes | 3.844 |
| Registros de IVA | 1.102 |
| Retenciones | 10 |
| Tiempo de carga | < 1 s |

Anomalías: solo 6 asientos descuadrados (ejercicio 2026, `MovId` 348–353, diario 35, modificados el 19/06/2026), importados como descuadre heredado. Ninguna cuenta fuera del plan, ningún diario desconocido, ningún apunte con los dos lados.

## Comparación de saldos

| Componente | Comparadas | Iguales | Distintas |
|---|---|---|---|
| Mensual (frente a `saldoslevel1`) | 805 | 795 (98,76 %) | 10 |
| Apertura | 0 | — | — |
| Regularización | 0 | — | — |
| Consistencia interna de `saldo_mensual` | — | — | 0 |

**Las 10 diferencias no vienen del ETL.** Comprobado directamente sobre el export: la suma de los apuntes de GeneXus (`movctas`) coincide con lo que recalcula la plataforma nueva; lo que no coincide son los saldos que guarda GeneXus (`saldoslevel1`). Es decir, en esa copia **GeneXus tiene sus saldos desalineados con sus propios apuntes**.

Las diferencias están todas en 2026 (julio, septiembre y octubre), en cuentas de clientes, ventas (705) e IVA repercutido (4770), y todas en asientos del diario 35 (facturas del programa de facturación), como los 6 descuadrados.

**Causa confirmada por José María (03/11/2026):** la copia local de mconta0048 se usa para pruebas de todo tipo, así que estos desajustes son esperables. No indican un defecto de GeneXus. Para una prueba limpia hay que partir de una copia recién restaurada desde producción.

## Conclusiones

- El modelo contable (ADR-0018), el ETL y el comparador funcionan con datos reales.
- El modo sombra ya aporta valor antes de migrar a nadie: detecta incoherencias internas de GeneXus.
- Faltan por probar con datos: apertura, regularización y cierre (mconta0048 no tiene ejercicios cerrados con esos asientos) y volumen (mconta0037).

# Segunda prueba — mconta0037 (03/11/2026)

Copia de mconta0037, uno de los clientes más grandes (15 ejercicios, varios cerrados).

## Carga

| Concepto | Cantidad |
|---|---|
| Empresas reales | 1 |
| Cuentas | 2.436 |
| Ejercicios | 15 |
| Asientos | 239.629 |
| Apuntes | 760.233 |
| Registros de IVA | 258.932 |
| Retenciones | 169 |
| Tiempo de carga | 46 s (en un entorno de desarrollo modesto) |
| Tiempo de comparación | 6 s |

Anomalías: solo los 5 asientos descuadrados ya conocidos (ejercicios 2022–2024, cerrados): 4 de facturas recibidas (diario 11) con diferencias de céntimos en IVA soportado (4720) y 1 manual (diario 12) de 2.743,59 € en 4709.

## Comparación de saldos

| Componente | Comparadas | Iguales | Distintas | Explicadas por descuadre heredado |
|---|---|---|---|---|
| Mensual | 51.387 | 51.381 (99,99 %) | 6 | 6 |
| Apertura | 4.342 | 4.342 (100 %) | 0 | — |
| Regularización | 673 | 673 (100 %) | 0 | — |
| Consistencia interna | — | — | 0 | — |

**Paridad efectiva: 100 %.** Las 6 diferencias mensuales están exactamente en los 5 asientos descuadrados: en ellos, GeneXus guardó en saldos un importe distinto del de sus propios apuntes (la diferencia de cada celda coincide con la del descuadre). Son ejercicios cerrados: no se tocan; se migran marcados como descuadre heredado.

## Conclusiones

- Validados con datos reales y volumen: el modelo contable, la regla de cuenta y contrapartida, el signo de las rectificativas, la apertura, la regularización (cuenta 129) y la exclusión del cierre (diario 93) y de los importados (diario 99) en los saldos.
- El comparador separa las diferencias atribuibles a descuadres heredados de los errores reales del ETL.
- Hallazgo para soporte: en mconta0037 hay 4 facturas recibidas con descuadres de céntimos en el IVA soportado, probablemente por redondeo en deducibles o prorrata en `PAltaMovimiento`. Si se repite en otros clientes, es un defecto de GeneXus que el modo sombra puede listar.
