---
id: 0047
title: Bandeja de entrada de documentos — lectura del buzón por IMAP en el worker, factura recibida con visor y lectura automática (XML o OCR) detrás de una interfaz
status: proposed
date: 2026-11-18
services: [core, ocr]
supersedes: null
superseded_by: null
---

## Contexto

En la plataforma, una factura recibida se registra tecleándola (ADR-0030). Faltan dos cosas que en GeneXus ya existen y se
usan cada día.

### La bandeja de GeneXus (`WWBandeja`, `IngBandeja`, tabla de entradas `BanEnt…`)

- **Cuatro bandejas por empresa:**
  - `R` facturas recibidas;
  - `O` otros documentos;
  - `A` contabilización automática (neoscan: PDF y XML);
  - `P` papelera, que se vacía sola a los 60 días.
- **Entrada:** dos vías.
  - «Revisar bústia» lee por **POP3** (`pop.1and1.es`, 995) los dos buzones de la empresa: `empresa.facturas@` va a `R` y
    `empresa.docs@` va a `O`. Solo coge los adjuntos **PDF**, guarda cada uno en la base (blob) con el remitente y la fecha, y
    **borra el mensaje del buzón**. La lectura es manual, con el botón.
  - «Pujar factures» para subirlos a mano.
- **Uso:** la rueda abre el formulario de la factura recibida (`IngFRN`) con el documento en un visor al lado. «Cargar con
  IA» llama a ms-activopro-ocr y rellena los campos. Un documento de `O` se abre con caja, banco o varios (asiento).
  «Mover a» lo pasa a otra bandeja. Al registrarlo, el documento queda **adjunto al asiento**. `Descarga_Adjuntos` baja en un
  zip los de un trimestre, para la gestoría.

### Lo que ya tiene la plataforma

- **Buzones de la empresa** en IONOS (`buzon_correo`, ADR-0046 §5): uso `facturas` y `documentos`, con la contraseña en
  Vault. Hoy solo envían (SMTP).
- **Worker con cola en Postgres** (ADR-0046 §4) y **archivo** (`@activopro/archivo`: Supabase Storage o una carpeta local).
- **Rebotes sin leer** (huecos H-076). Un correo que IONOS acepta y después se devuelve llega como rebote al **mismo buzón
  de facturas**, y el envío se queda en «Enviada».
- **Formulario de factura recibida** con propuesta por tercero (`app.propuesta_factura`: cuenta, tipo, retención, forma de
  pago), aviso de duplicada (`app.avisos_factura`) y alta del tercero desde el formulario.

### ms-activopro-ocr (`ocr.activopro.net`, Python, FastAPI, SQLite)

- `POST /ocr` (multipart, `tenant_id`) devuelve, de forma síncrona:
  - proveedor y NIF, cliente;
  - número, fechas;
  - líneas, desglose de IVA, base y total;
  - tipo de documento.
- Combina regex, LLM y una validación fiscal. Aprende de las correcciones (`POST /ocr/correccion`, proveedores conocidos).
- **Funciona bien**, según el uso real.
- **Pero no tiene autenticación** (CORS `*`, sin clave). Además **guarda** el texto y una copia del documento de cada
  petición, y no tiene un modo para no hacerlo.

### Factura electrónica

- La factura electrónica B2B (ADR-0006, `domain/spfe.md`) llegará como **UBL**, y las de las administraciones y algunos
  proveedores ya llegan como **Facturae**.
- Recibir por la SPFE en nombre del cliente necesita apoderamiento o su certificado (aplazado). Mientras tanto, el XML llega
  por correo o se sube a mano.

### Conservación

Quien recibe la factura tiene que conservarla: 4 años por la LGT y 6 por el Código de Comercio. La obligación es de la
empresa, no de ActivoPro. Hay empresas que quieren que ActivoPro guarde el original y otras que lo guardan en su propio
archivo (decisión de José María, 17/11/2026: **guardarlo solo si la empresa lo quiere**).

## Opciones consideradas

### Leer el buzón

1. **POP3 y borrar, como GeneXus.**
   - Lo más simple.
   - El cliente pierde el correo de su buzón. Si algo falla entre leer y guardar, el documento se pierde.
