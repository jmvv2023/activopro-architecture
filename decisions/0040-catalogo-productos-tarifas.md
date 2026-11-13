---
id: 0040
title: Catálogo — familias, productos y servicios, y tarifas de venta
status: accepted
date: 2026-11-13
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Sexto eslabón del orden acordado: **remesas → recurrencias → catálogo → almacén → caja**. ADR-0031 (punto 6), ADR-0036 y ADR-0039 (punto 8) dejaron la línea comercial preparada para un producto opcional que rellene descripción, precio, impuesto y cuenta. Este ADR cubre la parte «sencilla» del catálogo. Lo que en GeneXus es **Stock** (existencias, almacenes o centros, lotes, entradas, inventario, precio medio) va en un módulo aparte, **Almacén**, con su propio ADR, contratación y permisos.

### Lo que hay en GeneXus

Uso en los 162 schemas (`analysis/legacy/uso-tablas-todos-los-tenants.csv`):

| Tabla | Qué es | Schemas con datos | Filas |
|---|---|---|---|
| `articulos` | productos | 70 | 5.173 |
| `familias` | familias | 64 | 680 |
| `famgru`, `familiasfamgru` | grupos de familias (N:M) | 26 / 67 | 104 / 685 |
| `artiprecio` | precio del producto por vigencia | 60 | 12.987 |
| `ttarifas` | tarifas de la empresa | 17 | 53 |
| `artitarifas`, `artitarifasimporte` | precio por producto × tarifa × divisa × vigencia | 67 / 60 | 20.056 / 74.935 |
| `cliarticulostarifa` | precio pactado por cliente × dirección × producto, desde–hasta | 4 | 911 |
| `uniconsumo` | unidades de medida (con decimales) | 162 | 7.717 |

- **Familia** (`familias`):
  - código, descripción;
  - clasificación: `A` artículos, `S` servicios, `C` comentarios;
  - «factura por» unidades (`U`) o importe (`I`, la línea no lleva cantidad);
  - tres cuentas de ventas: nacional, intracomunitaria y exportación;
  - tipo de IVA o de IGIC y código de IRPF;
  - líneas en blanco antes de imprimir (comentarios).
  
  Una familia de comentarios no puede dejar de serlo.
- **Producto** (`articulos`, pantalla «Productos»):
  - código (13), descripción corta (50) y larga;
  - código de barras (solo artículos), unidad de venta y unidades por caja;
  - baja;
  - imagen adjunta;
  - precio de compra (`ArtPreCom`), marca de stock y de lotes.
  
  **Copia de la familia** al guardar la clase, las tres cuentas, el tipo de IVA/IGIC y el IRPF, así que cambiar la familia después no cambia los productos ya creados (`Actfamart` lo hace en bloque). El precio (`ArtPre`) está en desuso desde 2012: va en `artiprecio` por vigencia. Al dar de alta se crea la tarifa 1 con ese precio (`PAltaArtTar`).
- **Precio en la factura** (`GetImpTarifa`), con el parámetro `STOCKTAR`:
  1. Precio pactado del cliente y dirección vigente en la fecha (`cliarticulostarifa`): un importe o una tarifa.
  2. Si no hay, la tarifa de la dirección de envío (`CliDirTarCod`) o, si no, la tarifa 1.
  3. En la tarifa, el último precio con vigencia ≤ fecha en la divisa de la factura (por defecto, la de la empresa).
  4. Si esa tarifa no tiene precio, el de la tarifa 1.
- La **cuenta de ventas** de la línea sale del producto según el ámbito del cliente (nacional, intracomunitario, exportación).

### Lo que hay en la plataforma

