# Integridad contable de los clientes GeneXus (03/11/2026)

Resultado de `etl/legacy-export/chequeo-integridad.sql` (repo `activopro-platform`) sobre producción, solo lectura. Por cliente: apuntes, facturas, asientos descuadrados y saldos mensuales de GeneXus que no coinciden con sus propios apuntes. Como el ETL reproduce los apuntes exactamente (prueba con mconta0037), un cliente "limpio" aquí es un cliente con paridad de saldos del 100 % en el modo sombra.

## Resumen

| Grupo | Clientes | Limpios | Pocas incidencias | Intermedios | Masivos |
|---|---|---|---|---|---|
| Ola 1 (sin facturas en ActivoPro) | 78 | 31 | 18 | 19 | 10 |
| Con facturación | 77 | 31 | 23 | 18 | 5 |
| Sin apuntes | 5 | — | — | — | — |

- Limpio: 0 asientos descuadrados, 0 saldos distintos.
- Pocas incidencias: hasta 10 descuadrados y unos 12 saldos distintos (como mconta0037: explicables uno a uno).
- Masivo: 500 o más asientos descuadrados.

**31 clientes de la ola 1 tienen paridad completa de saldos hoy mismo**: mconta0003, 0005, 0011, 0012, 0019, 0020, 0021, 0022, 0026, 0028, 0035, 0036, 0038, 0039, 0042, 0056, 0062, 0064, 0067, 0068, 0106, 0110, 0111, 0112, 0117, 0118, 0132, 0142, 0143, 0152, 0153.

## Clientes con descuadres masivos

15 clientes concentran 45.551 de los 49.015 asientos descuadrados (93 %): mconta0002, 0006, 0017, 0050, 0063, 0071, 0072, 0075, 0077, 0088, 0089, 0091, 0098, 0114, 0127.

Un volumen así no son errores sueltos: apunta a algo sistemático. Hipótesis a comprobar:
- asientos que en GeneXus ocupan varios `MovId` (p. ej. importaciones de otros programas o asientos múltiples), de modo que el criterio "asiento = `MovId`" del ETL no vale para ellos;
- o un defecto concreto de GeneXus en algún proceso usado por esos clientes.

Pendiente: análisis por diario y ejercicio en uno de ellos (mconta0002).

## Causa de los descuadres masivos (03/11/2026) — no es un defecto

Análisis en producción (solo lectura) de mconta0002, 0114, 0077 y 0091:

- Los asientos "descuadrados" son facturas recibidas con IVA **no deducible** (`MovIvaDed = 'ND'`), y la diferencia es exactamente la cuota (mconta0114: 1.241 de 1.241; mconta0002: 1.000 de 1.000 en 2025; mconta0077 y 0091: 342 de 363 y 628 de 651).
- **Es una regla de GeneXus, no un error:** `PCrea` no acumula en saldos las líneas con IVA no deducible (comentario de 2011: "no deducible no acumulo saldos"), salvo en ISP (diarios 42, 43 y 47). La cuota queda en el apunte de IVA como dato informativo para el libro de IVA, pero no es contable. Por eso los balances de estos clientes salen cuadrados (comprobado por José María con sumas y saldos de mconta0002 y mconta0077).
- Hay dos variantes en los datos: en unos asientos la línea no deducible lleva la cuota (mconta0002, 0114…) y en otros va a 0 (mconta0037, con 14.446 apuntes sin importe).

Consecuencias:
- **ETL:** las líneas con IVA no deducible (fuera de ISP) se cargan con importe 0 y la cuota queda en el registro de IVA, que es como lo modela ADR-0018. Los asientos cuadran y no se marcan como heredados.
- **Chequeo de integridad:** aplica la misma regla. Hay que **volver a ejecutarlo**: el número de clientes limpios subirá.
- **Uso:** José María indica que estos clientes llevan la contabilidad con asientos manuales ajustados a su criterio.

Efecto en mconta0037: 6 líneas no deducibles; los descuadres heredados bajan de 5 a 2 (quedan 1 manual de 2.743,59 € en 4709 y 1 de céntimos), con paridad mensual del 100,00 %.

## Segunda ejecución, con la regla del IVA no deducible (03/11/2026)

Los asientos descuadrados bajan de 49.015 a **303** en total.

| Grupo | Clientes | Limpios | Pocas incidencias | A revisar |
|---|---|---|---|---|
| Ola 1 (sin facturas en ActivoPro) | 78 | **56** | 17 | 5 |
| Con facturación | 77 | 55 | 21 | 1 |

- Limpio: 0 descuadres y 0 saldos distintos: paridad de saldos del 100 %.
- Pocas incidencias: hasta 10 descuadres y 15 saldos distintos, explicables uno a uno como en mconta0037.
- A revisar: mconta0065 (18 descuadres), 0075 (77), 0077 (42), 0091 (33), 0098 (60) y 0105 (15). En 0077 y 0091 coinciden con los asientos de IVA no deducible en los que la diferencia no era la cuota (p. ej. varias líneas de IVA o combinaciones con `NJ`); probablemente variantes de la misma regla.

**Ola 1, clientes con paridad de saldos completa (56):** mconta0003, 0005, 0011, 0012, 0015, 0017, 0019, 0020, 0021, 0022, 0026, 0028, 0035, 0036, 0038, 0039, 0042, 0045, 0053, 0056, 0060, 0062, 0063, 0064, 0067, 0068, 0074, 0082, 0087, 0088, 0094, 0099, 0102, 0104, 0106, 0109, 0110, 0111, 0112, 0114, 0117, 0118, 0124, 0128, 0132, 0141, 0142, 0143, 0144, 0148, 0149, 0152, 0153, 0155, 0157, 0158.

### Contexto de clientes (José María, 03/11/2026)

- mconta0017 es una **fundación**: puede tener fiscalidad especial (entidad sin fines lucrativos).
- mconta0114 es una empresa de **Canarias** (IGIC), llevada por una asesoría; la asesoría es la cliente de ActivoPro.
- mconta0065, 0075, 0077, 0091, 0098 y 0105 (los 6 "a revisar") son empresas de **esa misma asesoría**. Sus descuadres residuales probablemente responden a su forma de trabajar (asientos manuales con IVA no deducible), no a errores aleatorios.
- Cada empresa sigue siendo su propio tenant aunque la lleve una asesoría; los usuarios de la asesoría tienen acceso a varios tenants (ADR-0014). La unidad de migración sigue siendo la empresa (ADR-0016).
- En España hay varios territorios fiscales (común, Canarias, Ceuta y Melilla, País Vasco, Navarra): la ola 1 empieza por empresas de territorio común.
