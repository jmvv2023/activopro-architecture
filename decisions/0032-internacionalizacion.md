---
id: 0032
title: Internacionalización — idioma por usuario e idioma del tercero, catálogo único y mensajes con código
status: proposed
date: 2026-11-08
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

ActivoPro se distribuye en **seis idiomas**: castellano, catalán, gallego, francés, portugués e inglés. La plataforma nueva no tiene internacionalización. Hoy todos los textos están en castellano, en tres sitios:

- **Las pantallas.** Unas 21 pantallas de los módulos nuevos (Contabilidad, Fiscal, Facturación) llevan los textos escritos en el código, y antd y dayjs están fijados en `es`.
- **La base de datos.** Unos 400 `raise exception` y 85 avisos (`{codigo, texto}`) con el texto ya redactado y las fechas formateadas (`to_char(..., 'DD/MM/YYYY')`). La API los devuelve tal cual.
- **Las normas centrales.** Grupos del PGC, clases de operación, tipos impositivos y las etiquetas de casillas de `@activopro/fiscal/etiquetas`.

En GeneXus:
- El idioma va **por usuario** (sesión `IDI`, tabla `idiomas` con códigos numéricos; `'1'` = castellano).
- Cada **tercero** tiene su idioma (`GetIdiTer`): sus facturas y las comunicaciones le llegan en ese idioma.
- Algunos datos del usuario se guardan por idioma: nombres y textos de las plantillas (`asidefinicionidioma`, `asideflintexto`, `asidefcontrolestexto`) y conceptos de informes (`definfconallidi`).

Cuanto más tarde se prepare la arquitectura, más pantallas y mensajes habrá que rehacer.

## Opciones consideradas

**Mensajes de la base de datos**
1. **La base traduce.** Una tabla `mensaje (codigo, idioma, texto)` y el idioma por transacción. Funciona para cualquier cliente (API, ETL, psql). Pero parte los textos en dos catálogos (front y base), y cambiar un texto pasa a ser una migración.
2. **La base devuelve código y datos; traduce quien muestra.** El texto en castellano queda como respaldo para logs y psql. Hay un solo catálogo, versionado en Git y con tests de que está completo.

**Datos que escribe el usuario en varios idiomas**
1. **Una tabla de textos por entidad** (`<entidad>_texto (id, idioma, texto)`), como GeneXus. Muchas tablas y uniones.
2. **Una columna `jsonb` de textos** (`{"es": "...", "ca": "..."}`) en la fila. Va con su RLS y su auditoría, y se resuelve con una sola función con respaldo.

## Decisión

**1. Idiomas.**
- Códigos BCP 47: `es`, `ca`, `gl`, `fr`, `pt`, `en`.
- Norma central `idioma` (código, nombre propio, locale de formato: `es-ES`, `ca-ES`, `gl-ES`, `fr-FR`, `pt-PT`, `en-GB`).
- El castellano es el idioma fuente y el de respaldo.
- El ETL traduce los códigos numéricos de GeneXus.

**2. Dos idiomas distintos.**
- **Idioma del usuario** (`usuario.idioma`). Lo elige el usuario y decide las pantallas, los mensajes, los formatos y los informes que consulta. En el primer acceso se toma el del navegador si es uno de los seis; si no, castellano. La empresa no tiene idioma.
- **Idioma del tercero** (`tercero.idioma`). Decide los documentos y las comunicaciones que se le envían: factura en PDF, correos y recordatorios. No depende de quién los emita.

**3. Un catálogo único: paquete `@activopro/i18n`.**
- Ficheros JSON por idioma y por módulo (`comun`, `contabilidad`, `fiscal`, `facturacion`…), con claves semánticas (`facturacion.serie.no_vigente`) y mensajes ICU (plurales, fechas e importes como parámetros).
- Lo usan:
  - el front, con `react-i18next` y el `i18nProvider` de Refine;
  - la API, para lo que genera ella;
  - los generadores de documentos, en el idioma del tercero;
  - `@activopro/fiscal`, para las etiquetas de casillas.
