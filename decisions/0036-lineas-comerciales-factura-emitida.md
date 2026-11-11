---
id: 0036
title: Líneas comerciales de la factura emitida — concepto libre, descuento por línea y descuentos y cargos a pie, con el desglose fiscal calculado
status: accepted
date: 2026-11-11
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

José María, probando Facturación (11/11/2026), pide tres cosas:

- una línea de concepto de edición libre;
- descuento por línea;
- descuento a pie de factura.

Hoy la línea de la factura (`factura_linea`, ADR-0030) es el desglose contable y fiscal: cuenta, base, tipo, cuota y operación. Sirve para las recibidas. En las emitidas no hay descripción, cantidad ni precio. ADR-0031, punto 6, ya decidió que las emitidas tendrían dos capas:

- **línea comercial:** artículo, descripción, cantidad, precio, descuento y tipo;
- **desglose fiscal:** el `factura_linea` de hoy, calculado de las líneas comerciales.

ADR-0031 lo dejaba para el módulo de productos. Lo que se pide ahora es esa capa, sin esperar al catálogo: el artículo queda opcional.

### Lo que hay en GeneXus

De 162 schemas:

| Tabla | Schemas con datos | Filas |
|---|---|---|
| `facturas` | 79 | 376.444 |
| `facturasfaclin` (líneas) | 74 | 2.396.534 |
| `facturasfacdto` (descuentos y cargos a pie) | 12 | 2.046 |
| `dtocarfac` (catálogo de descuentos y cargos) | 9 | 53 |
| `facturasfacimp` / `facturasfacven` (desglose por tipo y por cuenta) | 74 / 75 | 532.404 / 381.007 |

**Línea** (`facturasfaclin`):
- artículo opcional;
- concepto corto (`FacLinCon`, 50) y largo (`FacLinConL`, 2.048);
- unidades, precio, % de descuento (`FacLinDtoPor`) e importe del descuento (`FacLinDtoImp`);
- tipo de IVA y recargo, cuenta de venta y retención.

`CalcFacVen2` calcula:

- importe = unidades × precio;
- descuento = redondeo(importe × % / 100);
- neto = importe − descuento.

El IVA se calcula sobre el neto, y el neto va a la cuenta de venta: el descuento de línea no se contabiliza aparte.

**A pie** (`facturasfacdto`): cada línea a pie lleva:

- código del catálogo `dtocarfac`;
- tipo D (descuento) o C (cargo);
- porcentaje;
- secuencia `FacDtoSec`: 1 es en paralelo, sobre la base; 2, 3… en cascada, sobre la base menos lo ya descontado;
- cuenta contable (por ámbito: nacional, intracomunitario, exportación) y tipo de IVA.

En el asiento cada descuento o cargo va **a su cuenta** (`resumen_dtos`), no restando de la venta. Lo usan 12 de 162 schemas.

### Marco

- **Base imponible.** Los descuentos y bonificaciones que se conceden en la propia factura no forman parte de la base imponible (art. 78.Tres.2.º LIVA). Los cargos (portes, embalajes) sí, y llevan el tipo de lo que acompañan.
- **Contenido de la factura.** La factura tiene que llevar la descripción de las operaciones y el precio unitario sin impuesto, más cualquier descuento o rebaja que no esté incluido en ese precio (RD 1619/2012, art. 6.1.f).
- **VeriFactu y SII.** Declaran la base y la cuota por tipo. Que el descuento esté en la línea o a pie no cambia el registro; sí cambia el PDF.
- **PGC.**
  - Los descuentos comerciales en factura minoran la venta: la venta se registra neta.
  - El descuento por pronto pago en factura tiene su cuenta (706).
  - Los rappels por volumen van a la 709, pero suelen ir fuera de la factura.

## Opciones consideradas

### 1. Dónde viven las líneas comerciales

1. **Tabla nueva `factura_linea_comercial`**, de la que la base calcula `factura_linea`. Es lo que fijó ADR-0031.
   - Pros: el registro de IVA, el asiento, la cartera y los modelos no cambian. Las recibidas siguen igual.
   - Contra: una tabla más.
2. **Añadir descripción, cantidad, precio y descuento a `factura_linea`.**
   - Pros: más sencillo hoy.
   - Contras: una línea de texto o un cargo a pie no son una base por tipo y cuenta. Mezcla las dos capas que ADR-0031 separó, y el desglose dejaría de ser uno por cuenta y tipo.

### 2. Línea de concepto libre

1. **Línea de tipo `texto`:** solo descripción (multilínea, hasta 2.000 caracteres), sin importe, en su sitio entre las demás. Es la «línea de concepto» que se pide.
2. **Solo descripción larga en cada línea con importe**, como `FacLinConL`.

