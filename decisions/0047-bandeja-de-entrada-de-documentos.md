---
id: 0047
title: Bandeja de entrada de documentos — buzón por IMAP al pedirlo, factura recibida con visor y lectura automática en un servicio propio sin estado
status: accepted
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
- Combina PaddleOCR, regex, un LLM (Groq, Gemini, OpenAI o Mistral, con circuito de corte) y una validación fiscal.
  Aprende de las correcciones (`POST /ocr/correccion`, proveedores conocidos), que guarda en su SQLite.
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
2. **Elegida. IMAP, y lo procesado a la papelera del buzón con borrado a los 30 días.**
   - Nada se borra antes de estar guardado en la plataforma, y el cliente tiene 30 días para recuperarlo de la papelera. El
     buzón (2 GB) no se llena.
   - Es idempotente: se lee por UID y la `UIDVALIDITY` de la carpeta, y la huella del adjunto evita duplicados.
   - Los rebotes se leen en la misma pasada.
3. **Reenvío a un webhook** (IONOS no lo ofrece en estos buzones; exigiría otro proveedor). Descartada.

### Dónde está el documento mientras está pendiente

1. **Elegida. Siempre en el archivo** (Storage), y se borra o se conserva al registrarlo según la empresa.
   - El visor lo sirve rápido y no depende de que el correo siga en el buzón.
2. **Solo en el buzón**, pidiéndolo por IMAP cada vez que se abre.
   - No guarda nada.
   - Es lento, falla si el cliente borra el correo, y no sirve para lo subido a mano.

### Lectura automática: con qué servicio

1. **Usar ms-activopro-ocr tal cual desde la plataforma.**
   - Ya funciona.
   - Un mismo servicio para dos productos con ritmos distintos: un cambio para la plataforma (albaranes de proveedor, el
     contrato tipado, la retención) es un riesgo para GeneXus, y al revés.
   - Su estado (SQLite con documentos, texto y aprendizaje) no es de la plataforma ni está bajo su RLS.
2. **Un modelo con visión** llamado desde el worker.
   - Sin servicio que mantener.
   - Pierde lo que el micro ya resuelve bien (regex primero, validación fiscal, control de NIF, aprendizaje por proveedor),
     tiene coste por documento y añade un encargado del tratamiento más.
3. **Elegida. Un servicio de lectura propio de la plataforma, que parte del micro.**
   - Es una copia del código de ms-activopro-ocr en el monorepo (`servicios/lectura`).
   - **No guarda nada:** ni documento ni texto ni aprendizaje. Lo que aprende se guarda en la base de la plataforma, por
     empresa, y se le pasa en cada petición.
   - El contrato es tipado y crece por tipo de documento: factura recibida, albarán de proveedor, ticket.
   - ms-activopro-ocr sigue sirviendo a GeneXus sin cambios y se retira cuando GeneXus se apague.

## Decisión

### 1. Lectura del buzón: IMAP en el worker, al pedirla, y lo leído a la papelera

- **Cómo se lee.** Cada buzón activo de la empresa se lee por **IMAP**: el de `facturas` y, en la fase 3, el de `documentos`.
  - Va a `imap.ionos.es`:993, con TLS y las mismas credenciales del envío. A `buzon_correo` se le añaden el servidor y el
    puerto IMAP, con IONOS por defecto.
  - Lo hace el worker con el trabajo `correo.leer`, uno vivo por buzón.
- **Cuándo se lee: solo cuando hace falta, nunca en continuo.**
  - Al **entrar en la Bandeja**, si la última lectura tiene más de 2 minutos.
  - Con el botón **Revisar el buzón**.
  - **Unos 15 minutos después de enviar correos de la empresa**, una vez, para recoger los rebotes. Es un trabajo aplazado
    con la clave del buzón, así que varios envíos seguidos dan una sola lectura.
  - La pantalla enseña cuándo se leyó por última vez y mientras lee dice «Revisando el buzón…»; el resultado se ve sin
    recargar.
