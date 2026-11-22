---
id: 0061
title: Lector de documentos propio sin LLM externo — datos estructurados primero, texto con posiciones, plantillas por proveedor aprendidas y compartidas, modelo de documento ligero y local para escaneados, y comprobación fiscal
status: accepted
date: 2026-11-22
services: [platform, ocr]
supersedes: null
superseded_by: null
---

Modifica el punto 3 de ADR-0047 («servicio `lectura`, copia del micro, LLM si falta algo»). El resto de ADR-0047 (buzón,
bandeja, visor, conservar originales, fases 1, 3 y 4) no cambia.

## Contexto

- **Lo que hace hoy ms-activopro-ocr:**
  - extrae el texto: PyMuPDF en los PDF con texto y PaddleOCR en los escaneados;
  - después aplica regex, un clasificador y, para lo que falta, un LLM (Groq, Gemini, DeepSeek, OpenAI, Mistral);
  - valida y aprende un nombre → NIF por proveedor.
  - **Del PDF se queda solo el texto corrido** (`get_text()`): pierde dónde está cada dato en la página. Por eso las
    regex tienen que adivinar qué importe es la base y cuál el total.
- **Lo que dice el monitor (22/11/2026, 87 documentos, 3 clientes):**
  - `regex_sin_llm`: **32 (37 %)**, completos sin LLM.
  - `regex_fallback`: **55 (63 %)**. Se llamó al LLM y fallaron todos los proveedores, o no había ninguno configurado
    (`pipeline.py`: `RuntimeError` → confianza 0,3).
  - `llm_hibrido`: **0**. **El LLM no ha completado ni un documento.**
  - Correcciones registradas: **0**. **No sabemos si lo leído es correcto.** «Completo» quiere decir que hay un valor,
    no que sea el bueno.
- **El LLM trae costes aunque no funcione:**
  - Envía facturas de terceros, con datos personales, a proveedores de fuera de la UE (DeepSeek en China; Groq y OpenAI
    en EE. UU.): transferencias internacionales, contratos de encargado y una lista de subencargados que mantener.
  - Los modelos se retiran sin aviso (Groq quitó `llama-3.3-70b` el 16/08/2026).
  - Sus respuestas no se pueden reproducir ni explicar campo a campo.
- **Reglamento de IA (UE 2024/1689, modificado por el Digital Omnibus):**
  - Extraer datos de una factura no es un uso de alto riesgo (anexo III).
  - Lo que se define a mano (reglas, plantillas, comprobaciones aritméticas) queda fuera de la definición de sistema de
    IA, según las directrices de la Comisión.
  - Un motor de OCR con red neuronal (PaddleOCR, Tesseract 5) sí entra en la definición, pero es de riesgo mínimo.
  - **El riesgo real no es el Reglamento de IA, sino el RGPD:** dónde va el documento y quién lo procesa.
- **Las facturas llegan cada vez más estructuradas:**
  - Facturae / UBL por correo.
  - El QR de los sistemas de facturación (VeriFactu o no), con NIF del emisor, número, fecha e importe total. Según el BOE
    vigente es obligatorio en 2027: el 1 de enero para las sociedades y el 1 de julio para el resto. Hacienda ha
    anunciado otro aplazamiento, sin publicar todavía.
  - La factura electrónica B2B (Orden HAC/1028/2026): a unos 12 meses para los de más de 8 M € y a unos 24 para el resto.
  - **Lo que hay que leer «a ojo» irá a menos.** No compensa una pieza cara y opaca para un problema que se reduce.
- **Lo que viene después:** la misma lectura para los albaranes de proveedor en la entrada de género (ADR-0041, ADR-0047
  fase 4). Ahí importan las líneas: código, cantidad, precio, lote y caducidad.

## Opciones consideradas

1. **Copiar el micro con su LLM** (lo que decía ADR-0047).
   - Ya existe.
   - Los datos dicen que hoy el LLM no aporta nada.
   - Conserva el problema de las transferencias y de los modelos que se retiran.
   - Hereda el defecto de leer texto sin posiciones.
2. **Servicio de un proveedor en la nube** (Azure Document Intelligence, Google Document AI, Textract, con región UE).
   - Lee muy bien.
   - Coste por página, encargado del tratamiento, dependencia de un tercero y caja negra.
3. **Modelo propio con visión, alojado por nosotros.**
   - Nada sale de nuestra infraestructura.
   - Hace falta GPU o tiempos de respuesta de minutos.
   - Sigue sin explicar de dónde sale cada dato. Se mantiene un modelo.