- **Línea comercial** (ADR-0036): descripción, cantidad, precio, % de descuento, impuesto y tipo, operación (interior, intracomunitaria, exportación, ISP…), recargo y cuenta de ingreso. Es igual en la factura emitida y en la recurrencia (ADR-0039), y se puede escribir a mano.
- **Tipos impositivos centrales** (`tipo_impositivo`, ADR-0022): IVA e IGIC por código (GE, RE, SR, CERO… / TC, ESP, RE…) con vigencias. El porcentaje de un código cambia con la ley sin tocar los datos de las empresas.
- **Cuentas de impuesto** propuestas por tipo y operación (`app.cuenta_impuesto_propuesta`) y **retenciones** por `app.cuenta_retencion_propuesta`.
- **Datos por defecto en la relación** (`tercero_rol`): cuenta, impuesto, tipo, operación, retención y forma de pago, con `app.propuesta_factura`.
- **Textos por idioma** (`textos jsonb`, ADR-0032). Los documentos salen en el idioma del tercero.
- La factura **no lleva divisa**: todo es en euros.
- Unas páginas «Catálogo» y «Familias» del modelo anterior (Supabase, `unidades_medida`, `tipos_impuesto`), sin uso real.

## Opciones consideradas

### 1. Alcance del módulo

1. **Catálogo de venta ahora; Almacén aparte después** (recomendada).
   - **Catálogo:** familias, productos y servicios, unidades, tarifas y precios pactados, y el uso en la factura y la recurrencia.
   - **Almacén:** existencias, almacenes, entradas y salidas, lotes, inventario, coste, precio de compra y proveedor habitual. Se cuelga del producto (1:1) sin que el catálogo dependa de él.
2. **Catálogo con stock básico** (cantidad en existencia en el producto). Mezcla los dos módulos, y el stock bien hecho (por almacén, con movimientos) obliga a rehacerlo.

### 2. Clases de producto

1. **Producto o servicio; los comentarios como «textos predefinidos»** (recomendada).
   - `clase`: `producto` (bien: admite código de barras y, con Almacén, stock) o `servicio`.
   - Los comentarios de GeneXus (familias `C`: textos fijos que se insertan como línea) son un catálogo aparte de textos por idioma que el editor ofrece al añadir una línea de texto. No llevan precio, impuesto ni cuenta, que es lo que en GeneXus se rellena con `EX`, `---` y `999 000000`.
   - Las «líneas en blanco antes de imprimir» se dejan para la plantilla del PDF.
2. **Como GeneXus: tres clases en el producto**, con el comentario como un producto más. Obliga a excepciones en cada regla (sin impuesto, sin cuenta, sin precio).

### 3. Familias

1. **Familias en árbol (padre opcional)** (recomendada).
   - Una familia puede tener subfamilias. Los listados e informes agrupan por cualquier nivel.
   - ETL: los grupos de GeneXus (`famgru`) se cargan como familias padre cuando cada familia está en un solo grupo (el caso normal: 685 filas para 680 familias). Si una está en varios, se toma el primero y queda como anomalía.
2. **Familias planas más grupos N:M, como GeneXus.** Los grupos solo sirven para listados; dos conceptos para lo mismo.
3. **Familias planas sin grupos.** Lo más simple, pero se pierde lo que usan 26 clientes.

### 4. Qué hereda el producto de la familia

1. **Herencia viva con excepción** (recomendada).
   - La familia lleva los valores por defecto: clase, tipo impositivo, retención, cuentas de venta, unidad y «se vende por importe».
   - El producto los deja vacíos (toma los de la familia en cada momento) o los fija (excepción). Cambiar la cuenta de una familia cambia la de todos sus productos sin excepción, sin proceso en bloque.
   - El editor muestra el valor heredado y de dónde viene.
2. **Copia al guardar, como GeneXus**, con un proceso de «aplicar a los productos». Es más predecible si la familia cambia por error, pero obliga a procesos en bloque y deja productos desalineados.

### 5. Impuesto y cuentas del producto

1. **Por código de tipo y por operación** (recomendada).
   - **Impuesto:** el código del tipo (`GE`, `RE`, `SR`, `CERO`… para IVA; `TC`, `RE`… para IGIC) y no un porcentaje. El porcentaje sale de `tipo_impositivo` en la fecha de la factura (`app.tipo_vigente`): una bajada de tipos por ley no obliga a tocar el catálogo. Exenta o no sujeta como en la línea.
     - El producto guarda IVA e IGIC a la vez (como GeneXus), y la línea toma el del impuesto de la empresa, que liquida uno solo.
   - **Retención:** opcional, con el tipo de retención (profesionales, alquileres…).
   - **Cuentas de venta:** una por defecto (interior) y, opcionalmente, una por operación (intracomunitaria, exportación, ISP de ventas). La línea toma la de la operación del cliente o, si no hay, la por defecto. Generaliza las tres de GeneXus.
   - La **cuenta de impuesto** no va en el catálogo: la sigue proponiendo `app.cuenta_impuesto_propuesta`.