- **Por cada mensaje nuevo** de la bandeja de entrada (UID mayor que el último leído, con su `UIDVALIDITY`):
  - **Rebote de un envío nuestro.** Se reconoce porque es un informe de entrega (`multipart/report`,
    `message/delivery-status`), lleva nuestra cabecera `X-ActivoPro-Envio` en el mensaje devuelto, o su
    `Original-Message-ID` coincide con un envío.
    - El envío pasa a `rebotado`, con el destinatario y el motivo, y se avisa en la factura y en la portada.
    - El mensaje va a la papelera.
    - Así se cierra H-076.
  - **Con adjuntos admitidos** (PDF, XML, JPG, PNG; 15 MB como mucho cada uno): cada adjunto es un **documento de entrada**,
    con el remitente, el asunto, la fecha y el `Message-ID`. El mensaje va a la papelera.
  - **Sin adjuntos admitidos:** se queda en la bandeja de entrada, sin tocar. Puede ser correo normal del cliente.
- **Papelera del buzón.**
  - Los mensajes procesados se mueven a la **papelera del buzón** de IONOS (la carpeta con el atributo `\Trash`), porque el
    buzón tiene 2 GB.
  - En cada lectura, el lector **borra de la papelera los que movió hace más de 30 días**. Los reconoce por su `Message-ID`,
    guardado en `buzon_lectura_mensaje`, así que no toca nada que el cliente haya tirado por su cuenta.
  - La bandeja lo dice: «Los correos leídos pasan a la papelera del buzón y se borran a los 30 días».
- **Duplicados:** un documento con la misma huella (SHA-256) en la misma empresa no se crea dos veces; se anota que ha vuelto
  a llegar.
- **Errores:** si la contraseña no vale o no hay conexión, la bandeja enseña «No se pudo leer el buzón: …» y la consola
  también. Nada se mueve ni se borra si el documento no ha quedado guardado: primero se guarda y se confirma, después se
  mueve el mensaje.
- **Nunca se ejecuta ni se interpreta el contenido del correo:** ni HTML ni enlaces. Solo cabeceras y adjuntos.

### 2. Documento de entrada y archivo

- **`documento_entrada`**, por empresa, con RLS:
  - **bandeja:** `facturas` o `documentos`;
  - **origen:** `correo`, `subida` o, más adelante, `spfe`;
  - **mensaje:** remitente, asunto, fecha y `Message-ID`;
  - **fichero:** nombre, tipo, tamaño, huella y ruta en el archivo;
  - **estado:** `pendiente` → `registrado` (con `factura_id` o `asiento_id`, y más adelante `entrada_genero_id`) /
    `descartado` → borrado;
  - **lectura:** `lectura` (jsonb: campos con su confianza y de dónde salen: XML, lector o propuesta) y `lectura_estado`
    (`sin_leer`, `leyendo`, `leido`, `error`);
  - **trazabilidad:** quién lo registró o descartó y cuándo.
- La aplicación solo lee. Se escribe con funciones: `app.subir_documento_entrada`, `app.descartar_documento_entrada` y
  `app.restaurar_documento_entrada`. Al registrar, `app.guardar_factura` acepta `documento_entrada_id`.
- **Mientras está pendiente**, el fichero está en el archivo de la plataforma: cubo privado `entrada`, o la carpeta local.
- **Al registrarlo**, según la empresa (`empresa_config_documentos.conservar_originales`, **desactivado** por defecto):
  - **Conservar:** el documento queda **adjunto a la factura** (o al asiento) y se ve y se baja desde ella. Se guarda **6
    años como máximo** desde la fecha de la factura y después se borra solo. La opción lo dice: «ActivoPro conserva los
    originales un máximo de 6 años; para plazos más largos, guárdalos también en tu archivo».
  - **No conservar:** se borra del archivo a los 30 días de registrarlo, para poder corregir la factura viéndolo. Como el
    correo también se borra a los 30 días, la opción avisa: «El original no se conserva en ActivoPro: guárdalo en tu archivo».
    Cada factura deja **bajarlo** mientras exista.
- **Descartados:** van a la papelera de la bandeja y se borran a los 60 días, como en GeneXus. Se pueden recuperar mientras
  tanto.
- **Coste:** una factura en PDF pesa entre 50 y 300 KB. Lo pendiente y los 30 días son poco. Conservar es lo que crece, y
  solo en las empresas que lo eligen. Se mide por empresa (`archivo_bytes` en la consola).

### 3. Lectura automática: XML en un paquete; PDF e imagen en el servicio de lectura de la plataforma

