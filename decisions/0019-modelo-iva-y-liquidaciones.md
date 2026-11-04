---
id: 0019
title: Atributos fiscales explícitos en el registro de IVA y liquidación guardada como lo presentado
status: proposed
date: 2026-11-04
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

En GeneXus el tratamiento de IVA de un registro no está en el registro. Se deduce al liquidar (`GenResIva`) a partir de varias fuentes:
- las cuentas de referencia de la empresa (`tctareferencia`, `CtaRefTpo = 'I'`, `CtaRefTpoIva`), con correcciones fijas en el código (4724→6, 4773/4774/4775→2);
- la subcuenta: si empieza por `01`, es recargo de equivalencia;
- el diario: 42 (ISP), 4, 40, 23 y 41 (inversión), 47 (ISP inmobiliaria);
- el concepto: `ConCod` 2 y 6 son rectificaciones;
- `MovIvaDed` (ND, NJ, DP, PR, EX…).

Las autoliquidaciones (intracomunitarias, ISP) se guardan como un único registro en un apunte cuyas dos cuentas son de IVA (p. ej. 4773/4723). `GenResIva` lo cuenta dos veces.

Al cerrar el IVA de un trimestre, `LiqIvaAlta` guarda el resumen en `liqiva`, y `IVA_303_2017` genera el fichero del 303.

Requisitos de José María (2026-11-04):
- el 303 es un fichero para subida directa a la AEAT, en el formato de registro oficial, y no se modifica a mano;
- `liqiva` debe ser lo presentado;
- un trimestre reabierto se puede volver a cerrar, y entonces se vuelve a guardar la liquidación.

Validación en modo sombra con mconta0037 (36 trimestres, 2017–2025), en `activopro-platform` PR #7:
- grupos (base y cuota por cuenta) idénticos en 33/36 trimestres;
- resultado idéntico en 34/36 trimestres.

Las tres diferencias son registros modificados después de liquidar. Lo que se presentó ya no se puede reconstruir desde los apuntes, y por eso hay que guardarlo.

## Opciones consideradas

1. **Replicar GenResIva** en la plataforma nueva (cuentas de referencia, diarios y conceptos al liquidar). Da paridad inmediata, pero arrastra la lógica implícita y los números de diario a todo el código nuevo (303, 390, SII, libro).
2. **Atributos fiscales explícitos en cada registro, fijados al contabilizar.** El 303, el 390 y el libro son agrupaciones de esos atributos. La traducción desde GeneXus vive solo en el ETL.

## Decisión

Se elige la opción 2.

Cada `registro_iva` lleva estos atributos:
- `impuesto`: IVA, IGIC o IPSI;
- `sentido`: devengado o deducible;
- `operacion`: interior, intracomunitaria, intracomunitaria de servicios, ISP, ISP inmobiliaria, importación, régimen agrícola, exportación, entrega intracomunitaria…;
- `recargo_equivalencia`, `bien_inversion` y `rectificacion`;
- `deducibilidad`: total, parcial, prorrata, no deducible, no sujeta o exenta;
- `cuenta_impuesto_id`.

Una autoliquidación son **dos registros**, uno devengado y otro deducible. La lógica de GeneXus queda confinada en `etl/src/iva.ts`.

La **liquidación cerrada es inmutable y es lo presentado**:
- al cerrar el trimestre se guardan el resumen (casillas del 303) y el fichero generado;
- el fichero sigue el diseño de registro de la AEAT y no se edita;
- reabrir el trimestre permite volver a cerrarlo, lo que genera una nueva versión de la liquidación;
- las versiones anteriores se conservan, marcadas como sustituidas, como histórico y trazabilidad (decidido por José María el 2026-11-04). El volumen es despreciable: un resumen de unas decenas de casillas y un fichero de unos pocos KB por empresa y trimestre.

## Consecuencias

- El 303, el 390, el libro registro y el SII se calculan agrupando atributos, sin números de diario.
- El modo sombra compara cada trimestre con `liqiva`. Las diferencias son esperables y se listan, no se corrigen. Pueden venir de registros modificados después de liquidar o de retoques manuales antes de cerrar: en la pantalla de liquidación (`TrbResIva`) cada línea del resumen se puede editar (`TmpIva`) y `liqiva` guarda el valor retocado sin el calculado, así que no se distinguen.

Pendiente de decidir:
1. Deducibilidad parcial (`DP`): GeneXus guarda en el registro solo la cuota deducible y el informe muestra aparte la parte no deducible (fila 0103, calculada como cuota íntegra − cuota deducible, línea a línea). Propuesta: guardar también la cuota no deducible de forma explícita en el registro.
2. Retoques manuales de la liquidación (la misma puerta que hoy): propuesta de guardar por línea el valor calculado, el ajuste, el usuario y el motivo, en lugar de sobrescribir; las casillas salen de calculado + ajuste.
3. Correspondencia tipo impositivo → cuenta (`ivatiposctas`/`igictiposctas`) al contabilizar desde la plataforma nueva.

Hecho (activopro-platform PR #8): casillas del 303 (`app.casillas_303`), fichero AEAT (`src/fiscal/modelo303.ts`) y liquidación por versiones (`liquidacion_impuesto`). El fichero generado con los datos de la plataforma es idéntico byte a byte al de GeneXus de 3T2026 (mconta0037). El fichero se obtiene solo con «Contabilizar/Descargar 303» en GeneXus, que además contabiliza; en la plataforma, el fichero de cualquier versión cerrada se puede volver a descargar sin reabrir nada.

Tipos especiales sin validar: en `IVA_303_2017` las casillas 150, 165 y 153 leen las tres la subcuenta 000000 (0 %), y el 5 % (000500) no tiene casilla. Hay que cotejarlo con el diseño de registro oficial antes de soportar 0 %, 2 %, 5 % y 7,5 %; mientras tanto, la plataforma da error con esos tipos.

Siguiente: asiento de liquidación al cerrar, compensación tomada de la liquidación anterior y retoques manuales (pendiente 2). Después: prorrata/DP, grupos ≥ 100 (exentas, exportaciones, entregas intracomunitarias), 390, IGIC 420, 347 y 349.

## Validación con los informes de GeneXus

Los informes «Resumen de IVA» y «Autoliquidación de IVA» de mconta0037 para 2T2019, 2T2021 y 3T2023, generados el 2026-11-04 con los datos actuales, coinciden línea a línea con lo que calcula la plataforma nueva:
- devengado, deducible, rectificaciones y bienes de inversión, por cuenta y tipo;
- entregas exentas y recibidas exentas;
- «No deducible» (138,23 € en 3T2023), que es la parte no deducible de los registros con deducibilidad parcial.

## Origen

Sesión con José María del 2026-11-04; `jmvv2023/activopro-platform` PR #7.