2. **Porcentaje fijo en el producto.** Más simple, pero cada cambio legal de tipos obliga a reescribir el catálogo (como pasó en 2024 con los alimentos).

### 6. Precios y tarifas

1. **Tarifa general obligatoria, tarifas adicionales y precios pactados, todo con vigencias** (recomendada).
   - Cada empresa tiene una **tarifa general**, la tarifa 1 de GeneXus. El precio del producto es su precio en la tarifa general.
   - **Tarifas adicionales** (mayorista, distribuidor…). Cada una puede ser:
     - de precio fijo por producto, como `artitarifasimporte`;
     - un % sobre la general (p. ej. −15 %), con precio fijo opcional en los productos que no siguen la regla.
     
     Un producto sin precio en una tarifa toma el de la general, como GeneXus.
   - **Vigencias** como los cambios programados de las recurrencias: «desde tal fecha». Hay subida en bloque por % sobre una tarifa, una familia o una selección, con redondeo. Se conserva el historial.
   - **Tarifa del cliente** en su relación (`tercero_rol.tarifa_id`) y, opcionalmente, en la dirección de envío, como `CliDirTarCod`.
   - **Precio pactado** con un cliente por producto, desde–hasta, como `cliarticulostarifa`: un precio fijo o un % de descuento.
   - **Resolución** (`app.precio_producto(rol, producto, fecha[, dirección])`): pactado vigente → tarifa de la dirección → tarifa del cliente → general. Devuelve el precio y de dónde sale, y el editor lo muestra.
   - **Sin divisas** de momento: la factura es en euros. Los precios en otras divisas de GeneXus no se cargan y quedan como anomalía. 60 schemas tienen `artitarifasimporte`; habrá que ver cuántos tienen una divisa distinta del euro antes del ETL.
2. **Como GeneXus, solo con precios fijos por tarifa.** Una tarifa «−15 %» obliga a mantener a mano un precio por producto (74.935 filas en GeneXus son en buena parte eso).
3. **Solo precio del producto y precio pactado, sin tarifas.** No cubre a los 67 schemas que usan tarifas.

### 7. Unidades y venta por importe

1. **Catálogo de unidades por empresa con decimales** (recomendada). Uno inicial (unidad, hora, kg, m, m², l, servicio…) con nombre por idioma y número de decimales de la cantidad, como `uniconsumo`.
   - «Se vende por importe» (GeneXus `FamImp = I`) es una marca del producto o de la familia: la línea va con cantidad 1 y el precio es el importe, sin columna de cantidad en el PDF.
   - Las unidades por caja pasan a Almacén.
2. **Unidad como texto libre.** Más simple, pero no controla los decimales de la cantidad ni se traduce.

### 8. Uso en la factura y en la recurrencia

1. **El producto rellena la línea, que sigue siendo editable** (recomendada).
   - `factura_linea_comercial.producto_id` y `recurrencia_linea.producto_id`, opcionales: la línea libre sigue existiendo.
   - Al elegir un producto se rellenan:
     - la descripción en el idioma del cliente;
     - la unidad;
     - el precio de `app.precio_producto` a la fecha de la factura;
     - el tipo impositivo del impuesto de la empresa;
     - la retención;
     - la cuenta según la operación.
     
     El usuario puede cambiar cualquier dato en la línea. La factura guarda lo que se emitió, no una referencia viva.
   - **Recurrencia:** la línea con producto elige entre su precio (con cambios programados, ADR-0039) y «precio de tarifa al facturar». En el segundo caso, las subidas de la tarifa llegan solas a las cuotas.
   - Búsqueda por código, código de barras, nombre (en cualquier idioma) y familia.
   - Las recibidas no usan el catálogo hasta Almacén, que es quien necesita el producto en las compras.
