---
id: 0023
title: Operaciones con terceros (347 y 415) desde los apuntes, con terceros en la plataforma y declaración por versiones
status: accepted
date: 2026-11-05
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

**GeneXus** (`WPmod_347`, `Crea_347`, `Mod_347`) genera el 347 (AEAT) y el 415 (ATC) con el mismo programa.

**Origen de los datos.** Recorre los asientos del año natural y decide por diario y por línea:

| Clave | Qué recoge | Importe |
|---|---|---|
| B (entregas) | facturas emitidas (diarios 3, 15, 22, 51; 35 y 36 sin 349; 26 y 48 solo servicios) | línea 1, el cliente |
| A (adquisiciones) | facturas recibidas (diarios 4, 5, 11, 20, 21, 30, 40, 42, 43, 45, 47) | línea 2, el proveedor |
| A (adquisiciones) | diarios 14 y 50 | línea 1 |
| A o B | asientos «varios» (diario 8) | según marcas del concepto (`ConAsiFEN`, `ConAsiFRN`) |

- **Tercero:** el NIF, nombre, país y provincia salen de la ficha de cliente, proveedor, acreedor o banco de la cuenta (`tctareferencia` C/P/A/B). Sin NIF, el tercero entra como `** cuenta`.
- **Ajustes del 347:**
  - resta los suplidos;
  - excluye las facturas con retención de IRPF, salvo la parte sin retención;
  - excluye los arrendamientos con retención (ARI/SRI).
- **Ajustes del 415:** solo los diarios canarios, e incluye las operaciones con retención y los arrendamientos.

**Acumulación y presentación:**
- acumula por NIF, clave y trimestre en `tmp347`, que el usuario puede editar;
- umbral `limdeclara` 347D (3.005,06 €) en valor absoluto;
- fichero de 500 posiciones.

**Huecos de GeneXus:**
- los cobros en metálico (> 6.000 €) siempre a 0;
- la hoja de inmuebles (arrendamientos de locales) está desactivada;
- no hay marcas de inversión del sujeto pasivo ni de criterio de caja por tercero.

**La plataforma** tiene los apuntes, los registros de impuesto (con operación, clase y retenciones) y las cuentas, pero no los terceros: ni ficha, ni NIF, ni país o provincia.

### Lo comprobado con la documentación y los datos (2026-11-05)

**Diseño de registro del 347 (AEAT, «ejercicio 2025 y siguientes», aportado por José María).** Registros de 500 posiciones, ISO-8859-1, de tres tipos:
- **Tipo 1 (declarante):** totales de declarados y de inmuebles, complementaria o sustitutiva con justificante, y representante legal.
- **Tipo 2 (declarado):**
  - NIF, nombre, provincia (99 para no residentes) y país;
  - clave A–G e importe anual con signo;
  - marca de seguro y de arrendamiento de local;
  - metálico y transmisiones de inmuebles;
  - desglose trimestral;
  - NIF de operador comunitario, marca de ISP (solo el destinatario) y marca de depósito distinto del aduanero;
  - importe por criterio de caja y convocatoria BDNS (clave E).
- **Tipo 2 (inmueble):** NIF del arrendatario, importe, situación, referencia catastral y dirección.

**415 (ATC).**
- **Contenido:**
  - es el equivalente canario del 347, pero solo con las operaciones de IGIC; el 347 recoge también las de IGIC, así que una empresa canaria presenta los dos;
  - incluye operaciones con retención y arrendamientos (igual que GeneXus);
  - excluye importaciones y bienes de inversión (van al 416).
- **Umbrales:** 3.005,06 €, y 300,51 € en los casos especiales.
- **Obligados:** no están obligados quienes llevan los libros por el SII.
- **Presentación:** por la sede de la ATC. Existe un diseño lógico para soporte informático (Resolución publicada en el BOC n.º 41 de 2015, anexo II), pero no se ha podido descargar.

**Base de comparación en GeneXus (`tmp347`):**

| Cliente | 347 | 415 |
|---|---|---|
| mconta0037 | 2025: 363 filas | — |
| mconta0124 | 2024: 137 filas | — |
| mconta0013 | 2025 | 2025 |
| mconta0032 | 2025 | 2025 |
| mconta0086 | 2025 | 2025 |

