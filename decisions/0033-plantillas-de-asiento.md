---
id: 0033
title: Plantillas de asiento — líneas tecleadas, fijas, calculadas y de cuadre, con controles por idioma
status: proposed
date: 2026-11-08
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

GeneXus tiene **asientos personalizados**:
- se definen en `AsiDefinicion` (`TrbAsiDef`);
- se introducen con `IngPersonalizado` (diario 33, `PrgId = 'PER'`).

ADR-0028 los dejó para la fase 3 y ADR-0032 adelantó que sus textos irían por idioma.

**Uso real.** 11 schemas usan 16 plantillas:
- nóminas: 0126, 0054, 0095, 0010, 0057;
- cierre de caja y liquidación mensual de recetas de farmacias: 0075, 0077, 0091, 0098, 0105;
- pensión: 0004.

Las plantillas 1 y 2 de cada empresa son las de **existencias** (`IngExistencia`): tienen reglas propias (lado fijo, sin fórmulas, cuentas sin repetir por la analítica) y no entran aquí.

**Cómo funcionan en GeneXus** (leído del código):

- **Líneas** (`asideflineas`): cuenta (opcional), lado D/H, grupo, orden, concepto (`AsiDefConCod`), observación y fórmula (`AsiDefLinConf`). Etiqueta por idioma en `asideflintexto`.
  - **Orden > 0:** la línea se pide en pantalla y el usuario teclea un importe. Sin cuenta, es un **dato de control** (p. ej. «total TC», «líquido») que no genera apunte.
  - **Orden 0:** la línea está oculta y su importe sale de la fórmula. La fórmula es texto (`1+2-3`), y los números son el orden de las líneas tecleadas. El código parte también por `*` y `/`, pero solo aplica `+` y `-`: el operando de un `*` o un `/` se ignora sin aviso.
  - **Grupo de dos líneas:** teclear una genera también la otra por el mismo importe en el lado contrario («contrapartida automática», `DefAsiNumLin`). Ejemplo: indemnizaciones 641 → 465, con solo la 641 en pantalla. Una línea con fórmula en un grupo de dos no se calcula («ya lo he sumado»).
  - Una línea con importe 0 no genera apunte.
  - Si una cuenta del grupo ya no existe, el grupo entero desaparece del formulario sin aviso.
- **Controles** (`asidefcontroles`): «expresión = expresión» con la misma sintaxis, y un mensaje por idioma (`asidefcontrolestexto`, con respaldo en el idioma 1). Si no se cumplen, **no se guarda**.
  - En la nómina de 0126, `1+2-3-4-5-6 = 9` es el cuadre contra el líquido y `7-6 = 8` es la comprobación del TC. Esta última parece mal configurada en tres empresas.
- **El asiento** guarda en cada apunte el orden de la línea de la que sale (`MovImpNomAux`, 0 en las calculadas) y la plantilla en `MovImpNomAux2`. Al modificarlo **se reabre el formulario de la plantilla** con los importes, y los controles vuelven a aplicarse.
- **Sin IVA:** el formulario se salta la comprobación del periodo de IVA (`&MsgIva = 'S'`) y no genera registros de IVA ni de retenciones.

**Restricciones:**
- Los controles se mantienen (José María: «no los podemos quitar hasta estar completamente seguros»).
- Los textos van por idioma (ADR-0032).
- El código tiene que quedar limpio: las plantillas no se mezclan con el editor genérico ni con las facturas.

## Opciones consideradas

**1. Dónde se usan.**
- **a) Como relleno del editor genérico.** La plantilla solo propone las líneas y el usuario sigue en el editor. Es más simple, pero al tocar un apunte se saltan los controles, y al modificar el asiento ya no hay plantilla. Pierde lo que GeneXus garantiza.
- **b) Formulario propio de la plantilla** (como GeneXus), con el asiento ligado a ella y a sus importes tecleados. Al modificar se reabre la plantilla y los controles vuelven a aplicarse. **Elegida.**

**2. Fórmulas.**
- **a) Texto con sintaxis** (`1+2-3`), como GeneXus. Hay que escribir un parser en la base y en el front, y las referencias por número se rompen al reordenar las líneas.
- **b) Lista de términos** `[{linea, signo}]` que apuntan al id de la línea. Es una suma con signo, sin parser. Se puede reordenar y renombrar sin romper nada, y el editor la monta con botones (+ / −) en lugar de teclearla. **Elegida.**