2. **IMAP, mover lo procesado a una carpeta.**
   - El correo queda en el buzón de IONOS, que hace de archivo del cliente.
   - Es idempotente: se lee por UID y la `UIDVALIDITY` de la carpeta, y la huella del adjunto evita duplicados.
   - Los rebotes se leen en la misma pasada.
3. **Reenvío a un webhook** (IONOS no lo ofrece en estos buzones; exigiría otro proveedor). Descartada.

### Dónde está el documento mientras está pendiente

1. **Siempre en el archivo** (Storage), y se borra o se conserva al registrarlo según la empresa.
   - El visor lo sirve rápido y no depende de que el correo siga en el buzón.
2. **Solo en el buzón**, pidiéndolo por IMAP cada vez que se abre.
   - No guarda nada.
   - Es lento, falla si el cliente borra el correo, y no sirve para lo subido a mano.

### Lectura automática (OCR)

1. **ms-activopro-ocr desde el worker.**
   - Ya funciona y aprende de las correcciones.
   - Hay que añadirle autenticación (clave por cliente de la API) y un modo **sin conservar** (borrar el fichero y el
     texto al responder).
2. **Un modelo con visión** (p. ej. la API de Claude) llamado desde el worker.
   - Sin servicio que mantener.
   - Coste por documento, y un encargado del tratamiento más. Sin el aprendizaje por proveedor que ya hay.
3. **Portar el OCR al monorepo.**
   - Es Python, con PaddleOCR y modelos pesados: no encaja en el worker de Node. Descartada.

## Decisión (propuesta)

### 1. Lectura del buzón: IMAP en el worker, sin borrar nada

- Cada buzón activo de la empresa (`facturas` y, en la fase 2, `documentos`) se lee por **IMAP**, en `imap.ionos.es`:993
  con TLS y las mismas credenciales del envío. Esto añade a `buzon_correo` el servidor y el puerto IMAP, con IONOS por
  defecto.
- El trabajo se llama `correo.leer`.
  - Hay uno vivo por buzón (clave = buzón), que **se vuelve a encolar** cada 5 minutos (`disponible_desde`).
  - Con «Revisar ahora» en la bandeja, se adelanta. Sin cron externo: la cola ya tiene `aplazar`.
- **Por cada mensaje nuevo** de la bandeja de entrada (UID mayor que el último leído, con su `UIDVALIDITY`):
  - **Rebote de un envío nuestro.** Es un informe de entrega (`multipart/report`, `message/delivery-status`), o lleva nuestra
    cabecera `X-ActivoPro-Envio` en el mensaje devuelto, o su `Original-Message-ID` coincide con un envío. El envío pasa a
    `rebotado`, con el destinatario y el motivo. Se avisa en la factura y en la portada. El mensaje se mueve a
    `ActivoPro/Rebotes`. Así se cierra H-076.
  - **Con adjuntos admitidos** (PDF, XML, JPG, PNG; 15 MB como mucho cada uno): cada adjunto es un **documento de entrada**,
    con remitente, asunto, fecha y `Message-ID`. El mensaje se mueve a `ActivoPro/Procesados`.
  - **Sin adjuntos admitidos:** se queda donde está, marcado como visto, sin tocar. Puede ser correo normal del cliente.
- **Duplicados:** un documento con la misma huella (SHA-256) en la misma empresa no se crea dos veces. Se anota que ha
  vuelto a llegar.
- **Errores:** si la contraseña no vale o no hay conexión, el estado de lectura del buzón lo dice («no se pudo leer el
  buzón: …»). La bandeja lo enseña y la consola también. El trabajo reintenta como los demás.
- **Nunca se ejecuta ni se interpreta el contenido del correo:** ni HTML ni enlaces. Solo cabeceras y adjuntos.

### 2. Documento de entrada y archivo

