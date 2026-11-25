---
id: 0066
title: Autónomos — contabilidad por partida doble, libros registro del IRPF y resumen para la Renta sacados de ella, y recargo de equivalencia completo
status: proposed
date: 2026-11-25
services: [platform]
supersedes: null
superseded_by: null
---

## Contexto

La plataforma ya trata a la persona física en lo que comparte con la sociedad:

- `tipo_entidad` (ADR-0044);
- retención de IRPF de las emitidas (`empresa_retencion_irpf`);
- 111, 115 y 130 en estimación directa normal y simplificada (ADR-0051), con la difícil justificación, las exclusiones del 130 y la diferencia de amortización fiscal;
- aplicación del resultado a la 550.

Falta lo que solo pide el autónomo:

1. **Libros registro del IRPF** (art. 68 RIRPF; formato de la Orden HAC/773/2019).
   - Los llevan los empresarios en estimación directa simplificada y los profesionales: ingresos, gastos, bienes de inversión y provisiones y suplidos.
   - El empresario con actividad mercantil en directa normal lleva contabilidad conforme al Código de Comercio y no los necesita.
   - Hacienda los pide en requerimientos y comprobaciones en el formato común, el mismo Excel que ya generamos para el IVA (H-084, solo personas jurídicas). La versión de persona física añade las columnas del IRPF en las hojas de ingresos y gastos.
2. **Resumen anual para la Renta.**
   - Es el apartado E1 del modelo 100 (rendimientos de actividades económicas en estimación directa): ingresos íntegros, gastos por casilla, rendimiento neto, reducciones (art. 32 LIRPF), pagos fraccionados y retenciones soportadas.
   - No hay fichero de importación: el asesor teclea las casillas en Renta Web.
3. **Recargo de equivalencia** (minorista persona física).
   - Lo que existe:
     - el régimen en `empresa_regimen_especial`;
     - el bloqueo de 303/390 (`REGIMEN_ESPECIAL_NO_SOPORTADO`);
     - la recibida con recargo, no deducible;
     - el cliente en recargo en la ficha (`tercero_rol.recargo_equivalencia`), que cobra el recargo en las emitidas.
   - Lo que falta: el tratamiento del minorista en sus ventas y en el IRPF, y las declaraciones que sí presenta (309 por adquisiciones intracomunitarias o inversión del sujeto pasivo; 303 si tiene otra actividad en régimen general).

Decisión de José María (25/11/2026): **la contabilidad del autónomo es la misma, por partida doble**. Los libros y el resumen se sacan de ella: no hay un «modo libros» con otra forma de registrar.

## Opciones consideradas

### Libros registro del IRPF

1. **Generar los libros de la contabilidad**: ingresos del grupo 7, gastos del 6, bienes de inversión de las fichas de inmovilizado y suplidos de `titulo_suplidos`. El concepto de cada línea sale de la cuenta por una tabla PGC → concepto del formato común, editable por la empresa.
   - Pros: un solo registro, cuadra con el 130 y con la contabilidad por construcción, sin datos nuevos al teclear.
   - Contras:
     - lo que no tiene cuenta propia (gastos de difícil justificación, reducciones) no es una línea del libro sino un cálculo del resumen;
     - la tabla de conceptos hay que mantenerla con el formato oficial.
2. **Libros como registro propio** (un «libro de ingresos y gastos» que se teclea sin asiento).
   - Pros: es lo que hacen los programas de autónomos sin contabilidad.
   - Contras: dos fuentes que no cuadran; contradice la decisión de la partida doble.
3. **Solo en pantalla, sin Excel.**
   - Pros: lo más barato.
   - Contras: el formato común es lo que piden en un requerimiento. Sin él, el cliente exporta a mano.

### Resumen anual para la Renta

1. **Pantalla con las casillas del E1 y su detalle**, más PDF y Excel por `@activopro/informes`. Las casillas salen de las mismas cuentas que el 130, con su tabla PGC → casilla (otra columna de la misma tabla de conceptos).
   - Pros: es lo que teclea el asesor; reutiliza `app.rendimiento_130`, la amortización fiscal y la difícil justificación.
