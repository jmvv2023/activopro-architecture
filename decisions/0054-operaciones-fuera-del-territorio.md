---
id: 0054
title: Operaciones con clientes de fuera del territorio del impuesto — según el impuesto de la empresa, dónde está el cliente y si actúa como empresario
status: accepted
date: 2026-11-19
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Una empresa liquida IVA (territorio común) o IGIC (Canarias) (ADR-0043, `empresa.territorio`). Cuándo una venta lleva el impuesto
de la empresa depende de dónde está el cliente y de si actúa como empresario o profesional:

- **IGIC, servicios** (art. 17.Uno Ley 20/1991): se entienden prestados en Canarias si el destinatario es un empresario con la
  sede, el establecimiento o el domicilio en Canarias o, si es un particular, si el prestador está establecido en Canarias. Un
  servicio de una empresa canaria a una empresa de Barcelona **no está sujeto a IGIC** (reglas de localización; el cliente se
  autorrepercute el IVA por inversión del sujeto pasivo); a un particular de Barcelona, **sí lleva IGIC**.
- **IGIC, bienes** que salen de Canarias a la península, a la UE o a un tercer país: exentos como exportación.
- **IVA, servicios** a una empresa de Canarias, Ceuta, Melilla o de fuera de la UE: no sujetos por reglas de localización
  (art. 69 LIVA); a una empresa de otro país de la UE, no sujetos y declarados en el 349 (clave S, ADR-0052).
- **IVA, bienes** que salen a Canarias, Ceuta, Melilla o fuera de la UE: exentos como exportación; a una empresa de la UE, entrega
  intracomunitaria exenta.
- El mismo artículo tiene excepciones (inmuebles, transporte, restauración, eventos…): las decide el usuario.

Lo que había en la plataforma:

- El selector de operación de la factura era el mismo para IVA e IGIC: una empresa de IGIC veía «Entrega de bienes a la UE» y
  «Servicio a empresa de la UE», que para ella no tienen sentido.
- No había «servicio a empresa de fuera del territorio». Se hacía con una línea interior a tipo «no sujeta», que VeriFactu
  declara como N1 (no sujeta por otros motivos) en lugar de N2 (por reglas de localización). Desde la península, un servicio a una
  empresa canaria se podía registrar como «Servicio a empresa de la UE» y acababa en el 349 como operador español.
- Nada proponía la operación por el cliente: el usuario tenía que saberlo.
- Los datos aguas abajo ya estaban: la operación `tercer_pais` no sujeta es N2 en VeriFactu, el SII y los libros de la AEAT,
  categoría O con mención de localización en el PDF y en la Facturae, y clase `no_sujeta_localizacion` en el 303, el 420, el 390 y el
  425.

## Opciones consideradas

1. **Solo un aviso al emitir**, sin cambiar el selector. Barato, pero el usuario sigue sin la opción correcta (N1 en VeriFactu) y la
   empresa de IGIC sigue viendo operaciones de la UE.
2. **Operación propuesta por el cliente sin marca de empresario**, por el NIF. Falla con los autónomos: un NIF de persona física
   puede ser un particular o un profesional, y el resultado cambia (con o sin IGIC).
3. **Selector según el impuesto, operación propuesta por dónde está el cliente y una marca «Actúa como empresario o profesional» en
   la relación cliente, propuesta por el NIF y editable, y un aviso en la factura si una línea no es la habitual.**

## Decisión

Opción 3.

- **Territorio del cliente** por su país y provincia (`app.territorio_tercero`): común, Canarias (35, 38), Ceuta y Melilla (51, 52),
  UE (los países con prefijo de NIF-IVA, sin el Reino Unido) o tercer país.
- **Empresario**: `tercero_rol.actua_empresario` (null = propuesto por la identificación, `app.actua_empresario_propuesto`: entidad
  española sí; NIF-IVA de otro país sí; persona física y el resto, no). En la relación cliente, «Actúa como empresario o
  profesional»; guardar lo que corresponde al NIF lo deja automático, como «Me practica retención de IRPF».
- **Operación propuesta** (`app.operacion_propuesta(rol, clase)`: producto o servicio):

  | Empresa | Cliente | Bienes | Servicios, empresario | Servicios, particular |
  |---|---|---|---|---|
  | IGIC | Canarias | Interior | Interior | Interior |
  | IGIC | Fuera de Canarias | Exportación (exenta) | Fuera del territorio (no sujeta) | Interior (con IGIC) |
  | IVA | Territorio común | Interior | Interior | Interior |
  | IVA | UE | Entrega a la UE (exenta) si es empresario; si no, interior | Servicio a empresa de la UE (no sujeta) | Interior |
  | IVA | Canarias, Ceuta, Melilla, tercer país | Exportación (exenta) | Fuera del territorio (no sujeta) | Interior |

  Va en la propuesta de la factura cuando ni la ficha ni la última factura dicen otra cosa (la ficha y la última factura mandan),
  y en la línea de producto según la clase del producto: un producto fuera del territorio sale como exportación; un servicio, como
  servicio fuera del territorio.
- **Selector según el impuesto de la empresa.** IGIC: Interior, «Servicio a empresa de fuera de Canarias» y «Entrega de bienes fuera
  de Canarias» (exportación); recibidas sin las operaciones intracomunitarias. IVA: las de antes más «Servicio a empresa de fuera de
  la UE, Canarias, Ceuta o Melilla». «Servicio … fuera» es la operación `tercer_pais` a tipo «no sujeta»: una opción de la
  pantalla, no una operación nueva (como el servicio a la UE, ADR-0052).
- **Aviso** `OPERACION_TERRITORIO` en la emitida si alguna línea no es de las habituales para ese cliente. No bloquea: las
  excepciones del art. 17 / 69 las decide el usuario.

## Consecuencias

- La empresa de IGIC ve solo lo que le sirve y el servicio a una empresa peninsular sale N2 en VeriFactu y en el SII.
- Los clientes ya existentes toman la marca de su NIF; los autónomos que actúan como profesionales se marcan a mano.
- Las ventas a distancia de bienes a particulares de la UE (régimen OSS) siguen como interior: fuera de alcance.
- Lo ya registrado no se toca.

## Origen

Conversación con José María, 19/11/2026: «un cliente de una empresa de Canarias con sede en Barcelona…».
