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

## Causa de los descuadres masivos (03/11/2026)

Análisis de mconta0002 en producción (solo lectura):

- Los descuadres no se compensan entre asientos: son reales. Entre 50.000 y 90.000 € al año, siempre con el debe por encima del haber, desde 2011 hasta 2026.
- Todos son **facturas recibidas** (diario 11 sobre todo; también 4 y 14).
- En 2025, los 1.000 asientos descuadrados tienen IVA **no deducible** (`MovIvaDed = 'ND'`; 52 combinan exento y no deducible), y en los 1.000 la diferencia es **exactamente la cuota de IVA**.

Conclusión: al contabilizar una factura recibida con IVA no deducible, GeneXus genera un asiento cuyo debe supera al haber en el importe de la cuota. Lo más probable es que la cuota no deducible se cargue a la vez como mayor gasto y en el apunte de IVA; queda por confirmar en qué línea sobra viendo un asiento concreto. Es un defecto de GeneXus que sigue activo en 2026 y deja descuadrados los balances de sumas y saldos de los clientes que usan IVA no deducible.

Consecuencias:
- **Migración:** sin impacto en el ETL; los asientos se migran como descuadre heredado. Estos clientes no son candidatos de la primera ola.
- **Plataforma nueva:** el IVA no deducible se modela como mayor gasto, con el registro de IVA informando la cuota para el libro y el apunte de IVA a 0 (como ya hace GeneXus en mconta0037, con 14.446 apuntes sin importe). El asiento debe cuadrar; la base de datos lo impide si no.
- **Soporte:** corregirlo en GeneXus toca la lógica de contabilización (regla 4 de `CLAUDE.md`): requiere decisión explícita de José María. Pendiente también decidir qué se hace con los asientos ya descuadrados de ejercicios abiertos.
