---
id: 0057
title: Documentos adjuntos al asiento, la factura y la ficha de inmovilizado, en el archivo y con su carga
status: accepted
date: 2026-11-20
services: [platform]
supersedes: '0005'
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

## Espacio y pantalla Documentos (ampliación del 21/11/2026)

De acuerdo con José María (conversación del 21/11/2026):

- **Espacio por cliente** (tenant), con el desglose por empresa: un espacio incluido (parámetro global `adjuntos.espacio_incluido`,
  con excepción por cliente) y **espacio adicional** por bloques como módulo que da de alta Enumbers desde la consola.
- **Cuenta solo lo que sube el cliente** (adjuntos de asiento, factura e inmovilizado y los originales de la bandeja que se conservan).
  No cuenta lo que genera la plataforma: PDF de los envíos, Facturae, informes ni los originales de la bandeja en sus 30 días.
- **Nunca se bloquea ni se borra lo que hay.** Pasado el espacio, solo no se sube nada a mano (`ADJUNTOS_SIN_ESPACIO`; la pantalla
  dice que para ampliarlo se contacte con Enumbers); ver, descargar y conservar sigue siempre (seis años, art. 30 del Código de Comercio), y ningún proceso contable se para:
  la bandeja sigue recibiendo.
- **Clientes migrados**: espacio inicial = el mayor entre el incluido y lo que traen más un margen, para que nadie empiece lleno. La
  cifra del espacio incluido se fija con el tamaño de los adjuntos por esquema de producción (consulta en
  `analysis/2026-11-tamano-adjuntos.sql`, la lanza José María).
- **Pantalla Documentos** (menú): árbol de contenedores fijos —empresa → ejercicio → asientos, facturas emitidas, facturas recibidas,
  inmovilizado— con el tamaño de cada nodo y búsqueda; cada documento se abre con su asiento, factura o ficha. Sin carpetas libres: un
  documento siempre cuelga de lo que documenta. Arriba, la tarjeta con el espacio usado y la barra, con aviso al 80 % y al 95 %.

## Implementación (21/11/2026)

Hecho en `activopro-platform` #220 (migración `20261231000034_adjuntos.sql`). Lo que quedaba abierto se resolvió así:

- **Tipos de fichero**: PDF, JPEG, PNG y XML (los de la bandeja) y Word, Excel y OpenDocument (`.docx`, `.xlsx`, `.odt`, `.ods`)
  reconocidos por el contenido; los antiguos `.doc` y `.xls` son un contenedor OLE que no dice lo que lleva, y ahí manda la extensión.
  PDF, imágenes y XML se ven en el visor; lo de ofimática se descarga siempre. Si la exportación de un cliente grande trae otros
  tipos, se añaden a la lista (H-115).
- **Terceros**: no desde el principio. El bloque está en el asiento, la factura (emitida y recibida, ya guardada) y la ficha de
  inmovilizado; terceros, remesas y documentos de venta se añaden con una columna del enlace cuando haga falta.
- **Ejercicio de una ficha de inmovilizado**: el de su fecha de inicio (si no la tiene, el de su alta); es el que decide si se puede
  quitar un documento y en qué ejercicio sale en la pantalla Documentos.
- **Cifras**: espacio incluido 5 GB (`adjuntos.espacio_incluido`, provisional hasta lanzar `analysis/2026-11-tamano-adjuntos.sql`),
  bloque de 10 GB (`adjuntos.bloque`) y margen del 25 % sobre lo cargado (`adjuntos.margen_carga`). Son parámetros versionados:
  cambiarlos es añadir un valor, sin tocar el código.
- **Espacio adicional**: no es un módulo de `tenant_modulo` sino dos datos del cliente (`tenant.espacio_adjuntos`, el incluido propio,
  y `tenant.bloques_adjuntos`) que cambia Enumbers en la consola con motivo; el cambio queda en el historial del cliente.
- **Purga**: al quedarse sin enlaces se programa el trabajo `adjunto.purgar` para el día en que se puede borrar; si para entonces se
  ha vuelto a adjuntar, no hace nada.
- **Pendiente** (H-115): el exportador y la carga por huella y la cifra definitiva del espacio.
- **Segunda fase** (21/11/2026, `activopro-platform` #227, migración `20261231000037_adjuntos_mas_destinos.sql`): enlace también al
  tercero (sin ejercicio: sus documentos se quitan siempre, con motivo), a la remesa (por su fecha de cargo) y al documento de venta;
  el original conservado de la bandeja queda además como adjunto de su factura sobre el mismo fichero (cuenta una vez; la purga de la
  bandeja no lo borra mientras el adjunto tenga enlaces).

## Consecuencias

- Desbloquea la migración de los clientes que adjuntan (148 de 162 tienen algún adjunto de asiento).
- El archivo pasa de casi vacío a unos 85 GB: dentro de los 100 GB del plan Pro de Supabase al principio, unos 2 $ al mes por cada
  100 GB después (estimación de costes del 20/11/2026). Ver un adjunto cuenta como tráfico de salida (250 GB incluidos).
- Las copias de MySQL de producción no cambian hasta que se apague el programa anterior.
- Sustituye a ADR-0005: los documentos no van a MinIO junto al programa anterior sino al archivo de la plataforma, y los adjuntos
  de MySQL se pasan allí en la migración de cada cliente.

## Origen

Conversación del 20/11/2026 sobre el coste del entorno nuevo (tamaños de producción) y análisis
`analysis/2026-11-paridad-programa-anterior.md`; hueco H-098 de `activopro-platform/docs/manual/huecos.md`.