2. **Producto como referencia viva** (la factura recalcula desde el producto). Incompatible con la inmutabilidad de la emitida.

### 9. Identificación, baja y textos

1. **Código obligatorio y único por empresa**, más código de barras (EAN/GTIN) opcional y único (recomendada).
   - Nombre y descripción larga **por idioma** (`textos`). El castellano es obligatorio y el resto cae a él.
   - **Activo / baja**: uno de baja no se ofrece en líneas nuevas. Un producto usado en facturas o recurrencias no se borra: se da de baja. Lo mismo para familias, tarifas y unidades.
   - La **imagen** del producto queda para cuando haya almacenamiento de ficheros (Storage) y la use algún documento.
2. **Código opcional.** Más flexible, pero el código es la clave de la importación, del ETL y de la búsqueda rápida.

### 10. Módulo y permisos

1. **Módulo `catalogo`** con `catalogo.consultar`, `catalogo.preparar` (productos y familias) y `catalogo.precios` (tarifas, precios, subidas en bloque y pactados) (recomendada). El precio se separa porque en muchas empresas lo decide una persona distinta de quien da de alta productos.
   - Usar el catálogo en una factura no exige el módulo, porque basta con `facturacion.preparar`. Lo que exige el módulo es mantenerlo.
2. **Todo con `catalogo.configurar`.** Menos permisos, sin separar precios.

## Decisión

Decidido por José María el 13/11/2026, todas las opciones recomendadas:

- **1.1 Catálogo de venta ahora; Almacén aparte** (ADR propio, módulo y permisos propios, colgado del producto).
- **2.1 Producto o servicio**; los comentarios de GeneXus como **textos predefinidos** por idioma.
- **3.1 Familias en árbol** (padre opcional); los grupos de GeneXus se cargan como familia padre.
- **4.1 Herencia viva**: el producto toma de su familia lo que deja vacío, y lo que fija es excepción.
- **5.1 Impuesto por código de tipo** (porcentaje de `tipo_impositivo` a la fecha), retención opcional y **cuentas de venta por operación** con una por defecto.
- **6.1 Tarifa general obligatoria**, tarifas adicionales de precio fijo o % sobre la general, **precios pactados** por cliente, tarifa del cliente y de la dirección, todo con vigencias y subidas en bloque; sin divisas.
- **7.1 Catálogo de unidades** con decimales y «se vende por importe».
- **8.1 El producto rellena la línea**, que sigue editable; la recurrencia puede usar «precio de tarifa al facturar».
- **9.1 Código obligatorio y único**, EAN opcional, nombre y descripción por idioma, baja en vez de borrar.
- **10.1 Módulo `catalogo`** con `consultar`, `preparar` y `precios`.

## Consecuencias

- Tablas nuevas: `familia_producto`, `producto` (con sus cuentas por operación), `unidad_medida`, `tarifa`, `tarifa_precio`, `precio_pactado` y `texto_predefinido`.
- Columnas nuevas: `tercero_rol.tarifa_id`, `rol_direccion.tarifa_id`, `factura_linea_comercial.producto_id` y `recurrencia_linea.producto_id`, más su marca de precio de tarifa.
- Funciones `app.guardar_*` / `app.borrar_*`, `app.precio_producto`, `app.datos_linea_producto` (lo que rellena la línea) y `app.subir_precios`.
- Pantallas en `apps/web/src/pages/catalogo`, que sustituyen a las del modelo anterior: portada con familias y productos, ficha, tarifas, precios pactados en la ficha del cliente y configuración (unidades y textos).
- ETL de `familias`, `famgru`, `articulos`, `artiprecio`, `ttarifas`, `artitarifasimporte`, `cliarticulostarifa` y `uniconsumo`, cuando se importe cada cliente.
- Almacén (ADR siguiente): existencias, almacenes, movimientos, lotes, coste y precio de compra, sobre el mismo `producto`.

## Origen

Conversación con José María, 13/11/2026.
