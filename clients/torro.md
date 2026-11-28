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

## Incidencias tras la migración y la plataforma nueva (revisión del 26/11/2026)

Lo que TORRO ha reportado desde septiembre en el programa anterior, contrastado con la plataforma (`activopro-platform`). Fuente: las
conversaciones de soporte de cada incidencia.

| Fecha | Incidencia en el programa anterior | En la plataforma | Estado |
|---|---|---|---|
| 13/09 | El albarán impreso sin las columnas de trazabilidad (lote) y cajas, y con vencimientos de cartera ajenos | Impreso con `mostrar.lote` y `mostrar.cajas`; el albarán no lleva vencimientos (`VarianteDocumento`) | Cubierto |
| 20/10 | División por cero al facturar un artículo por peso con unidades por caja = 0 | La columna de cajas solo con unidades por caja > 0; el impreso va aparte, en el worker, y nunca deshace la emisión | Cubierto (prueba en `packages/documentos/test/factura.test.ts`) |
| 19/10 (26/11) | Seis números de factura saltados: la factura tomaba el número (estado `P`) antes de contabilizarse y el fallo al imprimir la dejaba a medias, sin asiento ni registro. Uno de sus albaranes volvió a quedar facturable, se rehizo a otro cliente y acabó facturado dos veces | El número se da al emitir, en la misma transacción que el asiento: si algo falla no se gasta. El albarán de un borrador no entra en otra factura hasta descartarlo | Cubierto (prueba en `db/test/venta_stock.test.ts`) |
| 20/10 | Regularizaciones con cajas en negativo que no se podían guardar | La cantidad lleva su signo; en pantalla, un negativo es «Sale» | Cubierto |
| 20/10 | La dirección de entrega no salía en el impreso (estaba en el nombre comercial) | Dirección de envío del documento y **Entregar en** en el impreso | Cubierto (H-106) |
| 20/10 | La entrada de lotes no proponía el último precio de compra ni la unidad | `app.ultima_compra` (proveedor, si no cualquiera, si no el PMP) y la unidad en la línea | Cubierto (H-105) |
| 22/10 | IVA mal sumado al emparejar lotes con la factura de compra | La entrada se enlaza con la factura por la base de compras (60x) y reparte la diferencia como coste; el asiento sale de la factura | Cubierto por diseño |
| 26/10 | Dirección de envío por documento, la rectificativa con la de la original y el resumen por dirección | `factura.direccion_envio_id`, la rectificativa toma la de su factura, facturar por dirección (`factura_por_direccion`) | Cubierto (H-106) |
| 26/10 | Provincia guardada como « 8» | Provincia por código del INE, validada | Cubierto |
| 02/11 | Los abonos no reponían el stock del lote | La devolución vuelve al lote de la línea original | Cubierto |
| 02/11 | No se podía regularizar un lote cerrado con género físico | La regularización de entrada a un lote existente se admite; solo la salida se limita a lo que hay | Cubierto |
| 02/11 | Cartera: totales de pantalla distintos de los del listado; listar sin los filtros de pantalla | El listado sale de la misma función con los filtros de la pantalla | Cubierto |
| 02/11 | Cartera: filtro «des de venciment» | **Vencen entre** en la cartera, en pantalla y en el listado | Hecho el 26/11 |
| 02/11 | Cartera: dos clientes con el mismo nombre mezclados en un grupo | El listado agrupaba por el nombre (el mismo fallo). Ahora agrupa por el tercero (`grupoPor`), también el libro de facturas por el NIF | Corregido el 26/11 |
| 02/11 | «Resumides»: los vencimientos de las facturas de un periodo de un cliente (o dirección) agrupados en un único recibo, con su PDF | No existe | **Hueco** (H-130) |
| 25/11 | Cambiar el precio de un artículo en todas las tarifas a la vez; el producto nuevo solo en la tarifa 1 | **Precios por producto** y el cambio en bloque; una tarifa sin precio propio sigue a la general | Cubierto (H-122) |
| — | Errores técnicos (`GXM-*`, 500, 403 del control de manipulación) | Propios del programa anterior | No aplica |

Notas para VeriFactu y la carga: TORRO tiene abonos en la serie ordinaria y rectificativas sin marca que agrupan varias facturas. En la
plataforma la rectificativa va en su serie y puede rectificar varias; lo importado no se declara a VeriFactu.