**3. Contrapartida automática de los grupos de dos.**
- **a) Mantener los grupos.** Es la regla menos evidente de GeneXus y la que más casos raros tiene (dos líneas tecleadas en el mismo grupo dan cuatro apuntes).
- **b) Sin grupos:** la contrapartida es una línea calculada con fórmula `= línea N`, que se ve en el formulario. **Elegida.** Lo traduce el ETL.

**4. Dónde se calcula.**
- **a) En el front y en la base**, con la lógica duplicada.
- **b) Solo en la base** (`app.calcular_plantilla`). El front pide el cálculo a la API mientras se teclea (con espera de 250 ms) y la base lo repite al guardar. **Elegida**: una sola fuente, y el cálculo es trivial.

## Decisión

### Modelo

**`plantilla_asiento`** (por empresa):
- `textos jsonb`: `nombre` y `concepto` por defecto del asiento;
- `activa`;
- `codigo_legacy`.

**`plantilla_linea`:**
- `orden`;
- `tipo`;
- `cuenta_id` (subcuenta de la empresa), `lado` (D/H);
- `importe` (en las fijas), `formula jsonb` (términos);
- `textos jsonb`: `etiqueta` en el formulario y `concepto` del apunte (si falta, el del asiento);
- `activa`.

Tipos de línea:

| Tipo | Importe | Cuenta |
|---|---|---|
| `tecleada` | lo teclea el usuario | opcional: sin cuenta es un **dato de control** y no genera apunte |
| `fija` | constante de la plantilla, editable al usarla | obligatoria |
| `calculada` | suma con signo de líneas tecleadas o fijas | obligatoria |
| `cuadre` | lo que cuadra el asiento (una como mucho) | obligatoria; si el cuadre cae en el lado contrario, es un error |

- Las fórmulas y los controles solo referencian líneas **tecleadas o fijas**, como en GeneXus, donde solo las líneas con orden > 0 son referenciables. Así no puede haber ciclos.
- Una línea con importe 0 no genera apunte. Un importe negativo va con su signo en el lado de la línea, como en el resto de la plataforma.

**`plantilla_control`:**
- `orden`, `izquierda jsonb` y `derecha jsonb` (términos);
- `textos jsonb`: el `mensaje`.

Si un control no se cumple, **no se guarda**, como en GeneXus. El formulario muestra el mensaje del usuario y los dos importes en el idioma de quien lo usa.

**`asiento`** añade dos columnas:
- `plantilla_id`;
- `plantilla_valores jsonb`: `{linea_id: importe}` de las líneas tecleadas y fijas.

**Textos:**
- nombre, etiquetas, conceptos y mensajes van en `textos jsonb` (`app.textos_validos`, leídos con `app.texto`);
- el concepto del apunte se escribe en el idioma de quien genera el asiento y se guarda como texto, como cualquier apunte.

### Funciones (`app`, con errores por código: ADR-0032)

- **`app.guardar_plantilla(empresa, id, datos)`**:
  - comprueba los tipos, la cuenta y el lado obligatorios, las referencias solo a tecleadas o fijas de la misma plantilla, un cuadre como mucho y que haya al menos una línea con cuenta;
  - una línea con asientos no se borra: se desactiva.
- **`app.borrar_plantilla`**: solo si no tiene asientos. Si los tiene, se desactiva.
- **`app.calcular_plantilla(empresa, plantilla, valores)`**: devuelve los apuntes, los totales, el resultado de cada control (`{ok, izquierda, derecha, mensaje}`) y avisos. Es `stable`, sin escribir nada.
- **`app.guardar_asiento_plantilla(empresa, asiento, plantilla, datos)`**:
  - recalcula y rechaza si un control falla (`CONTROL_PLANTILLA`, con los importes como parámetros);
  - crea o rehace el asiento por el mismo camino que `app.guardar_asiento`, con origen `personalizado`, `plantilla_id` y `plantilla_valores`;
  - las reglas de periodos (B1) las aplican los triggers, como a todo.
- **Asientos en preparación:** `asiento_preparacion` guarda `{plantilla_id, valores}`.

### Pantallas

- **Configuración › Plantillas de asiento** (permiso `contabilidad.configurar`):
  - lista de plantillas;
  - editor con la tabla de líneas (orden arrastrable, etiqueta, tipo, cuenta, lado, importe o fórmula);
  - fórmulas montadas con chips «+ L3 − L5» al elegir las líneas;
  - controles con su mensaje por idioma;
  - panel «Probar» con importes de ejemplo para ver los apuntes y los controles antes de guardar.
