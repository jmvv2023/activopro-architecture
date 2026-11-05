---
id: 0022
title: IGIC (420/425) sobre el mismo modelo de liquidación, y prorrata común a IVA e IGIC
status: accepted
date: 2026-11-05
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

**Qué hace hoy GeneXus con el IGIC.** Lo mismo que con el IVA, con otras cuentas de referencia (`CtaRefTpo = 'G'`, `GenResIgic`):
- genera el resumen de la liquidación (sesión `RESIGIC`), que se guarda en `liqiva` como el del IVA;
- genera el libro registro (`LibIgic`);
- **no genera el fichero del 420 ni del 425**: el cliente teclea las casillas en la Agencia Tributaria Canaria (ATC) a partir del resumen.

**La ATC no publica diseño de registro.**
- El 420 y el 425 se presentan por la sede o con el programa de ayuda, que cambia cada año (`m420v930e26`).
- El programa de ayuda importa un fichero propio (`.atc`: XML comprimido y codificado). Solo hay un análisis por ingeniería inversa de un proyecto externo y no consta que la sede acepte ficheros no generados por el programa.

**Modo sombra** (tras ADR-0021):

| Cliente | Trimestres con el resultado de GeneXus | Diferencias |
|---|---|---|
| mconta0086 | 27/27 | — |
| mconta0032 | 3/3 | — |
| mconta0013 | 39/45 | 5 con registros modificados después de guardar la liquidación; queda sin explicar 3T2015 |

**Los clientes con prorrata son canarios**, todos en régimen de prorrata de GeneXus (`EmpRegIva` = 6):

| Cliente | Prorrata | Actividades |
|---|---|---|
| mconta0013 | 2018–2026 | — |
| mconta0032 | 2026, 24 % | gestión administrativa más alquiler de vivienda exento |
| mconta0086 | 2026, 100 % | — |

**Prorrata en GeneXus:**
- la provisional se guarda por año (`prorrata.ProrrataPor`; `ProrrataPorDef` siempre a 0);
- se aplica al dar de alta cada apunte (`PR`, `MovImpNomAux`);
- la definitiva y la regularización se calculan en la liquidación del último periodo (`PorrataDef`: porcentaje redondeado al entero superior). El 4T2025 de mconta0013 (línea 900: 438,86 € al 86 %) sirve de caso real para validarla.

**Casillas del 420** (instrucciones de la ATC según fuentes secundarias; pendiente de cotejar con las oficiales):
- devengado en **6 bloques de base / tipo / cuota (01–18) en los que el tipo es un dato**, no una casilla fija por tipo;
- inversión del sujeto pasivo en 19–20 y modificaciones en 21–22;
- deducible por naturaleza: interiores corrientes 26–27, inversión 28–29, importaciones 30–33, rectificaciones 34–35;
- regularizaciones: bienes de inversión 37 y **prorrata en 39**;
- resultado en 45;
- **cuotas a compensar en 43**.

Las cuotas deducibles se consignan ya prorrateadas: la cuota deducible del ADR-0021.

### Cotejo con los documentos oficiales (2026-11-05)

Fuentes: modelo 420 e instrucciones (Resolución de 15/01/2020, BOC n.º 16 de 24/01/2020); instrucciones del 425 (Resolución de 18/11/2024, BOC n.º 241); documentación del plugin `erseco/facturascripts-plugin-ModelosIGIC` (AGPL-3.0, solo como referencia, sin reutilizar código).

**420**
- **Numeración de casillas:** confirmada la de arriba.
- **Tipos de devengado:** 6 filas de base / tipo / cuota (01–18). El programa de ayuda de 2026 añade las filas 16b–18c, porque en 2026 hay 8 tipos (0, 1, 3, 5, 7, 9,5, 15 y 20 %; el 1 % existe desde el 01/01/2026). Ninguna resolución del BOC ampara todavía ese cambio.
- **Prorrata:**
  - las bases van sin prorratear;
  - las cuotas deducibles (27–36) van después de aplicar la prorrata, que es la `cuota_deducible` del ADR-0021;
  - la casilla 39 solo se rellena en el último periodo del año o en el cese.
- **No hay rectificativa; hay autoliquidación complementaria:**
  - se marca y lleva el justificante de 13 dígitos de la anterior;
  - en la casilla 44 va lo ingresado en la anterior (positivo) o lo devuelto de más (negativo);
  - solo procede si el resultado es un mayor ingreso o una menor devolución o compensación. Si no, se pide la rectificación a la ATC.
