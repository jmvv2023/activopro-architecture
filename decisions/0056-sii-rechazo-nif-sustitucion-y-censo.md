---
id: 0056
title: SII — emitida rechazada que no se puede corregir se sustituye, y el NIF se comprueba en el censo de la AEAT antes de emitir
status: accepted
date: 2026-11-20
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Primera prueba del SII en la preproducción de la AEAT (20/11/2026, certificado de Enumbers): altas, modificación y
fuera de plazo, correctos. Una emitida de la plataforma a un cliente con un NIF que no está en el censo volvió
**rechazada** (1117, «El NIF no está identificado»).

- **La AEAT** (preguntas técnicas del SII):
  - un error al *registrar* se corrige con una modificación;
  - una *factura* errónea, con una rectificativa por sustitución o por diferencias;
  - un NIF no identificado se reintenta más tarde (la AEAT puede darlo de alta en el censo);
  - si sigue sin identificarse, solo una **persona física** puede ir como «no censado» (`IDOtro`, tipo 07): queda aceptada
    con errores. Una sociedad no tiene esa salida.
- **La plataforma:**
  - una emitida de la plataforma **no se modifica nunca** (VeriFactu, ADR-0030/0031): se rectifica;
  - la factura guarda el NIF con que se emitió, así que corregir la ficha del cliente no la cambia, y es lo correcto: el
    documento emitido es el que es.
- **Resultado:** la factura queda rechazada para siempre, el aviso decía «corrige la factura o el asiento» (imposible) y el
  usuario no tenía salida. En las recibidas y los asientos el problema no existe: se corrigen y se reenvían.

## Opciones consideradas

1. **A — Sustituir:** anular la emitida con su rectificativa (copia en negativo, la convención de la plataforma) y emitir
   una nueva al cliente correcto.
2. **B — Corregir la identificación del destinatario en la factura** mientras la AEAT no la haya aceptado (solo NIF, tipo y
   país, con motivo) y reenviar el alta.
   - Es lo que hacen muchos programas y es más sencillo.
   - Cambia una factura ya emitida, cuyo PDF tiene el cliente con el NIF malo, y rompe la regla que sostiene VeriFactu y la
     plataforma. Abrirla solo para el SII deja dos criterios.
3. **C — Prevenir:** comprobar el NIF y el nombre en el censo de la AEAT antes de emitir, con el certificado de la empresa
   (servicio web de calidad de datos identificativos, `VNifV2`), y avisar antes de que el error llegue al SII.

## Decisión

**C para prevenir y A para resolver lo que llegue.** B se descarta. Aceptado por José María el 20/11/2026.

### A. Sustitución de una emitida que la AEAT no ha aceptado

- **Cuándo.** Emitida de la plataforma, en el SII, cuyo **alta nunca ha sido aceptada**:
  - el registro sigue `no_enviada`;
  - y está **rechazada** (la AEAT dijo `Incorrecto`) o **incompleta** (la plataforma ya ve que le falta algo, p. ej. el
    NIF).
  - Si la AEAT ya la tiene (registrada o aceptada con errores), no: lo que toque es una rectificativa normal, que va al SII
    como alta.
- **Qué hace** (`app.sustituir_emitida(empresa, factura, datos)`, todo en una transacción):
  1. **Emite la rectificativa por diferencias**, copia exacta en negativo de la original, en la serie rectificativa
     vigente y con fecha de hoy, como cualquier rectificativa de la plataforma.
     - Sale con el mismo cliente y NIF que la original: es su anulación.
  2. **Prepara la factura nueva** como borrador: las mismas líneas, descuentos, forma de pago y serie, al cliente que se
     elige (el mismo con la ficha corregida u otro).
     - El usuario la revisa y la emite él: puede cambiar fecha, cliente o lo que haga falta.
  3. **Marca en el SII la original y su rectificativa como `sustituida`.**
     - No se envían ni cuentan como pendientes: salen de la pantalla, de los avisos y de los plazos.
     - Guardan el motivo, quién lo hizo y la rectificativa.
     - La nueva va al SII como cualquier emitida.
- **Por qué la pareja no se envía.**
  - La AEAT no tiene la original (la rechazó) y la rectificativa lleva el mismo NIF no identificado: también la rechazaría.
  - Juntas suman cero (en el 303 también: la original suma y la rectificativa resta en el mismo o en otro periodo), así que
    no hay nada que declarar.
  - La nueva, con el NIF correcto, es la que declara la operación.
  - Riesgo asumido: el libro de la AEAT no tiene rastro de la original. Queda en la plataforma (factura, rectificativa,
    `sii_evento` con el motivo) para cualquier comprobación.
- **Sin efecto en VeriFactu:** solo existe en el tramo SII de la empresa (ADR-0055). Con VeriFactu, el rechazado sigue su
  propio camino (alta por rechazo, ADR-0046).
- **Cartera.** Los vencimientos de la original y los de la rectificativa (negativos) se compensan. Sin nada cobrado, la
  función los compensa sola (cobro de importe 0, ADR-0035). Con algo cobrado, se reaplica a la nueva desde la cartera.