4. **Elegida. Lector determinista:**
   - primero lo estructurado (XML y QR);
   - después el texto con sus posiciones, reglas y una plantilla por proveedor aprendida de lo que el usuario registra;
   - para los escaneados y las fotos, «ojos» locales: OCR clásico o un modelo de documento ligero (opción 3 en pequeño,
     dentro del mismo motor);
   - y una comprobación fiscal que decide qué se propone como bueno.
   - Sin LLM externo. El modelo local solo convierte la imagen en texto con posiciones: no decide qué es cada dato.

## Decisión

### 1. Dos piezas: los «ojos» sin lógica y la interpretación en TypeScript

- **Servicio `lectura-motor`** (contenedor propio sin estado, como Gotenberg; parte del código del micro):
  - Entra un PDF o una imagen.
  - Sale el **modelo de página**: palabras con su caja (página, x, y, ancho, alto) y su confianza, y el contenido de los
    QR que encuentre.
  - En los PDF con texto, las palabras con posición salen del propio PDF (`get_text("words")` de PyMuPDF): sin OCR.
  - En los escaneados y las fotos: página a imagen, enderezado y el motor de imagen (abajo).
  - El QR se busca siempre: se rasteriza la página y se lee con zxing.
  - **No guarda nada ni llama a nadie.** Solo lo llama el worker, con una clave de servicio y en la red privada.
  - No sabe qué es una factura.
- **Paquete `@activopro/lectura`** (TypeScript, sin acceso a la base; la interfaz `LectorDocumento` de ADR-0047):
  - Recibe el modelo de página (o el XML), el tipo de documento y las pistas de la empresa: NIF propio, plantillas y
    terceros conocidos.
  - Devuelve la `LecturaDocumento` tipada, con cada campo así: `{valor, origen, caja, comprobado}`.
  - Toda la lógica está aquí y **se prueba en `npm test`** con modelos de página en JSON, sin contenedor ni documentos
    reales en el repo.
- **Motor de imagen** (escaneados y fotos), **dentro del mismo contenedor**: no es un proyecto aparte.
  - Lo que hay que resolver no es «entender» la factura, sino convertir la imagen en palabras con su posición: igual que
    lo que ya trae un PDF con texto.
  - **Candidatos, todos de licencia abierta, en CPU y sin red:**
    - **PaddleOCR (PP-OCRv5)**: el del micro, OCR clásico con detección de texto. Es la base.
    - **Un modelo de documento ligero:** PaddleOCR-VL (0,9 B, 109 idiomas) o Granite-Docling (258 M, Apache 2.0).
      Además de leer, ordenan la página y reconocen tablas, que es lo que más falla en los escaneados y lo que hará falta
      en los albaranes.
    - Tesseract queda fuera: rinde bien en escaneos limpios, pero peor que PaddleOCR en fotos y diseños complejos, y no
      aporta nada que no tenga ya el micro.
  - **Se elige con una prueba**, antes de la fase 3, sobre facturas ficticias en el repo y escaneados reales solo en
    local. Se mide:
    - el acierto en importes, fechas, NIF y número;
    - el tiempo por página en el servidor que tengamos (sin GPU);
    - y la memoria.
  - La lectura va en segundo plano al llegar el documento. Unos segundos o un minuto por página es aceptable; si el
    modelo no cabe en esos tiempos, se queda PaddleOCR.
  - Si gana el modelo de documento, sigue siendo de riesgo mínimo para el Reglamento de IA, como cualquier OCR, y nada
    sale de nuestra infraestructura.

### 2. Orden de las fuentes (lo primero que da un valor comprobado manda)

1. **XML** (Facturae, UBL): exacto. Se lee en el paquete y no pasa por el motor.
2. **QR de la factura** (URL de cotejo de la AEAT): NIF del emisor, número, fecha y total, exactos. Lo que falta
   (desglose) lo completan las fuentes siguientes y tiene que cuadrar con ese total.
3. **Plantilla del proveedor** (punto 3): dónde ha estado cada dato en sus facturas anteriores.
4. **Reglas generales** (la experiencia de las regex del micro, pasadas a TypeScript y apoyadas en la posición): etiqueta
   y valor en la misma línea o debajo («Total», «Base imponible», «Nº factura»), cuadro de impuestos por columnas,
   formatos de fecha e importe españoles y de la UE, NIF con su letra de control.
- **Emisor:**
  - se toma del QR o del XML;
  - si no, de los NIF válidos del documento, quitando el de la empresa (que es el receptor);
  - si no, del remitente del correo cuando ya está asociado a un tercero.

