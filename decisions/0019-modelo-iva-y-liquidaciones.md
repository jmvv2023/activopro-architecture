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
- reabrir el trimestre permite volver a cerrarlo, lo que genera una nueva liquidación.

## Consecuencias

- El 303, el 390, el libro registro y el SII se calculan agrupando atributos, sin números de diario.
- El modo sombra compara cada trimestre con `liqiva`. Las diferencias por registros modificados después de liquidar son esperables y se listan, no se corrigen.

Pendiente de decidir:
1. Al volver a cerrar un trimestre, ¿se **conserva la versión anterior** (historial de presentaciones, útil para complementarias) o se sustituye como hoy? Propuesta: conservarla.
2. Correspondencia tipo impositivo → cuenta (`ivatiposctas`/`igictiposctas`) al contabilizar desde la plataforma nueva.

Siguiente paso: casillas del 303 y fichero AEAT, comparado byte a byte con ficheros generados por GeneXus. Después: prorrata/DP, grupos ≥ 100 (exentas, exportaciones, entregas intracomunitarias), 390, IGIC 420, 347 y 349.

## Origen

Sesión con José María del 2026-11-04; `jmvv2023/activopro-platform` PR #7.