- **`documento_entrada`**, por empresa, con RLS:
  - **bandeja:** `facturas` o `documentos`;
  - **origen:** `correo`, `subida` o, más adelante, `spfe`;
  - **mensaje:** remitente, asunto, fecha y `Message-ID`;
  - **fichero:** nombre, tipo, tamaño, huella y ruta en el archivo;
  - **estado:** `pendiente` → `registrado` (con `factura_id` o `asiento_id`) / `descartado` → borrado;
  - **lectura:** `lectura` (jsonb: campos con su confianza y de dónde salen: XML, OCR o propuesta) y `lectura_estado`
    (`sin_leer`, `leyendo`, `leido`, `error`);
  - **trazabilidad:** quién lo registró o descartó y cuándo.
- La aplicación solo lee. Se escribe con funciones (`app.subir_documento_entrada`, `app.descartar_documento_entrada`,
  `app.restaurar_documento_entrada`) y, al registrar, `app.guardar_factura` acepta `documento_entrada_id`.
- **Mientras está pendiente**, el fichero está en el archivo: cubo privado `entrada` o la carpeta local. Es la opción 1.
- **Al registrarlo**, según la empresa (`empresa_config_documentos.conservar_originales`, **no** por defecto):
  - **conservar:** el documento queda **adjunto a la factura** (o al asiento) y se ve desde ella mientras exista. Se
    borra al cabo del plazo de conservación que fije la empresa, 6 años por defecto, o cuando ella lo pida.
  - **no conservar:** se borra del archivo a los 30 días de registrarlo, para poder corregir la factura viéndolo. Si llegó
    por correo, el original sigue en el buzón del cliente (`ActivoPro/Procesados`). Lo subido a mano solo lo tiene el
    cliente.
- **Descartados:** van a la papelera y se borran a los 60 días, como en GeneXus. Se pueden recuperar mientras tanto.
- **Coste:** una factura en PDF pesa entre 50 y 300 KB. Pendientes y 30 días de gracia son poco. Conservar de verdad es lo
  que crece, y solo lo hacen las empresas que lo eligen. Se mide por empresa (`archivo_bytes` en la consola) por si hubiera
  que repercutirlo.

### 3. Lectura automática: XML primero; OCR detrás de una interfaz

- **Interfaz `LectorDocumento`** (paquete `@activopro/lectura`, sin acceso a la base). Entra un fichero y sale una
  `LecturaFactura`:
  - emisor (NIF, nombre, país);
  - número, fechas;
  - líneas;
  - desglose por tipo;
  - retención;
  - total;
  - confianza por campo.
- **XML (Facturae 3.2.x, UBL 2.1/2.5):** se lee en el paquete, sin OCR y con confianza total. Si trae varias facturas, se
  crea un documento por cada una.
- **PDF e imagen:** **ms-activopro-ocr** (opción 1), llamado por el worker (`documento.leer`) al llegar el documento. Antes
  de usarlo con datos de la plataforma, el micro necesita:
  - una **clave de API** por cliente (la plataforma y GeneXus), y CORS cerrado;
  - un **modo sin conservar** (`conservar=false`: borra el fichero y el texto al responder). El aprendizaje por proveedor y
    las correcciones se guardan igual, porque no son el documento.
  - Este cambio va en el repo del micro, con su propio PR.
- **Al registrar,** la diferencia entre lo leído y lo registrado se manda como corrección (`/ocr/correccion`), como hace
  GeneXus. Así el aprendizaje sigue mejorando con las facturas de la plataforma.
- **La propuesta es de la plataforma, no del OCR.** Del NIF leído sale el tercero, y si no existe se ofrece darlo de alta
  con lo leído. Del tercero, la cuenta, el tipo, la retención y la forma de pago (`app.propuesta_factura`). Del OCR, solo
  los datos del documento.
- Si mañana conviene otro lector (un modelo con visión, otro servicio), se cambia la implementación de la interfaz.

### 4. Pantalla: Bandeja (Facturación)

- Va en **Facturación → Bandeja**, con el contador «Por registrar» en la portada de Facturación y en **Inicio**.
- **Lista:**
  - columnas: fecha, de quién (remitente o «Subido por …»), fichero, lo leído (emisor, número, total) y estado;
  - pestañas: pendientes, registrados, papelera;
  - **Subir documentos**, arrastrando varios a la vez;
  - **Revisar el buzón ahora**;
  - las direcciones de los buzones de la empresa, para dárselas a los proveedores.
