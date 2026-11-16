---
id: 0046
title: VeriFactu, documentos PDF y correo en la plataforma — registro en la base, envío por un worker, plantillas en el monorepo y renderizador aparte
status: proposed
date: 2026-11-16
services: [core, verifactu, docgenerator]
supersedes: null
superseded_by: null
---

## Contexto

La factura emitida de la plataforma (ADR-0030, ADR-0031, ADR-0036) ya tiene número correlativo, fecha del sistema y es
inmutable. Para usarla de verdad le falta:

- el registro VeriFactu (huella, QR, envío a la AEAT);
- el PDF;
- el envío por correo.

La plataforma necesitará además muchos más PDF: albaranes, presupuestos, remesas, recibos y todos los informes (diario,
mayor, balances, modelos).

### Lo que hay hoy, fuera de la plataforma

**ms-activopro-verifactu (`jmvv2023/ms-activopro-verifactu`, 2.0.0, unas 2.300 líneas, Fastify + TypeScript).**

- Partes independientes de GeneXus (unas 900 líneas, con tests y el vector real SIM7):
  - huella;
  - XML del registro;
  - QR;
  - envío SOAP con certificado de cliente;
  - lectura de la respuesta;
  - control de flujo de la AEAT (6.4.4.1).
- Partes atadas a GeneXus:
  - `routes/registros.ts` (915 líneas);
  - cadena en `verifactu_registro` de cada schema de MySQL (`USE schema`, `GET_LOCK` por NIF);
  - respuesta en XML;
  - parser ISO-8859-1;
  - certificado en cada petición, guardado 24 h solo en memoria;
  - control de flujo en memoria.
- Existe como servicio porque GeneXus no podía hacerlo en su transacción (`domain/verifactu-evolucion.md`). Por eso
  GeneXus llama después del commit y solo sabe reenviar: puede haber factura emitida sin registro.
- Su otro objetivo era **aislar el SIF** para que evolucione solo ante cambios regulatorios.

**docgenerator (`jmvv2023/docgenerator`, `pdf.activopro.net`).**

- Funciona: Handlebars, Puppeteer con un navegador reutilizado y auto-reposición, cola `p-queue` con contrapresión,
  `/health`, `/ready` y monitor. Tiene tres estilos de factura y uno de albarán y de presupuesto.
- Limitaciones:
  - el contrato es el JSON plano de GeneXus, sin tipos;
  - las plantillas viven en el servicio;
  - tiene un i18n propio, distinto de `@activopro/i18n`;
  - no tiene tests;
  - no tiene autenticación (CORS abierto, solo la restricción por IP de Nginx);
  - `node_modules` está versionado (8.560 ficheros).
- Cada informe nuevo de la plataforma obligaría a tocar otro repositorio, con datos sin tipos y textos duplicados.

**ADR-0013 §5** deja la generación de PDF y VeriFactu como servicios autónomos, "porque no comparten transacciones con el
core". En la plataforma el registro VeriFactu **sí** comparte la transacción de la emisión. Este ADR revisa ese punto
para estos dos servicios.

### Plazos

VeriFactu obliga desde el 1 de enero de 2027 a los contribuyentes del Impuesto sobre Sociedades y desde el 1 de julio
de 2027 al resto (RDL 15/2025). El 5 de octubre de 2026, Hacienda anunció su intención de aplazarlo a octubre de 2028,
pero no está en el BOE: se planifica con 2027.

## Opciones consideradas

### VeriFactu

1. **Reutilizar el micro tal cual.** No vale: su cadena vive en MySQL por schema y la plataforma no tiene MySQL.
2. **Micro con dos almacenes (MySQL para GeneXus, Postgres para la plataforma).**
   - A favor: un solo SIF.
   - En contra: el registro queda fuera de la transacción de la emisión, como hoy en GeneXus. Además, el micro
     necesitaría acceso a la base de la plataforma o un almacén propio.
3. **Elegida. En la plataforma, con el SIF aislado en paquetes.**
   - El registro se crea en la transacción de la emisión.
   - El envío lo hace un worker.
   - Lo regulatorio vive en paquetes sin acceso a la base, versionados y con sus tests.

### Renderizador de PDF

