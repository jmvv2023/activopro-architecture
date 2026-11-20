---
id: 0057
title: Documentos adjuntos al asiento, la factura y la ficha de inmovilizado, en el archivo y con su carga
status: proposed
date: 2026-11-20
services: [platform]
supersedes: null
superseded_by: null
---

## Contexto

En el programa anterior se adjunta un documento a un asiento (`adjmovctas`, uno por asiento: empresa, ejercicio y número), a una
factura (`facturasadjuntos`, varios) y a una ficha de inmovilizado (`activofijoactdoc`, varios). Son el 80 % del tamaño de
producción: unos 477.000 adjuntos de asiento en 148 empresas, 81 GB guardados dentro de MySQL (`longblob`), más unos 3.800 de
facturas y 1.600 de inmovilizado (análisis de paridad del 20/11/2026, H-098).

En la plataforma solo existe el original de una factura recibida que entra por la bandeja (`documento_entrada`, ADR-0047), que se
guarda en el archivo (`@activopro/archivo`: Supabase Storage, cubo privado `documentos`) y no en la base, y que se borra a los 30 días
de registrarse salvo que la empresa elija conservar los originales. No hay forma de adjuntar nada a un asiento, una factura o una
ficha, y sin eso no se puede migrar a ningún cliente que adjunte.

Restricciones: los ficheros no van a la base (tamaño, copias, coste: ADR-0046); el aislamiento por tenant también en el archivo
(ruta `<tenant>/<empresa>/…` y acceso solo a través de la API); en ejercicios cerrados no se toca nada; los documentos de la
contabilidad se conservan seis años (art. 30 del Código de Comercio).

## Opciones consideradas

1. **Una tabla de adjuntos con enlaces** — `documento_adjunto` (el fichero: nombre, tipo por su contenido, tamaño, huella SHA-256
   única en la empresa, ruta en el archivo, subido por y cuándo) y `adjunto_enlace` (el adjunto con exactamente uno de `asiento_id`,
   `factura_id` o `activo_id`, y el orden). Un mismo fichero subido dos veces se guarda una vez; un adjunto puede estar en el asiento y
   en su factura. Un solo visor, una sola API y una sola carga para los tres orígenes; se amplía a terceros, remesas o documentos de
   venta añadiendo una columna al enlace. Contra: una tabla más que mantener coherente con lo que se anula (asientos anulados,
   facturas rectificadas).
2. **Una tabla por entidad** (`asiento_adjunto`, `factura_adjunto`, `activo_adjunto`), como el programa anterior. Más simple de leer,
   pero triplica funciones, pantallas y carga, y no deduplica.
3. **Guardar el fichero en la base** (`bytea`). Descartada: es exactamente lo que hoy hace pesar 81 GB a las copias nocturnas, y en
   Supabase el disco de la base cuesta unas seis veces más por GB que el archivo.

## Decisión

Opción 1. Propuesta concreta:

- **Ficheros**: PDF, JPEG, PNG, XML, y los de ofimática que aparezcan en la carga (Excel, Word); el tipo se decide por el contenido
  (como la bandeja), 15 MB por fichero. Ruta `<tenant>/<empresa>/adjuntos/<huella>`. Se sirven solo por la API, con `nosniff` y
  `Content-Security-Policy: sandbox`, y se ven con el visor de la bandeja (`visorDocumento.tsx`: pdf.js en canvas, imagen, XML como
  texto); lo demás se descarga.
- **Reglas en la base**: la aplicación solo lee; se escribe con `app.adjuntar(empresa, destino, fichero…)` y
  `app.quitar_adjunto(enlace, motivo)`. Adjuntar se puede siempre (documentar no cambia la contabilidad); quitar no, si el asiento,
  la factura o la ficha pertenecen a un ejercicio cerrado, y siempre con motivo y evento. Un fichero sin enlaces se borra del
  archivo cuando han pasado seis años desde la fecha del último documento al que estuvo enlazado (trabajo del worker, como la purga
  de la bandeja).
- **Pantallas**: bloque **Documentos** en el asiento, la factura (emitida y recibida) y la ficha de inmovilizado: lista, subir
  (arrastrar o elegir), ver al lado y quitar con motivo. El original de la bandeja sigue siendo lo que es (ADR-0047); al registrar
  una factura con «conservar originales», el original queda además como adjunto de la factura.
- **Carga**: un exportador propio (`exportar-adjuntos.cmd`) que vuelca cada `longblob` a un fichero con su huella como nombre y un
  índice TSV (empresa, ejercicio, asiento / factura / ficha, nombre, tipo, huella); el ETL sube por huella (lo ya subido no se repite,
  la carga se puede reanudar) y enlaza: `adjmovctas` al asiento por empresa, ejercicio y número; `activofijoactdoc` a la ficha;
  `facturasadjuntos` a la factura si está cargada (H-101) y, si no, a su asiento. Se hace por cliente, con su migración, nunca en el
  proyecto de demostración.

## Consecuencias

- Desbloquea la migración de los clientes que adjuntan (148 de 162 tienen algún adjunto de asiento).
- El archivo pasa de casi vacío a unos 85 GB: dentro de los 100 GB del plan Pro de Supabase al principio, unos 2 $ al mes por cada
  100 GB después (estimación de costes del 20/11/2026). Ver un adjunto cuenta como tráfico de salida (250 GB incluidos).
- Las copias de MySQL de producción no cambian hasta que se apague el programa anterior.
- Pendiente de decidir antes de implementar: la lista exacta de tipos de fichero (se verá en la exportación de un cliente grande) y
  si el bloque Documentos se ofrece también en terceros desde el principio.

## Origen

Conversación del 20/11/2026 sobre el coste del entorno nuevo (tamaños de producción) y análisis
`analysis/2026-11-paridad-programa-anterior.md`; hueco H-098 de `activopro-platform/docs/manual/huecos.md`.
