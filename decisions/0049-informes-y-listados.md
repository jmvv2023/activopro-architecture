---
id: 0049
title: Informes y listados — una salida común (pantalla, PDF, Excel, CSV) y cuatro fases
status: accepted
date: 2026-11-18
services: [core, reporting]
supersedes: null
superseded_by: null
---

## Contexto

«Informes» cubre cosas muy distintas:

- **Listados.** Lo que el usuario ve en una lista (clientes, facturas, cartera, existencias…) impreso o exportado.
- **Libros oficiales.** Diario, mayor, sumas y saldos, libros registro de IVA/IGIC, bienes de inversión, inventario.
- **Estados financieros configurables.** Balance, PyG y los demás de `definfcon*`; personalizables por empresa (ADR-0017).
- **Informes de gestión.** Ventas por cliente o producto, cartera vencida, márgenes…

Todos se tienen que poder ver en pantalla y sacar en PDF y en Excel. Al darse de baja, el cliente se lleva su información en esos formatos.

### Lo que hace GeneXus

- **Listados en Excel.** Unos 15 listados (sumas y saldos, mayor, libros de IVA/IGIC, cartera de cobros y de pagos, terceros, productos, ventas, entradas…) rellenan una plantilla .xlsx (`GetModListado`).
  - Primero se busca el modelo de la empresa en `modlistados` y, si no hay, la plantilla común de la carpeta del servidor.
  - En producción hay 1.674 modelos en 95 clientes, unos 17 por cliente: por la cuenta, son copias del estándar.
- **Informes configurables.** Cada uno de `definfcon` lleva además su propia plantilla Excel (`DefInfExcel`).
- **Analítica.** No hay contabilidad analítica. `departamento` y `empcen` existen, pero los apuntes (`movctas`) no llevan centro ni departamento.

### Lo que hay en la plataforma

- Consultas con filtros: diario, mayor, sumas y saldos, plan, libro de facturas, cartera, existencias, valoración, inmovilizado…
- El paso a PDF con Gotenberg (`@activopro/documentos`, ADR-0046).
- El worker con su cola y el archivo.
- Nada de Excel.

## Opciones consideradas

### Dónde se generan los ficheros

1. **En el front**, con lo que ya tiene la tabla.
   - A favor: inmediato.
   - En contra: cada pantalla lo haría a su manera; los formatos dependerían del navegador; los listados grandes no caben en memoria; y no queda constancia de qué datos personales salen.
2. **En el backend, desde un modelo común de tabla.**
   - A favor: un solo formato para todo; la misma consulta que la pantalla; lo grande, en el worker.
   - En contra: una ruta más por listado.

### Personalización del Excel

1. **Mantener los modelos .xlsx por empresa**, como `modlistados`.
   - En contra: plantillas con marcadores que no se pueden traducir ni validar, y que se rompen cuando cambian las columnas.
2. **Estilo propio de ActivoPro**, neutro y con la marca discreta, más **vistas guardadas** (columnas, orden, filtros, agrupación).

### Personalización de los informes

1. **Constructor libre de consultas.**
   - En contra: caro de mantener; difícil de asegurar más allá del tenant; resultados que no se pueden traducir ni comprobar. GeneXus tampoco lo tiene.
2. **Personalizar donde tiene sentido:** los estados configurables (ADR-0017) y las vistas guardadas de los listados.

## Decisión

### Cuatro fases

Cada fase tiene su ADR o se amplía en este cuando llegue.

| Fase | Qué |
|---|---|
| **1. Salida común y listados** | Este ADR. |
| **2. Libros oficiales** | Diario con «suma y sigue», mayor, sumas y saldos, libros registro de IVA/IGIC en el formato de la AEAT, bienes de inversión, inventario y libro de inmovilizado. Paginación y numeración de libro. |
| **3. Estados financieros configurables** | El motor de ADR-0017: conceptos, cuentas por reglas de rango con saldo deudor o acreedor, fórmulas entre líneas y columnas (actual frente a anterior, meses, comparativas). Estándar global PGC normal, abreviado y PYMES, y copia propia al personalizar. ETL que detecta lo personalizado, y modo sombra. Es el «balance y PyG». |
| **4. Informes de gestión y envío programado** | Catálogo con parámetros, sobre la salida común; envío periódico por correo con el worker y los buzones de la empresa. |
| Más adelante | Legalización de libros (Legalia 2) y depósito de cuentas en el Registro Mercantil. |

No se hace un constructor libre de consultas.

### Fase 1: la salida común

**El modelo `Informe`.** Vive en un paquete nuevo, `@activopro/informes`, sin acceso a la base. Lleva:

- título, empresa (nombre y NIF), periodo y los filtros aplicados como texto;
- columnas tipadas: texto, importe, precio, cantidad (con sus decimales), porcentaje, fecha, entero o marca;
- filas, agrupación con subtotales y totales;
- idioma y formatos del usuario (ADR-0032).