- **Encaje en la plataforma:** las versiones de `liquidacion_impuesto` encajan si en el 420 la nueva versión de un periodo presentado sale como complementaria y la 44 se propone desde la versión anterior, como la 110 del 303.
- **Resultado:** I, C, D (solo en el 4T) o «sin actividad».
- **Presentación telemática obligatoria** (Resolución de 22/03/2024), salvo personas físicas que solo arriendan inmuebles hasta 50.000 €.

**425**
- **Quién la presenta:** como el 390, no la presentan quienes llevan los libros por el SII (salvo sin autoliquidación del último periodo).
- **Datos estadísticos:**
  - por actividad, la clave 1–5;
  - el **régimen aplicable 1–11**;
  - la **prorrata general provisional (E) y definitiva (F) y la especial (G)**, que salen de `empresa_prorrata`.
- **Liquidación:**
  - régimen ordinario por tipo (01–18 bis). Las instrucciones no dan la numeración de la fila «bis» y el impreso no está entre los documentos;
  - deducciones 80–93, con la **regularización de la prorrata en la 93**;
  - resultado 95;
  - compensación del ejercicio anterior 114;
  - resultado de las autoliquidaciones 116–119.
- **Volumen de operaciones (120–137)** por clase de operación:

  | Casilla | Operaciones |
  |---|---|
  | 120 | régimen general |
  | 122 | exportaciones (arts. 11–12) |
  | 123 | áreas exentas (art. 13) |
  | 124 | exentas art. 25 Ley 19/1994 |
  | 125 | otras exentas con derecho a deducción |
  | 126 | exentas sin derecho a deducción |
  | 128 | no sujetas por localización y con inversión del sujeto pasivo |
  | 132 | inmuebles y financieras no habituales |
  | 133 | bienes de inversión del transmitente |
  | 136 | soportado no deducible por exclusiones del art. 30 (no la parte de prorrata) |

  Son las mismas clases que separan numerador, denominador y exclusiones de la prorrata definitiva.
- **Programa de ayuda:** solo existe el de 2025 (`m425v631e25`) y todavía no el de 2026.

**Normativa:** desde el 21/10/2025 el IGIC está en el texto refundido del Decreto Legislativo 1/2025 (deroga la parte del IGIC de la Ley 4/2012).

**Fichero:** el `.atc` se importa en el programa de ayuda del mismo ejercicio, no en la sede. Su formato está en el XSD de dentro del programa y el plugin lo ha comprobado byte a byte con el codificador oficial, pero no con una declaración real presentada. Cada ejercicio trae programa y versión nuevos.

## Opciones consideradas

**A. Un motor de liquidación por modelo sobre lo ya construido.**
- El 303, el 420 y, más adelante, el 418 o los forales comparten registros, ajustes por línea, avisos, cierre, versiones, sellado, reapertura y asiento de liquidación.
- Lo propio de cada modelo es la correspondencia apartado × tipo → casillas y el generador de salida.
- Exige generalizar `app.lineas_303`, `app.casillas_303` y compañía por modelo e impuesto. Hoy filtran `impuesto = 'IVA'`.

**B. Funciones paralelas para el IGIC.** Es más rápido, pero duplica la auditoría y el cierre, que es lo más delicado.

**Salida del 420/425** (no hay diseño oficial):
1. **Borrador con las casillas** (pantalla y PDF con la estructura del modelo) para teclearlas en la sede, que es lo que hace hoy el cliente. Sin riesgo de formato.
2. **Fichero `.atc` para el programa de ayuda**, por ingeniería inversa. Ahorra tecleo, pero no es oficial, cambia cada año y un error lo descubre el cliente.
3. **Pedir a la ATC el formato** de importación para software de terceros, como colaboradores sociales.

**Prorrata (común a IVA e IGIC):**
- **Porcentajes por año en la plataforma:** provisional, definitiva y especial si se opta por ella, en una tabla `empresa_prorrata` (empresa, impuesto, ejercicio).
- **Alta de cada soportado de un ejercicio en prorrata:** la cuota deducible se calcula con la provisional. GeneXus exige marcar `PR` a mano.
- **Definitiva al cerrar el último periodo:**
  - numerador: operaciones con derecho a deducción;
  - denominador: todas las operaciones;
  - exclusiones legales (bienes de inversión, operaciones financieras accesorias…);
  - redondeo al entero superior.
