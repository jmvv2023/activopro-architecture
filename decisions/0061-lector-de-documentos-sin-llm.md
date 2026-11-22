---
id: 0061
title: Lector de documentos propio sin LLM — datos estructurados primero, texto con posiciones, plantillas por proveedor aprendidas de lo registrado y comprobación fiscal
status: proposed
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
4. **Elegida (propuesta). Lector determinista:**
   - primero lo estructurado (XML y QR);
   - después el texto con sus posiciones, reglas y una plantilla por proveedor aprendida de lo que el usuario registra;
   - OCR local solo para los escaneados y las fotos;
   - y una comprobación fiscal que decide qué se propone como bueno.
   - Sin LLM.

## Decisión (propuesta)

### 1. Dos piezas: los «ojos» sin lógica y la interpretación en TypeScript

- **Servicio `lectura-motor`** (contenedor propio sin estado, como Gotenberg; parte del código del micro):
  - Entra un PDF o una imagen.
  - Sale el **modelo de página**: palabras con su caja (página, x, y, ancho, alto) y su confianza, y el contenido de los
    QR que encuentre.
  - En los PDF con texto, las palabras con posición salen del propio PDF (`get_text("words")` de PyMuPDF): sin OCR.
  - En los escaneados y las fotos: página a imagen, enderezado y OCR local.
  - El QR se busca siempre: se rasteriza la página y se lee con zxing.
  - **No guarda nada ni llama a nadie.** Solo lo llama el worker, con una clave de servicio y en la red privada.
  - No sabe qué es una factura.
- **Paquete `@activopro/lectura`** (TypeScript, sin acceso a la base; la interfaz `LectorDocumento` de ADR-0047):
  - Recibe el modelo de página (o el XML), el tipo de documento y las pistas de la empresa: NIF propio, plantillas y
    terceros conocidos.
  - Devuelve la `LecturaDocumento` tipada, con cada campo así: `{valor, origen, caja, comprobado}`.
  - Toda la lógica está aquí y **se prueba en `npm test`** con modelos de página en JSON, sin contenedor ni documentos
    reales en el repo.
- **Motor de OCR:** se elige con una prueba antes de implementar: Tesseract 5 o PaddleOCR (el del micro), sobre
  facturas ficticias en el repo y escaneados reales solo en local. Gana el que acierte más palabras de importe y fecha.

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

### 3. Plantillas por proveedor, aprendidas al registrar

- **Al contabilizar un documento de la bandeja**, lo registrado es la verdad sin pedir nada más al usuario.
  - Por cada campo (número, fechas, bases, tipos, cuotas, total, retención) se busca su valor en el modelo de página, en
    todas sus formas escritas: `1.234,56`, `1234.56`, `01/02/2026`, `1-feb-2026`…
  - Si aparece en un solo sitio (o en uno junto a una etiqueta), se guarda el **ancla**: la etiqueta cercana, la posición
    respecto a ella y la zona de la página.
- **`lectura_plantilla`**, por empresa y tercero:
  - versión, anclas por campo, aciertos y fallos;
  - la fecha del último documento.
  - Con un documento, la plantilla queda «aprendida»; con dos que coinciden, «confirmada».
  - Si un campo de la plantilla falla, se vuelve a aprender de ese documento. Si el proveedor cambia de diseño, la
    plantilla nueva sustituye a la vieja.
- **Plantillas solo dentro de cada empresa** (con RLS). Compartir el diseño de un proveedor entre clientes enseñaría a
  quién compra cada uno. Queda como posible mejora para decidir aparte.
- **El modelo de página se guarda con el documento** (`documento_entrada`, misma vida que el original).
  - Así se aprende al registrar sin volver a pasar el OCR.
  - Y el visor resalta de dónde sale cada dato.

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
- **Cuándo se revisa esta decisión:** a los tres meses o 500 documentos.
  - Si el acierto en escaneados queda por debajo de lo útil, se estudia un modelo **alojado por nosotros**, nunca un
    servicio externo.
  - Se decide con los números de la consola.

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
2. **Plantillas por proveedor** aprendidas al registrar, y las cifras de acierto en la consola.
3. **OCR local** en el motor para escaneados y fotos, con el motor elegido en la prueba.
4. **Líneas y albaranes de proveedor** con `producto_proveedor`.

## Consecuencias

- **Nada sale de nuestra infraestructura** y no hay LLM:
  - ni transferencias internacionales ni encargados nuevos;
  - ni modelos que se retiran;
  - y el aviso de transparencia de IA solo podría tocar al OCR, que es de riesgo mínimo.
- **Cada dato dice de dónde sale** (XML, QR, plantilla o regla, con su caja en la página) y si cuadra. El usuario lo ve en
  el visor y el resultado se puede reproducir.
- **Mejora con el uso de cada empresa:** a partir de la segunda factura de un proveedor, lo normal es que la lea su
  plantilla. Lo primero de cada proveedor es lo que más cuesta.
- **Precio que se paga:**
  - mantener las reglas y el motor;
  - la primera factura de un proveedor escaneada y sin QR puede quedar a medias;
  - y no hay «comprensión» de documentos raros (a mano, muy desordenados), que se registran como hoy.
- **ms-activopro-ocr sigue para GeneXus** sin cambios de contrato. Se recomienda quitar ahí DeepSeek y los proveedores sin
  contrato, o apagar el LLM, que según el monitor no completa nada. Va en un PR aparte en su repo.
- **Pendiente:** la contabilización sin revisión sigue fuera (ADR-0047). Si algún día se plantea, solo para lo
  comprobado y de plantillas confirmadas.

## Por decidir (José María)

1. **Sin LLM en la plataforma**, revisándolo solo con las cifras del punto 5, y en ese caso únicamente un modelo
   alojado por nosotros.
2. **Plantillas solo por empresa** (sin compartirlas entre clientes).
3. **El modelo de página se guarda con el documento**, con la misma vida que el original.
4. **La prueba de Tesseract frente a PaddleOCR** antes de la fase 3.
5. **En el micro actual:** quitar DeepSeek o apagar el LLM.

## Origen

Conversación del 22/11/2026 con José María sobre ms-activopro-ocr («me planteo si en la nueva plataforma es necesario o con
reconocimiento de OCR, otras tecnologías y aprendizaje, podemos evitarlo… si conseguimos que sea realmente efectiva podría
llevarnos a ampliar la lectura de entrada de productos en el almacén») y las cifras del monitor (87 documentos:
`regex_fallback` 55, `regex_sin_llm` 32).