Los tres canarios tienen las dos declaraciones, y en el 415 hay más claves A que en el 347 (retenciones y arrendamientos). Hay filas con NIF ficticio y filas sin importe.

## Opciones consideradas

**Terceros**
1. **Entidad `tercero` por empresa enlazada a la cuenta**, con NIF, nombre, país ISO-2, provincia, correo y tipo: cliente, proveedor, acreedor o banco. La cuenta del tercero (430…, 400…, 410…) apunta a su tercero. La usarán también facturación y cartera; aquí entra lo mínimo.
2. **NIF y nombre directamente en la cuenta.** Más simple, pero mezcla plan contable con datos de tercero y no sirve a los módulos siguientes.

**Origen del 347**
1. **Por atributos, no por diarios.**
   - Asientos con registros de impuesto: devengado → B, deducible → A.
   - Importe: el apunte de la cuenta del tercero de ese asiento, con los ajustes de GeneXus (suplidos y retenciones).
   - Exclusiones por atributos del registro:
     - entregas y adquisiciones intracomunitarias (van al 349);
     - exportaciones e importaciones de bienes;
     - operaciones con retención;
     - terceros no residentes sin NIF español.
   - Los asientos sin registro de impuesto entran solo con un concepto marcado, como en GeneXus.
2. **Replicar la tabla de diarios de GeneXus.** Más fiel, pero ata la plataforma a una codificación que ya hemos sustituido por atributos (ADR-0019).

**Resultado**
1. **Como el 390 y el 425:**
   - declaración por versiones (`liquidacion_impuesto`, modelo 347 o 415, periodo 0A);
   - ajustes por tercero con lápiz, motivo y aviso (lo que hoy se hace editando `tmp347`);
   - control frente al recálculo;
   - sustitutiva y complementaria con justificante.

**Salida**
- **347:** fichero según el diseño de registro oficial de la AEAT, cotejado campo a campo como el 303 y el 390.
- **415:** borrador como el 420 y el 425. El fichero, cuando se disponga del anexo II de la Resolución de 2015 (BOC n.º 41) y se confirme que la sede lo acepta.

## Decisión

Decidido por José María el 2026-11-05 (ficha de terceros mínima, que se completará con facturación y cartera):
1. ~~Entidad `tercero` mínima, una por ficha de GeneXus, sin fusionar por NIF.~~ **Sustituida por el [ADR-0024](0024-terceros-unicos-con-roles.md)**: un tercero por NIF con roles, y la cuenta enlaza el rol.
2. 347 y 415 por atributos (no por diarios), con las exclusiones legales.
3. Resultado por versiones con ajustes por tercero.
4. Umbral y parámetros como norma central versionada.
5. **Campos del diseño 2025 desde los atributos que ya existen:**
   - marca de ISP en las compras con inversión del sujeto pasivo;
   - NIF de operador comunitario: no aplica, porque las intracomunitarias van al 349;
   - importe de caja y BDNS a cero mientras no haya criterio de caja ni subvenciones.

   Las reglas de exclusión del 415 (bienes de inversión, importaciones) se aplican por los atributos del registro.
6. **No replicar los huecos de GeneXus:**
   - cobros en metálico;
   - arrendamientos de locales con referencia catastral (hoja de inmuebles);
   - marcas de inversión del sujeto pasivo y criterio de caja por tercero.
7. **Validación** en modo sombra frente a `tmp347` de GeneXus por NIF, clave y trimestre.

## Consecuencias

- **Datos nuevos:** `tercero`, `tercero_rol` y `cuenta.tercero_rol_id` (ADR-0024); en ejercicios futuros, cobros en metálico por tercero (cartera) y referencias catastrales de los locales arrendados.
- **Export:** `etl/legacy-export/exportar-terceros.cmd` (fichas de terceros, países, `tmp347`, límites, conceptos). Contiene datos personales de terceros: solo en local, nunca en el repositorio.
- **Pendiente de documentación oficial:**
  - diseño de registro del 347 vigente (AEAT);
  - instrucciones y, si existe, diseño del 415 (ATC).

## Origen

Conversación con José María, 2026-11-05.