**De ese único modelo salen tres formatos:**

- **Excel** (exceljs):
  - números, importes y fechas reales, nunca texto, con el formato de su tipo (los decimales de `ui/formato.ts`);
  - cabecera congelada y autofiltro;
  - subtotales y totales con `SUBTOTAL()`, que siguen cuadrando cuando el usuario filtra;
  - una hoja «Datos» con la empresa, el periodo, los filtros y la fecha de emisión.
- **PDF** (React SSR y Gotenberg):
  - A4 vertical u horizontal según el ancho de las columnas;
  - cabecera de la tabla repetida en cada página;
  - pie con la fecha de emisión y «Página x de y».
- **CSV**: UTF-8 con BOM y `;`, con números y fechas en el formato del idioma del usuario, que es lo que abre bien una hoja de cálculo en castellano. Es para pasar datos a otro programa.

**Estilo.** El de ActivoPro: neutro (grises y el verde corporativo apagado en la línea de cabecera) y la marca en el pie, discreta. Sirve para que el cliente reutilice el fichero. No lleva el logo ni los colores de la empresa: esos son de sus documentos (facturas, ADR-0046).

**Generación en el backend:**

- `POST /informes/listados/:listado` con los filtros de la pantalla, la vista y el formato.
  - Llama a la misma función de la base que la lista, así que lo exportado es lo que se ve.
  - Exige el permiso de consulta del módulo del listado.
- Lo genera siempre el worker (trabajo `informe.generar`), sin umbral: un solo camino para lo pequeño y lo grande. *(Ajuste al
  implementar: la propuesta era generar lo pequeño en la API y lo grande en el worker.)*
  - La pantalla espera unos segundos y lo descarga sola; si tarda más, avisa de que queda en «Mis informes».
  - El fichero queda en el archivo 7 días y se descarga desde «Mis informes»; después se borra (la constancia se queda).
- Las columnas de cada listado se declaran una vez en la API (`apps/api/src/informes/listados/`), con su clave de traducción.

**Vistas guardadas.**

- `vista_listado`: listado, nombre, propietario, compartida, y en `config` las columnas visibles y su orden, el orden, la agrupación y los filtros.
- Las vistas son del usuario y puede compartirlas con la empresa. La compartida la ve todo el que tiene acceso al listado, y solo la cambia su propietario o un administrador.
- Cada usuario elige su vista por defecto.
- Se escriben con `app.guardar_vista` / `app.borrar_vista`.
- La vista gobierna lo que se exporta; la tabla de la pantalla conserva su diseño. *(Ajuste al implementar: llevar la vista también a
  las tablas de cada pantalla queda para cuando se pida.)*

**Constancia de lo exportado.** `informe_generado` guarda usuario, listado, formato, filtros, número de filas y fecha. Los listados sacan datos personales (terceros, empleados), y el RGPD pide saber quién los ha sacado. La aplicación solo lee la tabla.

**En el front:**

- un componente `ExportarListado` en la cabecera de cada lista: «Exportar» con PDF, Excel y CSV, «Columnas…» y el selector de vistas;
- la pantalla «Mis informes».

**Listados de la fase 1.**

- Primero:
  - la infraestructura con cinco listados representativos: terceros, libro de facturas emitidas y recibidas, cartera pendiente, sumas y saldos, y existencias;
  - después, los demás: diario, mayor, plan de cuentas, cobros y pagos, movimientos de tesorería, remesas, documentos de venta, productos y tarifas, valoración del almacén, inmovilizado y cierres de caja.
- `npm run inventario` avisa de toda lista sin exportación.

## Consecuencias

- Un único camino a PDF y Excel para toda la plataforma. Las fases 2 a 4 solo añaden el contenido.
- Lo que se exporta coincide con la pantalla, porque sale de la misma función, y queda registrado.
- Los modelos .xlsx de `modlistados` no se migran. Hay que confirmar antes de migrar clientes que ninguno tiene uno distinto del estándar que use de verdad. Lo mismo para `DefInfExcel` en la fase 3.
- **La analítica (centros y divisiones con reparto de costes) se trata aparte.** GeneXus no la tiene (ver `EVOLUTIVOS.md`). El modelo `Informe` no depende de ella. El ADR de la fase 3 tendrá que dejar el motor preparado para una dimensión más (filtro y columnas por centro) si se decide hacerla.
- Pendiente de medir: cuántos modelos de `modlistados` y cuántas plantillas `DefInfExcel` difieren del estándar.

## Origen

Conversación con José María del 18/11/2026. El estilo de ActivoPro en los Excel, sin modelos por empresa, y las vistas del usuario compartibles con la empresa son decisión suya. La analítica, en un hilo propio.