- **Regularización:** Σ cuota entera del año × definitiva − Σ deducido. Va a la casilla 39 del 420 o la 44 del 303 como propuesta del programa, editable con lápiz y aviso, como la 110.
- **Asiento de la parte no deducida:** a la cuenta de gasto de prorrata (`IVAPROR` en GeneXus).
- **Lo que necesita el modelo de registros:**
  - no basta con «exenta con o sin derecho»: hace falta una **clase de operación** con las claves del volumen del 425 (122–126, 128, 132 y 133);
  - esa clase sirve a la vez para el volumen del 425, para la definitiva y para el 390, que tiene el mismo concepto en sus casillas de volumen;
  - las exclusiones de la prorrata salen de esa clase, sin una marca aparte.

## Decisión

Decidido por José María el 2026-11-05:

1. **Un solo motor de liquidación por modelo para el 303 y el 420** (opción A). En el 420, la nueva versión de un periodo presentado es una autoliquidación complementaria, con la casilla 44 propuesta desde la versión anterior (como la 110 del 303).
2. **Salida del 420/425 como hoy:** borrador con las casillas para teclearlas en la sede. El fichero `.atc` queda como mejora, a ser posible con formato oficial de la ATC.
3. **Prorrata automática y editable donde la ley lo permite:**
   - **Prorrata general:** un único porcentaje para todo el soportado del año, sin editar la deducción por factura.
     - Lo que se corrige es el porcentaje; al cambiarlo se recalculan los registros de los periodos abiertos.
     - La regularización del último periodo (420 [39], 303 [44]) la propone el programa y se edita con lápiz y aviso, como la 110.
   - **Prorrata especial:** cada compra se asigna a un sector con derecho (100 %), sin derecho (0 %) o común (porcentaje general). Esa asignación es editable por registro.
   - **Ejercicio en prorrata sin porcentaje vigente:** error que se avisa, nunca un 0 % silencioso.
4. **Configuración en dos niveles, con vigencias:**
   - **La norma**, igual para todos los clientes y mantenida centralmente (no la gestiona cada empresa). Versionada por fecha de vigencia, como `parametro_plataforma`, porque cambia dentro de un ejercicio (p. ej. el 1 % del IGIC desde el 01/01/2026). Incluye:
     - tipos de gravamen;
     - correspondencia operación → casilla de cada modelo;
     - clases de operación.
   - **La empresa**, en su pantalla de configuración, con desde/hasta:
     - régimen de deducción (total, prorrata general o especial);
     - sectores diferenciados;
     - porcentaje provisional, con fecha desde dentro del ejercicio, porque puede cambiar por inicio o cese de una actividad, alta a mitad de año o un provisional distinto autorizado;
     - porcentaje definitivo, uno por ejercicio, calculado en el último periodo.

Validación con los tres clientes canarios (mconta0013, mconta0032, mconta0086) y con la regularización del 4T2025 de mconta0013.

Sin confirmar en la ley del IGIC: el umbral por el que la prorrata especial es obligatoria. No se aplica como regla hasta verificarlo.

**Pendiente de confirmar: las rectificativas de ventas en la prorrata definitiva.**
- La plataforma (PR #27 de activopro-platform) sigue a GeneXus (`PorrataDef`): las modificaciones de bases del año no computan en el numerador ni en el denominador.
- Con ese criterio las definitivas de mconta0013 de 2022 a 2025 coinciden con las que tecleó el cliente (85, 86, 87 y 86 %).
- Si se restaran las rectificativas, la de 2024 saldría al 86 %, sin regularización en vez de 94,15 €.
- Es una decisión fiscal; hasta confirmarla se mantiene el criterio de GeneXus.

## Consecuencias

- **Generalizar las funciones del 303** sin cambiar sus resultados; los tests actuales lo cubren.
- **Datos nuevos:**
  - `empresa_prorrata`;
  - el atributo de exentas con o sin derecho a deducción en el registro;
  - las cuentas `IGICMAS` / `IGICMENO` en `empresa_config_fiscal`; el ETL ya las tiene en `pdefecto`.
- **Las páginas de prorrata del 303/390** (página 04 del 303; páginas 05 y 07 del 390) salen del mismo cálculo.
- **Fuera de alcance:**
  - 418 (grandes empresas, mensual), 419 (grupos), 415 (operaciones con terceros), régimen simplificado;
  - regularización plurianual de bienes de inversión (evolutivo).

## Origen

Conversación con José María, 2026-11-05.