Las dos no se excluyen: toda línea con importe tiene su descripción, y además existe la de texto.

### 3. Descuento por línea

1. **Porcentaje**, y el importe se calcula como en GeneXus: redondeo a 2 decimales de cantidad × precio × % / 100.
2. **Porcentaje o importe fijo**: el usuario elige; si teclea el importe, el porcentaje no se guarda.

### 4. Descuentos y cargos a pie

1. **Lista de descuentos (−) y cargos (+)**, cada uno con:
   - concepto y porcentaje;
   - modo **paralelo** (sobre la base) o **cascada** (sobre la base menos los anteriores), como `FacDtoSec`.

   Se reparten por tipo impositivo, en proporción a la base de cada tipo; el redondeo se ajusta en el tipo de base mayor. Así cada tipo baja su base, como exige el 78.Tres.2.º.
2. **Un solo descuento global en %.** Más sencillo, pero se pierden la cascada y los cargos que usan algunos clientes de GeneXus.

### 5. Asiento de los descuentos a pie

1. **Neto:** el descuento resta de la venta de cada cuenta en proporción, y el asiento no lleva línea de descuento. Es el criterio del PGC para descuentos comerciales.
2. **A su cuenta:** cada descuento o cargo va a la cuenta de su catálogo (706 pronto pago, 759 cargos repercutidos…), como en GeneXus.
3. **Neto por defecto, y a su cuenta solo si el descuento la tiene en el catálogo.**

### 6. Catálogo de descuentos y cargos

1. **Catálogo por empresa** (`descuento_cargo`): código, nombre por idioma, tipo, porcentaje propuesto, modo y cuenta opcional. Como `dtocarfac`, con el patrón de las formas de pago.
2. **Sin catálogo:** se teclean en cada factura.

## Decisión

José María confirmó los ocho puntos el 11/11/2026.

1. **Dos capas, como fijó ADR-0031.**
   - `factura_linea_comercial` solo en emitidas de la plataforma: orden, tipo `articulo` / `texto`, descripción, cantidad, precio, % de descuento, impuesto y tipo, operación, recargo, cuenta de ingreso y retención.
   - `app.desglose_factura` calcula de ellas el `factura_linea` de siempre (una línea por cuenta, tipo y operación), con los descuentos y cargos a pie ya repartidos.
   - El formulario de la emitida pasa a líneas comerciales. Las recibidas y las importadas no cambian.
2. **Línea de texto y descripción en toda línea.** Una línea con importe sin descripción es un aviso al emitir (art. 6.1.f), no un error del borrador.
3. **Descuento por línea en porcentaje**, con el importe calculado y visible, como en GeneXus. El importe fijo queda para cuando se pida.
4. **Descuentos y cargos a pie en lista**, en paralelo o en cascada, repartidos por tipo.
5. **Asiento neto por defecto; a su cuenta si el descuento la tiene en el catálogo.** Es lo que pide el PGC sin perder lo que hacen los 12 clientes de GeneXus.
6. **Catálogo por empresa, opcional.** En la factura se puede añadir uno del catálogo o uno libre.
7. **Totales al céntimo:**
   - cada línea se redondea a 2 decimales;
   - la base por tipo es la suma de las líneas menos o más lo de pie repartido;
   - la cuota se calcula sobre la base de cada tipo.

   El total que se ve es el que va a VeriFactu y al asiento.
8. **Rectificativa:** copia las líneas comerciales y los descuentos de la factura que rectifica.

## Consecuencias

- **Migración.**
  - Tablas nuevas `factura_linea_comercial`, `factura_descuento` y `descuento_cargo`, con RLS.
  - `app.guardar_factura` acepta `lineas_comerciales` y `descuentos` en emitidas de la plataforma.
  - El desglose, los totales, la cartera y el asiento salen de `app.desglose_factura`.
  - `app.emitir_factura` exige que haya líneas comerciales.
- **Facturas ya emitidas.** Las emitidas hasta hoy en la plataforma no tienen líneas comerciales: se quedan como están, con su desglose.
- **ETL.**
  - Las facturas de GeneXus no se cargan hoy como documento.
  - `facturasfaclin` y `facturasfacdto` entrarán cuando se migren las emitidas como facturas, no solo como asientos.
  - El catálogo `dtocarfac` puede cargarse ya.
- **PDF de la factura.** Con descripción, cantidad, precio y descuentos ya hay lo que exige el art. 6.1.f. El PDF (ms-activopro-docgenerator) sigue en su propio paso.
- **Módulo de productos.** Cuando llegue, el artículo rellenará descripción, precio, tipo y cuenta. La línea comercial ya los tiene.

## Origen

Petición de José María del 11/11/2026, durante la prueba de Facturación, y orden acordado: cerrar la cartera y hacer este ADR antes de tesorería.