- **Registrar:** el formulario de la factura recibida de siempre, con el **visor a la izquierda**.
  - El visor es pdf.js, que pinta en un canvas sin ejecutar nada del PDF. Tiene zoom, páginas y girar; el XML se ve como
    una factura.
  - Los datos leídos van rellenos y marcados («leído», con un punto de color si la confianza es baja).
  - Lo propuesto por el tercero, como hoy.
  - **«Contabilizar y siguiente»** pasa al siguiente pendiente sin volver a la lista.
  - En pantallas estrechas, el visor es una pestaña («Documento» / «Factura»).
- **Otras acciones:** **Descartar** (a la papelera, con motivo opcional) y **Mover a documentos**.
- **Factura registrada desde la bandeja:** enseña el documento en su ficha mientras exista (siempre, si la empresa conserva
  los originales) y deja **bajarlo**.

### 5. Permisos y módulos

- Ver la bandeja es `facturacion.consultar`. Subir, registrar y descartar, `facturacion.preparar`.
- Conservar los originales y el plazo se configuran en Datos de la empresa → Documentos (`empresa.configurar`).
- Los buzones los sigue dando de alta Enumbers en la consola. La lectura se activa sola cuando el buzón existe, con un
  interruptor «Leer el buzón» por si una empresa no la quiere.

### Fases

1. **Lectura del buzón de facturas y rebotes** (IMAP, `correo.leer`, rebotes → envío `rebotado`), `documento_entrada`,
   subida a mano, bandeja con visor y registrar como factura recibida, conservar o no. **Sin lectura automática:** se
   teclea con el documento al lado, como hoy en GeneXus sin «Cargar con IA».
2. **Lectura automática:** `@activopro/lectura` con XML (Facturae y UBL) y el cliente de ms-activopro-ocr (después del PR del
   micro: clave y modo sin conservar), y correcciones al registrar.
3. **Buzón de documentos y adjuntos de asientos:** bandeja `documentos` (registrar como asiento, con plantilla, o como
   movimiento de tesorería), adjuntar documentos a cualquier asiento y bajar en un zip los de un trimestre (como
   `Descarga_Adjuntos`).

## Consecuencias

- **Una sola pieza lee el buzón** para las facturas que entran y los rebotes de las que salen. La factura electrónica
  tendrá ya su canal de entrada (XML por correo o subido) antes de la SPFE.
- **El buzón deja de vaciarse.** El cliente conserva sus correos en IONOS (cuota del buzón: se vigila en la consola) y la
  lectura es repetible sin perder nada.
- **El OCR pasa a ser una dependencia de la plataforma**, aunque sustituible. Hasta que el micro tenga clave y modo sin
  conservar, la plataforma no le manda documentos (fase 2).
- **Datos personales:** las facturas recibidas tienen datos de terceros. Quedan en el archivo con RLS por empresa, bajo el
  mismo tratamiento que el resto. Con el OCR sin conservar, no se copian a otro sitio.
- **Pendiente:**
  - recibir por la SPFE en nombre del cliente (apoderamiento; `domain/spfe.md`);
  - la contabilización automática sin revisión (la bandeja `A` de GeneXus);
  - el reenvío a la gestoría.

## Preguntas para decidir

1. **Conservar originales:** ¿«no» por defecto y 6 años si se activa?
2. **Buzón:** ¿mover lo procesado a `ActivoPro/Procesados`, o borrar como hace hoy GeneXus?
3. **Frecuencia:** ¿cada 5 minutos automático más «Revisar ahora», o solo manual como hoy?
4. **OCR:** ¿ms-activopro-ocr con clave y modo sin conservar, o probar un modelo con visión?
5. **Fases:** ¿la fase 1 sin lectura automática, o esperar a tener el OCR para que no se vea como un paso atrás frente a
   «Cargar con IA»?

## Origen

Revisión del 17/11/2026 con José María: bandeja de GeneXus («cuando pulsas en la rueda se abre el diálogo para informar la
factura recibida con un visor en el lateral… tiene el botón cargar que utiliza el ms-activopro-ocr»), guardar el PDF solo si
el cliente lo quiere, rebotes del correo (H-076) y huecos H-079.