- **Interfaz `LectorDocumento`** en el paquete `@activopro/lectura`, sin acceso a la base. Entra un fichero, el tipo de
  documento esperado y las pistas de la empresa. Sale una `LecturaDocumento` tipada:
  - **cabecera:** emisor (NIF, nombre, país), número, fechas, total;
  - **líneas:** descripción, código, cantidad, precio, descuento, tipo y, en un albarán, lote y caducidad;
  - **desglose por tipo** y **retención**;
  - **confianza por campo**.
- **XML (Facturae 3.2.x, UBL 2.1/2.5):** se lee en el paquete, sin OCR y con confianza total. Si el fichero trae varias
  facturas, se crea un documento por cada una.
- **PDF e imagen: servicio `lectura`** en el monorepo (`servicios/lectura`, Python + FastAPI).
  - **De dónde sale:** de ms-activopro-ocr: PaddleOCR y pdfplumber, regex primero, LLM si falta algo, validación fiscal,
    control del NIF.
  - **Sin estado.** No hay SQLite ni carpeta de subidas: lo recibido se borra al responder. Lo que el micro aprende y guarda
    (proveedor → NIF, correcciones) pasa a la base de la plataforma, por empresa y con RLS: `lectura_proveedor` y
    `lectura_correccion`. El worker se lo manda como pistas en cada petición.
  - **Con clave:** solo lo llama el worker, con una clave de servicio. Sin CORS. Va en la red privada, al lado del worker.
  - **Proveedores de LLM:** solo los que tengan contrato de encargado del tratamiento y no guarden ni usen para entrenar lo
    que se les manda. Se configuran por entorno, con la lista de permitidos en el código.
  - **Por tipo de documento:** `factura_recibida` (fase 2), `albaran_proveedor` para la entrada de género del Almacén (fase
    4) y `ticket`. Cada tipo tiene su esquema de salida y sus tests con documentos ficticios.
  - **Despliegue:** su propia imagen y su versión (`CHANGELOG.md`), como Gotenberg; el worker la llama por
    `LECTURA_URL`.
- **ms-activopro-ocr sigue para GeneXus**, sin cambios de contrato. Se recomienda cerrarle CORS y ponerle clave también; va en
  un PR aparte, en su repo. Se retira cuando GeneXus se apague.
- **Correcciones:** al registrar, la diferencia entre lo leído y lo registrado se guarda en `lectura_correccion`, y la
  relación nombre → NIF confirmada, en `lectura_proveedor`. Son las pistas de la siguiente lectura de esa empresa.
- **La propuesta contable es de la plataforma, no del lector.**
  - Del NIF leído sale el tercero; si no existe, se ofrece darlo de alta con lo leído.
  - Del tercero salen la cuenta, el tipo, la retención y la forma de pago (`app.propuesta_factura`).
  - Del lector salen solo los datos del documento.

### 4. Pantalla: Bandeja (Facturación)

- Va en **Facturación → Bandeja**, con el contador «Por registrar» en la portada de Facturación y en **Inicio**.
- **Lista:**
  - columnas: fecha, de quién (remitente o «Subido por …»), fichero, lo leído (emisor, número, total) y estado;
  - pestañas: pendientes, registrados, papelera;
  - acciones: **Subir documentos** (varios a la vez, arrastrando) y **Revisar el buzón**, con la hora de la última lectura;
  - las direcciones de los buzones de la empresa, para dárselas a los proveedores, y el aviso de la papelera del buzón.
- **Registrar:** el formulario de la factura recibida de siempre, con el **visor a la izquierda**.
  - El visor es pdf.js: pinta en un canvas sin ejecutar nada del PDF. Tiene zoom, páginas y girar. El XML se ve como una
    factura.
  - Los datos leídos van rellenos y marcados («leído»; un punto de color si la confianza es baja); lo propuesto por el
    tercero, como hoy.
  - **«Contabilizar y siguiente»** pasa al siguiente pendiente sin volver a la lista.
  - En pantallas estrechas, el visor es una pestaña («Documento» / «Factura»).