### 3. Plantillas por proveedor, aprendidas al registrar y compartidas entre empresas

- **Al contabilizar un documento de la bandeja**, lo registrado es la verdad sin pedir nada más al usuario.
  - Por cada campo (número, fechas, bases, tipos, cuotas, total, retención) se busca su valor en el modelo de página, en
    todas sus formas escritas: `1.234,56`, `1234.56`, `01/02/2026`, `1-feb-2026`…
  - Si aparece en un solo sitio (o en uno junto a una etiqueta), se guarda el **ancla**: la etiqueta cercana, la posición
    respecto a ella y la zona de la página.
- **Lo que se aprende es del proveedor, no del cliente**, y sirve a todos:
  - dónde pone el NIF (aunque sea en vertical en el margen);
  - qué páginas no son de la factura (las tres de promociones de una operadora);
  - dónde están el número, las fechas, el cuadro de impuestos y el total.
  - Lo que nunca entra: importes, fechas, números de factura, el nombre o el NIF del receptor y cualquier texto que
    dependa del cliente.
- **Dos niveles:**
  - **De la empresa** (`lectura_plantilla`, con RLS): lo aprendido de sus propios documentos. Manda sobre la común.
  - **Común** (`lectura_plantilla_comun`, sin tenant):
    - va por la huella del NIF del emisor (SHA-256 del NIF normalizado), nunca por el NIF ni por el nombre;
    - guarda solo anclas: etiquetas del proveedor, posiciones, zonas y páginas que se ignoran;
    - no guarda de qué empresas sale. **Ninguna empresa puede saber qué otras compran a ese proveedor**: la común solo
      se usa por dentro al leer y no se enseña;
    - **un ancla pasa a la común cuando la confirman documentos de al menos dos empresas distintas.** Así solo entra lo
      que es del diseño del proveedor (un texto que se repite en receptores diferentes no puede ser del receptor), y un
      error de una empresa no estropea la lectura de las demás;
    - si un ancla común falla en varias empresas, se retira.
- Con un documento, la plantilla de la empresa queda «aprendida»; con dos que coinciden, «confirmada». Si un campo falla,
  se vuelve a aprender de ese documento. Si el proveedor cambia de diseño, la nueva sustituye a la vieja.
- **Lo leído de cada página no se guarda** (respuesta de José María: el lector es una ayuda; el usuario revisa, completa y
  acepta).
  - Las palabras y sus posiciones viven solo **mientras el documento está pendiente**, para aprender al registrarlo sin
    volver a leerlo.
  - Al registrarlo o descartarlo se borran.
  - Lo que queda es la lectura de cada campo (`documento_entrada.lectura`: valor, origen, caja, comprobado), que el
    visor usa para resaltar.

### 4. Comprobación fiscal: decide qué se propone como bueno

- Para cada línea del desglose: base × tipo = cuota (±0,01), con los tipos vigentes en la fecha (`tipo_impositivo`).
- Para el total: Σ bases + Σ cuotas + recargo − retención = total.
- NIF con control válido y distinto del de la empresa. Fecha de expedición no futura.
- Con QR, el total del QR tiene que coincidir.
- **Cada campo sale en uno de tres estados:**
  - **comprobado:** sale del XML o del QR, o cuadra en las comprobaciones;
  - **leído:** encontrado pero sin poder comprobarlo;
  - **vacío.**
  - Una lectura que no cuadra **nunca se propone como buena**: se rellena marcada y el aviso dice qué no cuadra.
- La propuesta contable sigue siendo de la plataforma (ADR-0047): del NIF sale el tercero y del tercero, cuenta, tipo,
  retención y forma de pago.

### 5. Medir desde el primer día

- **`lectura_correccion`** (ADR-0047): por documento y campo, lo leído, lo registrado, el origen (xml, qr, plantilla,
  regla) y si la página tenía texto o pasó por el OCR.
- La **consola de Enumbers** enseña el acierto por campo, por origen y por texto u OCR. Cada empresa ve el de sus
  proveedores en la bandeja.
- **Cuándo se revisa esta decisión:** a los tres meses o 500 documentos, con los números de la consola.
  - Si el acierto en escaneados queda por debajo de lo útil, se vuelve a la prueba del motor de imagen con los modelos de
    entonces: siempre alojados por nosotros, nunca un servicio externo.

### 6. Albaranes de proveedor (ADR-0047, fase 4)

- La plantilla aprende también la **tabla de líneas**: la fila de cabecera, el rango horizontal de cada columna y dónde
  acaba la tabla.