- **Pantalla.**
  - En la factura y en el detalle del SII, el rechazo de una emitida de la plataforma dice qué pasa y ofrece
    **Sustituir por una factura nueva**: elegir el cliente (por defecto el mismo) y el motivo.
  - Al terminar, se abre el borrador de la nueva.
  - El aviso ya no manda a «corregir la factura» cuando es una emitida de la plataforma.
- **Permiso:** `facturacion.preparar` (emite documentos).

### C. NIF comprobado en el censo de la AEAT

- **Servicio.** `VNifV2` de la AEAT (manual técnico del servicio web masivo de calidad de datos identificativos):
  - por cada contribuyente, NIF y nombre (obligatorio en personas físicas);
  - responde `Identificado`, `No identificado`, `No identificado-similar` (personas físicas), `Identificado-Baja` o
    `Identificado-Revocado` (entidades);
  - hasta 10.000 por petición;
  - con certificado de persona física o de representante (`www1`) o de sello (`www10`), sin firma del mensaje.
  - Uso solo para cumplir obligaciones tributarias: el abuso se bloquea. Por eso se comprueba una vez por NIF y cuando
    cambia, no en cada factura.
- **Sin entorno de pruebas.** La AEAT no publica uno para este servicio.
  - El worker solo lo llama con `AEAT_CENSO=pro` (en producción, junto a `AEAT_ENV=pro`). Con `AEAT_ENV=pre` no se
    comprueba nada y el tercero queda «sin comprobar».
  - Los tests usan un simulador.
  - Para probarlo en local con el certificado de Enumbers, José María pone `AEAT_CENSO=pro` en su `.env`. Ninguna sesión
    autónoma lo hace.
- **Qué se comprueba y cuándo.**
  - Terceros con NIF español (tipo `nif` o `no_censado`, país ES) de una empresa con certificado vigente.
  - **Al darlos de alta y al cambiar el NIF o el nombre:** el trabajo `censo.comprobar`, por empresa, recoge todo lo que
    está sin comprobar o desfasado, con una espera corta para agrupar.
  - Una sola petición para muchos terceros, como en una carga.
  - **Desde la ficha:** «Comprobar en la AEAT».
  - **Al emitir o registrar** con un tercero nunca comprobado, se encola la comprobación. No espera a la respuesta.
- **Dónde queda.** En el tercero:
  - resultado (`censo_estado`);
  - NIF y nombre comprobados;
  - fecha.
  - Si después cambia el NIF o el nombre, el resultado ya no vale (desfasado) y se vuelve a comprobar.
- **Avisos.**
  - **Ficha** («La AEAT no identifica este NIF con este nombre», «NIF dado de baja», «NIF revocado», «Nombre parecido:
    revísalo»): en la ficha y en la lista de terceros por revisar.
  - **Al emitir** una factura (SII o VeriFactu) o registrar una recibida en el SII con un tercero **no identificado,
    revocado o de baja**: un aviso que hay que aceptar para seguir (`CENSO_NIF_NO_IDENTIFICADO`, como el envío fuera de
    plazo), con la explicación de que el SII la rechazará.
    - No bloquea: el censo puede ir por detrás (una sociedad recién constituida) y la AEAT dice que se reintente.
  - Sin comprobar o «similar», solo aviso, sin confirmación.

### Documentación

El dominio del SII queda completo en `domain/sii.md` (reglas, modelo, estados, flujos, plazos, rechazos y esta decisión).

## Consecuencias

- El usuario siempre tiene salida ante un rechazo, sin romper la regla de que una emitida no se toca.
- La mayoría de los rechazos por NIF se evitan antes de emitir, también en VeriFactu y en el 347.
- **A depende de C para ser raro:** la sustitución es la cura; la prevención es lo normal.
- La comprobación del censo **no se puede probar en preproducción**: va con simulador y, en real, solo con la decisión
  expresa de José María.
- Por hacer: migración (`registro_sii.situacion = 'sustituida'`, columnas del censo en `tercero`), `app.sustituir_emitida`,
  trabajo `censo.comprobar` y su paquete (`@activopro/aeat`), pantallas y manual.

## Origen

Prueba en preproducción del 20/11/2026: «he emitido una factura… La AEAT la rechazó: 1117». José María: «me parece correcta
tu recomendación C y A; todo esto ha de quedar muy bien documentado en el md del SII».

Fuentes:
- [AEAT, preguntas técnicas frecuentes del SII](https://sede.agenciatributaria.gob.es/Sede/impuestos-tasas/iva/iva-libros-registro-iva-traves-aeat/preguntas-tecnicas-frecuentes.html)
- [AEAT, validaciones y errores del SII v1.1](https://sede.agenciatributaria.gob.es/static_files/Sede/Procedimiento_ayuda/G417/FicherosSuministros/V_1_1/Validaciones_ErroresSII_v1.1.pdf)
- [AEAT, manual técnico del servicio web masivo de calidad de datos identificativos](https://www3.agenciatributaria.gob.es/static_files/Sede/Biblioteca/Manual/Tecnicos/WS/030_036_037/Manual_Tecnico_WS_Masivo_Calidad_Datos_Identificativos.pdf)