- Los nombres de las normas centrales se traducen en el catálogo por su código (`pgc.grupo.43`, `operacion.intracomunitaria`). En la base queda el nombre en castellano.
- Tests:
  - toda clave existe en castellano, y si falta es un error;
  - una clave que falta en otro idioma cae al castellano y aparece en un informe de pendientes;
  - todo código que lanza la base tiene clave.

**4. Mensajes de la base con código (opción 2).**
- Errores con `raise exception '<texto en castellano>' using errcode = …, detail = jsonb_build_object('codigo', 'SERIE_NO_VIGENTE', 'params', …)::text`, mediante un helper `app.error(codigo, params, errcode, texto)`.
- Avisos `{codigo, params, texto}`.
- Fechas e importes van en los parámetros sin formatear (ISO, numérico). Los formatea quien muestra el mensaje, en el locale del usuario.
- La API devuelve `{codigo, params, mensaje}`, y el front traduce por el código. Si no hay clave, muestra `mensaje`.

**5. Datos del usuario en varios idiomas (opción 2).**
- Columna `textos jsonb` con claves de `idioma` (lo comprueba un check), resuelta con `app.texto(textos, idioma)`. El orden de respaldo es: idioma pedido, castellano, el primero que haya.
- Solo donde el texto lo leen personas de idiomas distintos:
  - textos de plantillas que usan varios usuarios;
  - pies y condiciones de factura (`FACPIEEX`, `FACPIEUE`);
  - conceptos de informes.
- Lo que el usuario escribe en un documento concreto (concepto de un asiento, descripción de una línea) no se traduce: sale como lo escribió.

**6. Formatos.**
- Fechas, números e importes con `Intl` en el locale del usuario. `ui/formato.ts` deja de fijar `es-ES`.
- antd y dayjs cargan el locale del usuario.

**7. Ficheros oficiales.** Los ficheros de la AEAT y la ATC (303, 390, 347…) no se traducen: su diseño fija los textos. En pantalla, las etiquetas de casillas sí se traducen. El castellano oficial queda disponible como referencia (tooltip).

**8. Regla desde ahora.**
- Ninguna pantalla nueva con textos escritos en el código. ESLint lo exige en los módulos nuevos con `i18next/no-literal-string`, y el `LEGADO` queda fuera.
- Ninguna función nueva con un mensaje sin código.

## Plan de trabajo

1. **Base.**
   - Norma `idioma`, `usuario.idioma` y `tercero.idioma`.
   - Paquete `@activopro/i18n` con `es` completo.
   - `i18nProvider`, locales de antd y dayjs, y selector de idioma en el menú de usuario.
   - `app.error` y el formato de error de la API.
   - Regla de ESLint y tests del catálogo.
2. **Módulo a módulo:** Facturación, Contabilidad y Fiscal. Cada uno pasa sus pantallas a claves y sus funciones a códigos en el mismo PR, con tests.
3. **Traducciones:** catalán primero, después gallego, francés, portugués e inglés. Las redacta Claude a partir del castellano y las revisa una persona nativa antes de publicarlas.
4. **Documentos para terceros** en su idioma, cuando lleguen el PDF de la factura (módulo de productos, ADR-0031 punto 6) y las comunicaciones.

## Consecuencias

- El castellano deja de estar escrito en el código: los textos se cambian en el catálogo, sin tocar pantallas ni migraciones.
- La base sigue siendo legible en psql y en los logs (el texto en castellano queda como respaldo).
- Se reescriben, por módulos, unos 400 mensajes de error y 85 avisos, y los textos de 21 pantallas. Las pantallas antiguas (`LEGADO`) no se traducen: se sustituyen.
- Las plantillas de asiento (ADR-0033) nacen con `textos jsonb` y mensajes de control por idioma.

## Pendiente

- Idioma por defecto de un tercero sin idioma (propuesta: castellano) y si el alta de tercero lo propone según el país.
- Quién revisa cada idioma antes de publicarlo.

## Origen

Conversación del 08/11/2026 con José María al plantear las plantillas de asiento. Pidió preparar la arquitectura para varios idiomas y confirmó los seis idiomas, el idioma por usuario (no por empresa) y el idioma del tercero para sus facturas y comunicaciones.