1. **Gotenberg.**
   - Contenedor abierto (MIT) y mantenido, con Chromium, cola, reintentos y health.
   - Hace PDF/A y PDF/UA y une PDF.
   - No hay que mantener el pool de Chrome.
2. **docgenerator reducido a `POST /render`.**
   - Ya está en producción.
   - El pool, la autenticación y la limpieza los mantenemos nosotros.
3. **@react-pdf/renderer.**
   - Sin navegador, se ejecuta dentro de la API.
   - Solo un subconjunto de CSS. Los informes largos y las tablas complejas cuestan más.
   - La vista previa en pantalla no sería el mismo HTML.

### Correo

1. Proveedor transaccional (Postmark, Resend, SES…): de pago o con un tramo gratuito limitado.
2. **Elegida. SMTP de IONOS**, con las cuentas que ya tiene Enumbers, detrás de una interfaz que permita cambiar de
   proveedor sin tocar el resto.

## Decisión

### 1. VeriFactu: el SIF aislado en paquetes, el registro en la base y el envío en un worker

**Paquetes sin acceso a la base**, como `@activopro/fiscal`, `bancos` o `sepa`:

- `packages/aeat` (`@activopro/aeat`):
  - cliente SOAP con certificado de cliente (mTLS), con los entornos `pre` y `pro` por configuración;
  - control de flujo genérico;
  - lectura de errores SOAP.
  - Es el transporte que reutilizará el **SII** (clientes que nunca pasarán a VeriFactu) y cualquier otro envío a
    la AEAT.