- Lote y caducidad por reglas: «Lote», «L:», «Cad.», fechas MM/AAAA.
- **`producto_proveedor`** (código del proveedor → producto de la empresa): se aprende al registrar la entrada de género.
  Un código desconocido se deja para que el usuario elija el producto, y la próxima vez ya se conoce.
- Comprobación: Σ cantidad × precio − descuentos = total del documento, cuando lo lleva.

### Fases

1. **XML y QR.**
   - Facturae y UBL en `@activopro/lectura`; el motor con texto, posiciones y QR (sin OCR todavía).
   - Reglas generales y comprobación fiscal.
   - La lectura al llegar el documento, el formulario relleno con su estado y el visor que resalta.
   - Las correcciones guardadas.
2. **Plantillas por proveedor** aprendidas al registrar (de la empresa y comunes), y las cifras de acierto en la
   consola.
3. **Escaneados y fotos:** la prueba del motor de imagen (PaddleOCR frente al modelo de documento ligero) y el que
   gane, en el mismo contenedor.
4. **Líneas y albaranes de proveedor** con `producto_proveedor`.

## Consecuencias

- **Nada sale de nuestra infraestructura** y no hay LLM externo:
  - ni transferencias internacionales ni encargados nuevos;
  - ni modelos que se retiran sin aviso: el que se use va en nuestra imagen, con su versión;
  - y lo único que entra en la definición del Reglamento de IA son los «ojos» de los escaneados (OCR o modelo de
    documento), de riesgo mínimo.
- **Cada dato dice de dónde sale** (XML, QR, plantilla o regla, con su caja en la página) y si cuadra. El usuario lo ve en
  el visor y el resultado se puede reproducir.
- **Mejora con el uso de todas las empresas:** lo que una aprende de Telefónica lo aprovechan las demás desde su primera
  factura, sin ver nada de la otra. Lo nuevo de verdad es solo el proveedor que nadie ha registrado todavía.
- **Precio que se paga:**
  - mantener las reglas y el motor;
  - la primera factura de un proveedor escaneada y sin QR puede quedar a medias;
  - y no hay «comprensión» de documentos raros (a mano, muy desordenados), que se registran como hoy.
- **ms-activopro-ocr sigue para GeneXus** tal cual, sin más inversión, y se retira (o se reformula) con la nueva
  estrategia.
- **Pendiente:** la contabilización sin revisión sigue fuera (ADR-0047). Si algún día se plantea, solo para lo
  comprobado y de plantillas confirmadas.

## Respuestas de José María (22/11/2026)

1. **Sin LLM**, sin salir de nuestra infraestructura; un modelo local y ligero sí, si ayuda a leer PDF e imágenes, sin
   abrir un proyecto aparte → motor de imagen dentro de `lectura-motor`, elegido con la prueba (punto 1).
2. **Lo aprendido, disponible para todos; los datos, no** → plantilla común por proveedor con solo anclas, sin decir de
   qué empresas sale, y confirmada por dos empresas distintas (punto 3).
3. **No guardar lo leído de cada página:** es una ayuda; el usuario revisa, completa y acepta → solo mientras está
   pendiente, para aprender al registrar (punto 3).
4. **Tesseract frente a PaddleOCR:** sin opinión formada → Tesseract fuera; la prueba es PaddleOCR frente a un modelo de
   documento ligero (punto 1).
5. **El micro actual no preocupa:** se reformula o se retira con la nueva estrategia; no se invierte en él.

Aceptado por José María el 22/11/2026, con estos ajustes.

## Nota de implementación (fase 1, 22/11/2026)

- **La fase 1 no necesita el contenedor `lectura-motor`.** El texto con posiciones sale de pdf.js (Apache-2.0, el mismo del visor) y
  el QR de la página pintada con @napi-rs/canvas y zxing-wasm (MIT), dentro del worker.
- Así se evita también PyMuPDF, que usa el micro: su licencia es AGPL-3.0, que en un servicio en la nube obliga a publicar el
  código.
- El contenedor llega con la fase 3 (motor de imagen) y solo para los escaneados y las fotos. La interpretación sigue en
  `@activopro/lectura`.

## Origen

Conversación del 22/11/2026 con José María sobre ms-activopro-ocr («me planteo si en la nueva plataforma es necesario o con
reconocimiento de OCR, otras tecnologías y aprendizaje, podemos evitarlo… si conseguimos que sea realmente efectiva podría
llevarnos a ampliar la lectura de entrada de productos en el almacén») y las cifras del monitor (87 documentos:
`regex_fallback` 55, `regex_sin_llm` 32).
