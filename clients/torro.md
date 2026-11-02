# TORRO — instalación local → ActivoPro online

Schema destino: `mconta0037`. Origen: dump MySQL 5.5 (`mconta0037Full.sql`).

## Decisiones

- Ensayar todo en local, paso a paso, y después ejecutar en PROD.
- MinIO no es bloqueante para esta migración (ADR-0005).
- `FACSTILO` vacío hasta que el docgenerator soporte columnas de trazabilidad por lote.

## Orden de pasos

1. Schema `mconta0037` **vacío** (0 tablas). La demo de PROD, si se quiere, en `mconta0037_ref`.
2. `SET GLOBAL max_allowed_packet = 1073741824;` e importar el Full por CLI (no Workbench, por tamaño).
3. Verificar que es Torro: `facturas.FacHashData` no existe (0) y `acceso` con sus filas.
4. `01_drops_obsoletas.sql`.
5. Contar filas de las 15 tablas que recrea `Torro_CreateTables.sql` (todas a 0 en el ensayo).
6. `Torro_CreateTables.sql`.
7. `03_alters.sql` con `SET SESSION sql_mode = ''` (salto 5.5 → 8.0 y fechas cero). Ejecutar una sola vez.
8. Convertir adjuntos de `modListados` de `.xls` a `.xlsx`.

## Lecciones

- Importar el Full antes de reestructurar: su `DROP TABLE IF EXISTS` + `CREATE TABLE` pisa
  cualquier cambio previo.
- No importar la demo de PROD en el schema de trabajo: mezcla datos.
- `adjmovctas` ≈ 5,35 GB, casi todo PDFs de factura regenerables.