- `packages/verifactu` (`@activopro/verifactu`):
  - entrada: un *registro de facturación* canónico, no las tablas de factura;
  - salida: la huella, el XML de alta (y de anulación cuando se haga), el QR y la lectura de la respuesta.
  - Se porta del micro con sus tests: SIM7, rectificativas `I` con `FacturasRectificadas` y `FechaOperacion` (#46,
    #68), F2/R5 sin destinatario (1190), alta por rechazo, duplicados.
  - **Lleva la versión del SIF** (SemVer en su `package.json`, ADR-0007) y su `CHANGELOG.md`.

Así, un cambio regulatorio toca el paquete y la función que traduce la factura a registro, sube la versión y pasa sus
tests. No toca la facturación.

**El registro, en la base, en la misma transacción que emite.**

- `registro_facturacion` (por empresa y NIF emisor):
  - factura;
  - tipo de registro (alta; anulación, para más adelante);
  - campos de la huella;
  - huella y eslabón anterior (huella, serie y número, fecha);
  - `FechaHoraHusoGenRegistro`;
  - versión del SIF;
  - estado: `pendiente` → `aceptado` / `aceptado_con_errores` / `rechazado`;
  - CSV, error, intentos y envío;
  - XML enviado.
- Se crea por trigger cuando `app.emitir_factura` asigna el número, y vale también para la emisión en bloque y las
  recurrencias:
  - la cadena del NIF se serializa con `pg_advisory_xact_lock`;
  - la huella se calcula con `pgcrypto`.
  - Un test exige que la base y `@activopro/verifactu` den la misma huella para SIM7 y para casos propios.
- **Inmutable:**
  - solo cambian el estado y la respuesta;
  - un rechazado sigue siendo eslabón;
  - la subsanación es un registro nuevo al final;
  - nunca se reescribe la cadena hacia atrás.
- Solo la emitida **de la plataforma** crea registro. Las recibidas, las importadas de otro programa y los resúmenes de
  tickets del cierre de caja (los emite el TPV) no.
- La aplicación solo lee. Escriben las funciones de emisión y el worker.

**Envío.**

- El worker (punto 4) toma los pendientes por NIF.
- Respeta `TiempoEsperaEnvio` y el máximo de 1.000 registros. El control de flujo se guarda en una tabla
  (`envio_aeat`: lote, respuesta, espera, próximo envío), no en memoria: sobrevive a un reinicio y a varias instancias.
- Lo mismo que el micro: idempotente, la detección de duplicados por la estructura de la respuesta y la alta por
  rechazo cuando el registro cambia.

**Certificado.**

- El de cada cliente, cifrado en **Supabase Vault**.
- `certificado_aeat` guarda solo metadatos: titular, NIF, emisor, validez y la referencia al secreto.
- Lo sube el administrador (`fiscal.configurar`). La API comprueba la contraseña, que el NIF es el de la empresa y la
  caducidad; avisa antes de que caduque.
- Solo el rol del worker lee el secreto, con una función `security definer`. `app_user` nunca. Se descifra en memoria
  para el envío y no va a logs.
- En local y en los tests, sin Vault, la misma función con una implementación de prueba.

**Pantalla.**

- En la factura: estado VeriFactu, CSV, QR y el motivo del rechazo con lo que hay que hacer.
- En la portada fiscal: pendientes y rechazados.
- Sin certificado vigente, la factura se emite igual (el registro queda pendiente) con un aviso.

### 2. Identidad del SIF y migración de la cadena

- La plataforma es una **versión nueva del SIF ActivoPro**: mismo sistema y una nueva versión mayor (la del micro es la
  2.x). La declaración responsable (`activopro.net/responsable`) se actualiza con ella (ADR-0007).
- **Semilla:** al migrar una empresa, el ETL carga el último eslabón que la AEAT tiene de su NIF como registro de
  origen `semilla` (aceptado, nunca se envía). El primer registro de la plataforma encadena con él. El origen:
  - `verifactu_registro`, si emitía por el micro;
  - si venía del flujo nativo, los datos **tal como se enviaron** de `FacHashData`, con la fecha que se usó
    (`FacMod`), como en `ms-activopro-verifactu/docs/despliegue.md` §4.2.
- **Histórico:** las facturas importadas traen su huella, CSV y QR, para reimprimirlas iguales.
- **Corte:** un NIF emite VeriFactu en un único sistema. El día de la migración se desactiva en GeneXus (`MSVERACT` y la
  emisión) antes de sembrar. Dos sistemas encadenando el mismo NIF bifurcarían la cadena.
- El micro se congela para GeneXus (solo correcciones) y se retira con GeneXus.

### 3. Documentos PDF: plantillas en el monorepo y Gotenberg

**Plantillas en `packages/documentos` (`@activopro/documentos`).**

- Son componentes React renderizados a HTML en el servidor (`renderToStaticMarkup`).
- Tipados con `@activopro/contrato`, con los textos de `@activopro/i18n` en el idioma del tercero (documentos) o del
  usuario (informes) y los formatos de `ui/formato`.
- El HTML es **autocontenido** (fuentes, logo y QR embebidos): el renderizador no sale a la red.
- Paginación con CSS de impresión (`@page`, cabeceras de tabla que se repiten) y pie de Chromium con «página x de y».
- Tests de las plantillas con datos de la demo (HTML y número de páginas).

**Diseño de la empresa.**

- `empresa_estilo_documento`:
  - logo en Storage;
  - color principal y de acento;
  - tipografía de una lista cerrada;
  - diseño de una lista (clásico, moderno, minimal, como hoy);
  - pie de una a tres líneas y textos legales por idioma;
  - campos que se muestran.
- Los documentos de venta lo usan entero. Los informes, un diseño sobrio común con el logo y el color.
- No se permite HTML libre por cliente: es producto, no a medida (seguridad y mantenimiento).
- La pantalla de estilo enseña la **vista previa en vivo con el mismo HTML** en un iframe. El PDF es exactamente lo que
  se ve.

**Renderizador: Gotenberg.**

- Contenedor junto a la API, solo en la red privada: sin puerto público y con la navegación externa denegada.
- La API le manda el HTML y recibe el PDF.
- Tiempos y concurrencia por configuración. PDF/A cuando haga falta archivar.
- Si un día no sirve, la alternativa es el motor del docgenerator detrás de la misma interfaz `renderizarPdf(html,
  opciones)`.
- El docgenerator sigue sirviendo a GeneXus hasta su retirada.

**Almacenamiento.**

- Supabase Storage, en un bucket privado por tenant (`tenant/empresa/...`): logos y la **copia del PDF enviado**.
- La factura emitida se puede regenerar (VeriFactu garantiza sus datos), pero lo enviado se guarda tal cual: un cambio
  de plantilla no debe cambiar lo que recibió el cliente.

### 4. Trabajos en segundo plano: cola en Postgres y worker

- Tabla `trabajo`: tipo, tenant, empresa, datos, estado, intentos, disponible desde y error.
- Se toma con `for update skip locked`. Es portable a la base local de los tests, cosa que pgmq no garantiza.
- `apps/worker`: misma imagen que la API con otro comando y un rol propio.
- Fija el tenant por trabajo como la API (`app.tenant_id` por transacción).
- Atiende:
  - el envío a la AEAT;
  - el correo;
  - los PDF en bloque (emitir facturas, recurrencias);
  - después, lo que otros módulos necesiten.
- Reintentos con espera creciente y un estado visible en la pantalla de quien lo lanzó.

### 5. Correo: SMTP de IONOS detrás de una interfaz

- Una interfaz `Correo` con implementación SMTP (nodemailer) sobre un buzón de IONOS del dominio de ActivoPro.
- **Remitente y respuesta:** el nombre comercial de la empresa como nombre del remitente y el email de la empresa en
  `Reply-To`. No se envía desde el dominio del cliente: no tenemos su DKIM.
- **Límite de IONOS (Mail Basic / Business):** 500 correos por hora y buzón, menos los primeros 30 días del contrato.
  El worker los dosifica: un lote mensual de facturas sale en minutos u horas, nunca se pierde.
- SPF, DKIM y DMARC del dominio configurados.
- Los rebotes van a un buzón propio, que se leerá por IMAP en una fase posterior.
- Si el volumen crece, se cambia de implementación por configuración.
- El mismo SMTP sirve para Supabase Auth (invitaciones y contraseñas, H-032).

**Registro de envíos.**

- `envio_documento`: documento, destinatarios, asunto, idioma, estado (`pendiente`, `enviado`, `error`, `rebotado`),
  identificador del mensaje, usuario y ruta del PDF enviado.
- Destinatarios propuestos: los contactos del tercero marcados para recibir facturas, si no el email de la ficha.
- Texto del mensaje por idioma con variables (número, importe, vencimiento), editable por la empresa.

### Fases

1. Cola y worker; certificado en Vault con su pantalla.
2. VeriFactu:
   - paquetes `aeat` y `verifactu`;
   - registro en la base;
   - semilla en el ETL;
   - envío a preproducción;
   - estado en la factura y la portada fiscal.
3. Documentos:
   - paquete y Gotenberg;
   - estilo de la empresa con vista previa;
   - factura con QR, albarán y presupuesto.
4. Correo: envío de la factura y registro de envíos.
5. Informes sobre el mismo motor (balances y PyG con ADR-0017, diario, mayor, modelos).

## Consecuencias

- **ADR-0013 §5 queda modificado** para VeriFactu y la generación de PDF:
  - el SIF se aísla en paquetes y en un worker, no en un servicio;
  - el PDF se reparte entre plantillas en la plataforma y un renderizador sin estado.
  - Siguen autónomos el OCR, las alertas, la importación y la factura electrónica.
- La emisión y su registro VeriFactu son atómicos: desaparece el caso de factura emitida sin registro.
- **Durante la convivencia hay dos implementaciones del SIF:** el micro, congelado, para GeneXus, y los paquetes, para
  la plataforma. Coste acotado: hoy solo mconta0048 usa VeriFactu en producción.
- El backend necesita su plataforma de despliegue (pendiente desde ADR-0025), ahora con tres contenedores: API, worker
  y Gotenberg.
- **Nunca se envía nada a la AEAT de producción desde una sesión autónoma:** `pre` siempre, el envío simulado en los
  tests y nunca certificados reales en el repositorio.
- **Pendiente de comprobar:**
  - en la especificación de la AEAT, que la cadena de un NIF continúa con la semilla al cambiar de versión del SIF, y
    los campos de `SistemaInformatico` que cambian (versión, instalación);
  - con IONOS, la configuración DKIM del dominio.
- El docgenerator queda solo para GeneXus. Antes de cualquier otro cambio en él, sacar `node_modules` de Git.

## Origen

Conversación con José María del 16/11/2026:

- VeriFactu en la plataforma, como módulo mantenible y reutilizable para otros envíos a la AEAT (SII);
- certificado de cada cliente cifrado en Supabase Vault;
- la plataforma es una versión nueva del SIF, con la semilla de la cadena al migrar;
- el renderizador, a criterio técnico: los documentos llevan el logo, el diseño y el color del cliente;
- el correo, con las cuentas de IONOS.
