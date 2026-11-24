---
id: 0063
title: Una tabla de inmuebles por empresa, a la que apuntan el producto, la línea emitida, el arrendador y la retención
status: proposed
date: 2026-11-25
services: [platform]
supersedes: null
superseded_by: null
---

## Contexto

Varios modelos y libros piden los datos de un inmueble arrendado, y hoy la plataforma no los guarda:

- **Modelo 180** (resumen anual de las retenciones de arrendamientos urbanos, el 115 trimestral): por arrendador e inmueble, la
  situación (1 España salvo País Vasco y Navarra, 2 País Vasco, 3 Navarra, 4 España sin referencia catastral, 5 extranjero), la
  referencia catastral y la dirección desglosada (tipo de vía, vía, numeración, bloque, portal, escalera, planta, puerta, municipio
  con su código, provincia, código postal). Unos 42 clientes practican retenciones de alquiler (medida de 2025,
  `analysis/2026-11-uso-190-180-v3.sql`).
- **SII**: las emitidas de arrendamiento de local de negocio llevan la clave 11, 12 o 13 y el detalle del inmueble (situación y
  referencia catastral). Hoy se declaran con la clave general y el aviso `SII_ARRENDAMIENTO`.
- **347**: el arrendador de un local de negocio declara además un registro de inmueble por arrendatario. Hoy el fichero sale sin
  registros de inmueble.
- **Libros registro de la AEAT** (Excel): en una actividad de arrendamiento piden situación y referencia catastral (aviso
  `LIBROS_AEAT_INMUEBLE`).

Del lado del catálogo ya existe la marca heredable `inmueble` del producto y la familia (`20261231000038_catalogo_inmuebles.sql`),
que solo decide el territorio de la operación. El 24/11/2026 se decidió una sola tabla de inmuebles a la que apunten el producto
marcado como inmueble y la relación del arrendador, y que sirva también para el SII.

## Opciones consideradas

1. **Datos del inmueble en cada sitio** (en el producto, en la ficha del arrendador, en la retención). Lo mismo tecleado varias veces
   y sin forma de saber que dos son el mismo local.
2. **Una tabla de inmuebles por empresa**, con enlaces desde donde se usa. Un local que la empresa alquila y subarrienda, o que
   compra y luego arrienda, es el mismo registro.

## Decisión

Opción 2.

- **`inmueble`** (por empresa): código, descripción, uso (vivienda, local, otro), país, provincia, código de municipio del INE,
  municipio, código postal, la dirección desglosada como la pide el 180 y la referencia catastral. La situación no se guarda: sale
  del país, la provincia y la referencia (`app.situacion_inmueble`). La referencia catastral de 20 caracteres se comprueba con sus
  dos letras de control cuando el inmueble está en territorio común. Si no cuadra, es un aviso y no un bloqueo, porque País Vasco y
  Navarra tienen otros formatos. Puede apuntar a su ficha de inmovilizado (`activo_id`), solo como información. Con uso, se
  desactiva y no se borra.
- **Lado arrendador** (la empresa alquila un inmueble suyo y factura):
  - `producto.inmueble_id`, solo si el producto efectivo es inmueble.
  - La línea emitida guarda el inmueble que salió en ella (`factura_linea_comercial.inmueble_id`, como guarda el producto), copiado
    del producto. Se puede elegir otro en la línea.
- **Lado arrendatario** (la empresa alquila y retiene):
  - `inmueble_arrendador` une el inmueble con la relación del arrendador (`tercero_rol`). Admite varios, para los copropietarios.
  - La retención de clave `ARR` lleva su inmueble (`retencion.inmueble_id`). Si no llega, se propone al confirmar: el único
    inmueble del perceptor. Si tiene varios o ninguno, se queda vacío y el informe y el 180 avisan (`RETENCION_SIN_INMUEBLE`).

Fases:

1. Tabla, enlaces, propuesta, API y pantalla.
2. 180 (declaración, versiones y fichero oficial con su diseño).
3. SII (claves 11, 12 y 13 con el detalle del inmueble), registros de inmueble del 347 y columnas de los libros de la AEAT.
4. ETL. GeneXus guarda inmuebles en el 347 (`tinmuebles`) y en el SII. Hay que mirar qué tienen los clientes antes de cargar.

## Consecuencias

- Un solo sitio donde completar la referencia catastral. Los cuatro usos la toman de ahí y lo emitido conserva su inmueble aunque el
  producto cambie.
- El 180 sale de las retenciones con su inmueble. Sin inmueble, la retención cuenta en el 115 pero el 180 la deja en
  `no_declarables`.
- Queda pendiente decidir dónde se edita la tabla en pantalla. Propuesta: una página **Inmuebles** en Datos de la empresa, más el
  alta rápida desde el producto y desde la relación del arrendador. Así no hay que salir de un formulario para crear uno.

## Origen

Conversación con José María del 24/11/2026 («Si» a la tabla única) y medida del uso de las retenciones del 25/11/2026.