- **Otras acciones:** **Descartar** (a la papelera, con motivo opcional) y **Mover a documentos**.
- **Factura registrada desde la bandeja:** enseña el documento en su ficha mientras exista y deja bajarlo.
- **Diseño:** las piezas de `apps/web/src/ui` (`Estado`, `BarraCambios`, tarjetas con perfil), los textos en es, ca y en, y su
  página en el manual con capturas.

### 5. Permisos y configuración

- Ver la bandeja es `facturacion.consultar`. Subir, registrar y descartar, `facturacion.preparar`.
- **Conservar los originales** se configura en Datos de la empresa → Documentos (`empresa.configurar`), con la leyenda de
  los 6 años.
- Los buzones los sigue dando de alta Enumbers en la consola. La lectura se puede apagar por buzón («Leer el buzón»).

### Fases

Se hace todo, en este orden y sin prisa: ningún cliente está en la plataforma todavía.

1. **Bandeja y rebotes:**
   - lectura del buzón de facturas al pedirla (IMAP, `correo.leer`, papelera del buzón con borrado a los 30 días);
   - rebotes → envío `rebotado`;
   - `documento_entrada`, subida a mano;
   - bandeja con visor y registrar como factura recibida;
   - conservar o no los originales.
2. **Lectura automática de facturas:**
   - `@activopro/lectura` con XML (Facturae y UBL);
   - servicio `lectura` (copia del micro sin estado, con clave) y su cliente en el worker;
   - lectura al llegar el documento, pistas y correcciones en la base.
3. **Buzón de documentos y adjuntos:**
   - bandeja `documentos` (registrar como asiento con plantilla, o como movimiento de tesorería);
   - adjuntar documentos a cualquier asiento;
   - bajar en un zip los de un trimestre, para la gestoría.
4. **Albaranes de proveedor:** tipo `albaran_proveedor` en el servicio y registrar el documento como entrada de género del
   Almacén (líneas con producto, cantidad, lote y caducidad), enlazable después con la factura recibida (ADR-0041, fase 4).

## Consecuencias

- **Una sola pieza lee el buzón** para las facturas que entran y los rebotes de las que salen. La factura electrónica tendrá
  ya su canal de entrada (XML por correo o subido) antes de la SPFE.
- **El buzón no se llena.** Lo leído pasa a la papelera y se borra a los 30 días.
- **El original lo conserva la empresa:** en ActivoPro si lo elige (6 años como máximo), o en su archivo. La pantalla lo dice
  en los dos casos.
- **La plataforma tiene su propio lector**, sin estado y con lo aprendido en su base. Se puede ampliar a albaranes, tickets u
  otros documentos sin tocar lo de GeneXus. El precio es mantener una copia del código del micro mientras convivan; las
  mejoras de la lectura se hacen en la de la plataforma.
- **No hay sondeo continuo:** sin nadie en la bandeja y sin envíos, no se conecta al buzón.
- **Datos personales:** las facturas recibidas tienen datos de terceros.
  - Quedan en el archivo, con RLS por empresa.
  - El lector no guarda nada, y los LLM solo pueden ser proveedores con contrato y sin retención.
- **Pendiente:**
  - recibir por la SPFE en nombre del cliente (apoderamiento; `domain/spfe.md`);
  - la contabilización automática sin revisión (la bandeja `A` de GeneXus);
  - el reenvío a la gestoría.

## Decisiones de José María (18/11/2026)

1. Conservar originales: desactivado por defecto; si se activa, con la leyenda de que se conservan 6 años como máximo.
2. El buzón de IONOS tiene 2 GB: lo leído va a la papelera y se borra a los 30 días, y se informa de ello.
3. Nada de lectura continua: con un botón, o al entrar.
4. Partir del micro existente: dejar el actual para el servicio que da hoy y clonarlo como módulo de lectura de la
   plataforma, ampliable a otras entradas (albaranes de proveedor para el almacén…).
5. Hacer el proceso completo de forma progresiva, bien hecho aunque lleve más tiempo: una plataforma completa, segura,
   funcional, fácil para el usuario y coherente.

## Origen

Revisión del 17/11/2026 con José María: bandeja de GeneXus («cuando pulsas en la rueda se abre el diálogo para informar la
factura recibida con un visor en el lateral… tiene el botón cargar que utiliza el ms-activopro-ocr»), guardar el PDF solo si
el cliente lo quiere, rebotes del correo (H-076) y huecos H-079.
