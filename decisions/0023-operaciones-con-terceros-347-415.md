---
id: 0023
title: Operaciones con terceros (347 y 415) desde los apuntes, con terceros en la plataforma y declaración por versiones
status: proposed
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
- **415:** borrador como el 420 y el 425, salvo que la ATC publique un diseño.

## Decisión

Propuesta, pendiente de José María:
1. Entidad `tercero` mínima, enlazada a la cuenta, cargada desde las fichas de GeneXus.
2. 347 y 415 por atributos (no por diarios), con las exclusiones legales.
3. Resultado por versiones con ajustes por tercero.
4. Umbral y parámetros como norma central versionada.
5. **No replicar los huecos de GeneXus:**
   - cobros en metálico;
   - arrendamientos de locales con referencia catastral (hoja de inmuebles);
   - marcas de inversión del sujeto pasivo y criterio de caja por tercero.
6. **Validación** en modo sombra frente a `tmp347` de GeneXus por NIF, clave y trimestre.

## Consecuencias

- **Datos nuevos:** `tercero` (y `cuenta.tercero_id`); en ejercicios futuros, cobros en metálico por tercero (cartera) y referencias catastrales de los locales arrendados.
- **Export:** `etl/legacy-export/exportar-terceros.cmd` (fichas de terceros, países, `tmp347`, límites, conceptos). Contiene datos personales de terceros: solo en local, nunca en el repositorio.
- **Pendiente de documentación oficial:**
  - diseño de registro del 347 vigente (AEAT);
  - instrucciones y, si existe, diseño del 415 (ATC).

## Origen

Conversación con José María, 2026-11-05.