- **Usar una plantilla** (permiso `contabilidad.preparar`): «Nuevo asiento» ofrece «Asiento manual» o la lista de plantillas. El formulario tiene:
  - la cabecera (fecha, concepto, documento);
  - las líneas tecleadas con su campo;
  - las fijas, editables;
  - las calculadas y el cuadre, **visibles en solo lectura** con su resultado (GeneXus las ocultaba; verlas explica el asiento);
  - los totales del debe y el haber;
  - los controles en vivo (✓ / ✗ con el mensaje). «Guardar» queda desactivado mientras alguno falla.
- **Modificar** un asiento de plantilla reabre ese formulario con sus importes. Si la plantilla cambió después del asiento, avisa de que se recalcula con la definición actual. Un asiento sin plantilla utilizable (borrada, o migrado sin reconstruir) se abre en el editor genérico.
- **«Guardar como plantilla»** desde un asiento o desde el editor: crea una plantilla con sus cuentas y lados, todas tecleadas, y abre su editor.

### Lo que no hace

- **Sin IVA ni retenciones:** no genera registros de IVA ni de retenciones. Las facturas van por su formulario (ADR-0030).
- **Periodo de IVA:** una línea a una cuenta de impuesto (472/477) avisa en el editor de la plantilla. Si se usa, el asiento queda sujeto a la regla de periodos B1 como cualquier otro. GeneXus se saltaba esta comprobación; no se replica.
- **Fuera:** las plantillas de existencias (1 y 2, con el asistente de existencias), y las de catálogo o sector (con el alta de empresa).

### ETL

Migra las plantillas usadas (con asientos del diario 33) y traduce lo siguiente. Si más adelante se necesita otra, se carga con el mismo comando indicando su código:
- **líneas:**
  - orden > 0 → `tecleada`;
  - orden 0 con fórmula → `calculada`;
  - grupo de dos → la otra línea pasa a `calculada` con fórmula `= línea`;
  - dos tecleadas en el mismo grupo → líneas de dato y dos calculadas con la suma, para reproducir los cuatro apuntes;
- **fórmulas:** de texto a términos. Un `*` o `/` se quita, como lo ignora GeneXus, y queda como anomalía;
- **textos:** los de cada idioma, por la tabla de idiomas de GeneXus;
- **asientos del diario 33:** se enlazan con `plantilla_valores`, reconstruidos desde `MovImpNomAux`.

**Modo sombra** (`npm run etl -- comparar-plantillas <schema>`):
- regenera cada asiento del diario 33 con sus valores y la plantilla traducida, y compara los apuntes (cuenta, lado, importe);
- si coinciden, el asiento queda enlazado;
- si no, queda sin enlace (se modifica en el editor genérico) y como anomalía.

Es la prueba de que la traducción de los grupos y las fórmulas es fiel.

## Consecuencias

- **Controles:** los de GeneXus se conservan y siguen bloqueando, ahora con mensaje traducido e importes visibles. Uno mal configurado sigue impidiendo guardar: se corrige en la plantilla, nunca quitándolo en la migración.
- **Formulario:** desaparecen las reglas implícitas (grupos, líneas ocultas, cuentas que se caen del formulario sin aviso). Todo lo que genera apunte se ve en el formulario.
- **Código:** las plantillas tienen sus tablas, funciones y pantallas, y solo comparten con el editor el camino de guardar el asiento.
- **Decidido por José María (08/11/2026):**
  1. Los controles bloquean, como en GeneXus.
  2. Pendiente: comprobar si hay líneas a 472/477 en las plantillas (consulta en los 11 schemas).
  3. Se migran solo las plantillas usadas. Las demás se pueden cargar más adelante con el ETL si se necesitan.
  4. Definir plantillas es solo del administrador (`contabilidad.configurar`).
- **Pendiente:**
  - el modelo 111 y las retenciones de nómina (ADR propio, cuando llegue);
  - las líneas con «cuenta a elegir al usar» (p. ej. el banco), si se piden.

## Origen

Conversación del 08/11/2026 con José María:
- análisis del uso real de las plantillas (11 schemas, 16 plantillas) y de la nómina de mconta0126 con sus controles;
- pidió mantener los controles, separar bien el código e incluir la internacionalización (ADR-0032).