2. **Fichero para Renta Web.** No existe.

### Recargo de equivalencia

1. **Completar el régimen en el sitio**:
   - ventas del minorista sin liquidar el IVA repercutido;
   - para el IRPF, el IVA repercutido es ingreso y el soportado más el recargo, gasto (criterio del manual de Renta de la AEAT; a confirmar con las instrucciones vigentes);
   - 309 trimestral por las adquisiciones intracomunitarias y la inversión del sujeto pasivo;
   - 303 solo por la actividad en general (sectores diferenciados, ya modelados);
   - sin libros registro de IVA de esa actividad.
2. **Dejarlo como hoy** (bloqueo).
   - Pros: nada que mantener.
   - Contras: un minorista no puede usar la plataforma para lo fiscal.

## Decisión

Propuesta, pendiente de José María:

- **Libros registro del IRPF** según la opción 1.
  - Pantalla de consulta con los cuatro libros por periodo.
  - El Excel del formato común de persona física (IVA e IRPF en las mismas hojas, como lo pide la plantilla oficial), por el mismo camino que `libro_iva_aeat`.
  - El concepto, por la tabla de cuentas con avisos para lo que no encaja (como `LIBROS_AEAT_*`).
  - Solo para persona física y atribución de rentas en estimación directa; en la normal mercantil, se ofrece con una nota (no obligatorio).
- **Resumen para la Renta** según la opción 1, en el mismo módulo fiscal.
  - Casillas del E1 con su detalle hasta el apunte.
  - Pagos fraccionados de los 130 presentados y retenciones soportadas de `app.retenciones_periodo`.
  - Por ejercicio natural (el IRPF lo es aunque el contable no lo sea).
- **Recargo de equivalencia** según la opción 1, en tres pasos:
  1. ventas e IRPF;
  2. 309;
  3. el 303 de sectores diferenciados.

  El paso 1 es necesario para que el resumen de la Renta de un minorista salga bien.

Orden propuesto:

1. Tabla de conceptos y libros IRPF (pantalla y Excel).
2. Resumen para la Renta.
3. Recargo de equivalencia, pasos 1 a 3.

Cada uno con su ADR de detalle si el diseño cambia algo de este.

## Consecuencias

- Nueva norma central **`concepto_irpf`**, versionada por ejercicio: código del formato común, casilla del 100 y descripción, con la correspondencia por defecto PGC → concepto. Copia por empresa para lo que su plan tenga distinto.
  - Los códigos exactos de concepto (ingresos y gastos) y las columnas de la plantilla de persona física hay que tomarlos del diseño oficial vigente al implementar: no se suponen.
  - Si la AEAT cambia la plantilla, se sustituye su JSON, como con `disenoLibrosIva.json`.
- El 130, los libros y el resumen salen de las mismas cuentas, las mismas exclusiones y la misma amortización fiscal. Una diferencia entre ellos es un error, y lo vigila un test que cruza los tres.
- Lo que no sale de la contabilidad no se inventa:
  - las reducciones del art. 32 (requisitos personales);
  - la cuota de autónomos del titular si no está en una cuenta propia;
  - las rentas de otras actividades fuera de la empresa.

  Van como casillas que se ajustan con motivo, como en los modelos (`declaracion_ajuste`).
- Fuera de este alcance:
  - módulos (131 y estimación objetiva);
  - la sección II del 130 (agrícolas);
  - el 100 completo.
- Riesgo: la tabla PGC → concepto acierta en las cuentas estándar y no en las subcuentas propias de cada cliente. Por eso es editable, avisa de lo que no encaja y se mide en los clientes migrados antes de darla por buena (como el 190, con un análisis en `analysis/`).

## Origen

Conversación con José María, 25/11/2026: «para el tema de autónomos la contabilidad la misma por partida doble».

- Al preguntar si el 111 sería solo en pantalla: el 111 ya está completo, con pantalla y fichero (ADR-0051).
- Lo que quedaba abierto era la forma de los libros IRPF. Se propone pantalla más el Excel del formato común, que es lo que se entrega en un requerimiento.
