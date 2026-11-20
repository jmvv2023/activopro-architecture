# SII en ActivoPro (plataforma)

Suministro Inmediato de Información: los libros registro de IVA se llevan en la sede de la AEAT enviando cada factura por
servicio web (art. 62 a 71 RIVA). Este documento reúne cómo lo hace la plataforma (`activopro-platform`), las reglas
que aplica y por qué.

- **Decisiones:**
  - ADR-0053: el SII, el estado por factura y el envío;
  - ADR-0055: VeriFactu y SII como tramos;
  - ADR-0056: emitida rechazada que se sustituye y NIF comprobado en el censo.
- **Código.** El detalle de tablas y funciones está en `activopro-platform/CLAUDE.md` (apartado SII). Aquí, las reglas.

## 1. Quién lleva el SII

- **Obligados:** grandes empresas, inscritos en el REDEME (devolución mensual), grupos de IVA y quien lo elige (036).
- **Cuándo entra o sale:**
  - El efecto es desde el periodo de liquidación siguiente.
  - Quien entra deja de enviar a VeriFactu desde ese momento.
  - Quien sale vuelve a VeriFactu.
- **Tramos (ADR-0055).** En la plataforma, el sistema de facturación de una empresa es una serie de tramos
  (`empresa_sistema_facturacion`: `verifactu` o `sii`, desde, hasta), uno a la vez.
- **Quién cambia el tramo.** Solo Enumbers, desde la consola. La base comprueba todas las reglas, sin forma de saltarlas:
  - día 1 de un periodo de liquidación futuro;
  - sin registros en curso del sistema que se deja;
  - los rechazados de ese sistema se aceptan expresamente;
  - el SII solo con IVA y con el módulo `sii` contratado;
  - nunca en País Vasco ni Navarra.
- **Cada factura va al sistema de su fecha:**
  - el SII, por la fecha del registro (`app.sii_activo(empresa, fecha)`);
  - VeriFactu, por la de expedición.
- **Al salir del SII**, lo de su periodo se sigue enviando y corrigiendo (`app.tiene_sii`).
- **Lo que conlleva:**
  - 303 mensual en los trimestres en el SII (periodicidad `mixta`);
  - exonerado del 390 si está en el SII el 31/12 (`app.exonerado_390`);
  - sin libros registro en Excel de la AEAT en esos periodos (`LIBROS_AEAT_SII`).
- **Solo IVA de territorio común.** El SII del IGIC es otro servicio, el de la ATC, sin clientes por ahora (pendiente).

## 2. Qué se envía: un registro por factura del libro

- **Unidad.**
  - El SII es el libro entero: facturas de la plataforma, asientos manuales, cierres de caja e importaciones.
  - La unidad es el **asiento con registros de IVA**, como el 303.
  - Cada asiento da una o más facturas, emitidas o recibidas: `app.contenido_sii(asiento)`, del mismo libro que
    `app.libro_registro_iva`.
- **Identidad de una factura para la AEAT:** NIF del emisor + número (con serie) + fecha de expedición. Nunca un id
  nuestro.
  - En la plataforma: `registro_sii (libro, emisor, numero, fecha_expedicion)`.
  - Sin número (un asiento manual sin documento), `#<id del asiento>`.
- **Contenido** (`registro_sii.contenido`, canónico, comparable):
  - tipo de factura: F1, F2, F3, F4 (asiento resumen de los cierres de caja, con primer y último ticket), F5 (DUA),
    R1–R5;
  - clave de régimen;
  - contraparte (`app.identificacion_aeat`: NIF, o país + tipo + id);
  - desglose de factura, o por tipo de operación (entrega o servicio) con una empresa extranjera;
  - S1/S2/N1/N2 y exenciones E1–E6;
  - ISP;
  - en las recibidas, fecha de registro, cuota deducible y bien de inversión;
  - rectificativas por diferencias (`I`), o por sustitución (`S`, con `ImporteRectificacion`) solo si la sustitución es en
    positivo, siempre con las rectificadas.
- **Errores propios** (`SII_*`): lo que la plataforma ya ve que la AEAT rechazaría. La factura queda **incompleta** y no
  se envía hasta corregirlo:
  - sin número;
  - sin NIF ni nombre de la contraparte;
  - registro antes de la expedición;
  - resumen sin tickets…
- **Avisos propios** (no impiden enviar):
  - tipo de operación supuesto;
  - arrendamiento, que va con clave 01 mientras no haya inmuebles.

## 3. Ciclo de un registro

`registro_sii` guarda:

- lo que hay ahora (`contenido`) y lo último aceptado (`contenido_enviado`);
- la **situación** en la AEAT: `no_enviada`, `registrada`, `con_errores`, `de_baja` o `sustituida`;
- la **comunicación pendiente**: `A0` alta, `A1` modificación o `baja`, con su **plazo** (`limite`).

La aplicación solo lee la tabla.

**Cambios** (triggers diferidos de asiento, apunte, registro de IVA y factura → `app.sincronizar_sii`):

| Qué pasa | Resultado |
|---|---|
| Factura nueva en un tramo SII | `A0` pendiente |
| Cambia lo registrado en la AEAT | `A1` pendiente; si vuelve a lo enviado, nada |
| Cambia la identidad (número, fecha, NIF del emisor) | baja de la anterior y `A0` de la nueva |
| Desaparece (asiento anulado, sin IVA) | baja si la AEAT la tiene; si nunca se envió, se borra |
| Cambia el NIF, el tipo o el país en la ficha del tercero (asientos sin factura de la plataforma) | `A1`, o baja y alta en las recibidas (ADR-0053, H-089) |
| Cambia solo el nombre del tercero | nada en lo registrado: se queda con el nombre con que se envió |
| Mes con el IVA cerrado | lo registrado no cambia; reabrir la liquidación lo recalcula |

**Estado que se enseña** (`app.estado_registro_sii`):

| Estado | Qué significa |
|---|---|
| `pendiente` | Hay algo que enviar y nadie lo ha pedido aún |
| `enviando` | Pedido por el usuario o en un lote del worker (se ve desde que se pide) |
| `incompleta` | Le falta algo que la AEAT exigiría; se corrige en el origen |
| `rechazada` | La AEAT dijo `Incorrecto`; no vuelve a salir hasta que cambie el contenido |
| `con_errores` | Aceptada con errores: la AEAT la tiene, hay que corregirla (sale `A1`) |
| `enviada` | Registrada, con su CSV |
| `de_baja` | Dada de baja en la AEAT |
| `sustituida` | Emitida rechazada anulada con su rectificativa y sustituida por otra (ADR-0056); no se envía |

## 4. Plazos

- **Alta** (`app.limite_sii`): 4 días hábiles (sin sábados, domingos ni festivos nacionales, `festivo_nacional`) y siempre
  antes del día 16 del mes siguiente.
  - Las emitidas cuentan desde la expedición (el día 16, por el mes del devengo).
  - Las recibidas, desde el registro.
- **Modificación y baja:** antes del día 16 del mes siguiente al cambio.
- **Sanción por retraso:** 0,5 % del importe, mínimo 300 € y máximo 6.000 € por trimestre (art. 200 LGT).
- **Fuera de plazo no se bloquea: se confirma.**
  - El envío dice cuántas facturas y cuántos días de retraso.
  - Exige «Envío fuera de plazo bajo mi responsabilidad».
  - Queda en `sii_evento` con usuario, registros y días.
  - En modo automático, lo vencido no sale solo.
- **Festivos nacionales cargados hasta 2027.** Cada año hay que añadir el siguiente.

## 5. Envío

- **Modo por empresa** (`sii_envio`):
  - **manual** (por defecto): lo envía un usuario desde la pantalla SII, la factura o el asiento;
  - **automático**: sale solo cuando lleva un rato sin cambios (`sii_espera_minutos`) y antes de que venza.
- **Al pedirlo** (`app.enviar_sii`):
  - se marca `solicitado_en`;
  - el registro pasa a **Enviando…**;
  - se encola el trabajo `sii.enviar`, uno por empresa y libro.
- **El worker** (`apps/worker/src/sii.ts`, solo con `AEAT_ENV`):
  - toma un lote (`app.lote_sii`, hasta 10.000, una sola comunicación por lote);
  - lo envía con el certificado de la empresa;
  - guarda la respuesta por factura (`app.resultado_lote_sii`).
- **Respuesta por factura:**
  - **Correcto:** registrada, con el CSV.
  - **AceptadoConErrores:** con errores; la siguiente es `A1`.
  - **Incorrecto:** rechazada. Guarda lo rechazado y no sale de nuevo hasta que cambie.
  - **Duplicada** (ya estaba en la AEAT, p. ej. la envió el programa anterior): se toma como registrada y la siguiente es
    `A1`.
  - **Modificación de una que no existe:** pasa a `A0`.
- **Sin respuesta o error del servidor:**
  - se suelta el lote (`app.fallo_lote_sii`), sigue pedido y el worker reintenta con espera creciente;
  - un SOAP Fault del cliente es `SII_ENVIO_RECHAZADO`.
- **Sin certificado,** el trabajo se aplaza.
- **La pantalla avisa** si lo pedido lleva más de dos minutos sin que el worker lo recoja, o si el último intento falló
  (`registros_sii.cola`).
- **Entornos:** `AEAT_ENV=pre` en local y pruebas; `pro` solo en producción, lo activa José María.
- **Probado en preproducción** con el certificado de Enumbers el 20/11/2026 (demo en la base local con
  `--nif B23918170 --sistema sii`):
  - altas de emitidas y recibidas;
  - modificación;
  - fuera de plazo;
  - rechazo 1117.

## 6. Rechazos y cómo se resuelven

| Origen del registro | Cómo se corrige |
|---|---|
| Asiento manual, cierre de caja, recibida | Se corrige el origen (o la ficha del tercero) y se vuelve a enviar |
| Emitida de la plataforma | No se modifica nunca. Si la AEAT no la ha aceptado, **se sustituye** (abajo); si la tiene, rectificativa normal |

**Sustitución de una emitida rechazada o incompleta (ADR-0056, A):**

1. Solo si la AEAT no tiene su alta (`no_enviada`, rechazada o incompleta).
2. `app.sustituir_emitida` emite la **rectificativa por diferencias**, copia exacta en negativo, al mismo cliente y NIF.
3. Prepara un **borrador** de la factura nueva con las mismas líneas al cliente elegido. El usuario lo revisa y lo emite.
4. La original y su rectificativa quedan **sustituidas**:
   - no se envían;
   - salen de los pendientes y de los plazos;
   - guardan el motivo y quién lo hizo.

   No se envían porque la AEAT no tiene la original y la rectificativa la rechazaría igual. Juntas suman cero, también en
   el 303.
5. Sin nada cobrado, la cartera de las dos se compensa sola. Con cobros, se reaplican a la nueva.

**NIF no identificado (1117):**

- Persona física no censada: tipo de identificación «no censado» (código 07, NIF de persona física, España); la AEAT la
  acepta con errores.
- Sociedad: hay que corregir el NIF; con la emitida, sustitución.

## 7. NIF comprobado en el censo (ADR-0056, C)

- **Servicio** `VNifV2` de la AEAT (servicio web masivo de calidad de datos identificativos; NIF + nombre):
  - respuestas `Identificado`, `No identificado`, `No identificado-similar` (personas físicas), `Identificado-Baja`,
    `Identificado-Revocado` (entidades) y `No procesado` (por encima del máximo);
  - hasta 10.000 por petición (el esquema admite 20.000; se usa lo que dice el manual);
  - con el certificado de la empresa (mTLS, sin firmar el mensaje): `www1` con certificado de persona física o de
    representante, `www10` con certificado de sello (`AEAT_CENSO_SELLO=si`);
  - el nombre se manda siempre (obligatorio en personas físicas; el esquema pide la etiqueta).
  - Solo para cumplir obligaciones tributarias, o la AEAT bloquea el acceso: se comprueba **una vez por NIF y nombre** y
    cuando cambian, nunca en cada factura.
- **Qué se comprueba.** Terceros con NIF español válido (tipo `nif` o `no_censado`, país ES, no de relleno) de una empresa
  con certificado vigente (`app.censo_aplica`). Un NIF extranjero, un pasaporte o uno no válido: `no_aplica`.
- **Cuándo** (trabajo `censo.comprobar`, uno vivo por empresa, con un minuto de espera para juntar lo que llega seguido en
  una sola petición; `app.programar_censo`):
  - al dar de alta un tercero o cambiar su NIF, nombre, tipo o país (trigger `tercero_censo`);
  - al subir el certificado (trigger `certificado_censo`: lo que estaba sin comprobar, ya);
  - desde la ficha, «Comprobar en la AEAT» (`app.pedir_censo`: se repite aunque esté al día);
  - al emitir o registrar con un tercero sin comprobar o desfasado (no espera a la respuesta).
- **Dónde queda.** En el tercero: `censo_estado`, el NIF y el nombre con que se comprobó (`censo_nif`, `censo_nombre`), el
  nombre que devuelve la AEAT (`censo_nombre_aeat`) y la fecha.
  - Estado que se enseña (`app.estado_censo`): `no_aplica`, `sin_comprobar`, `desfasado` (el NIF o el nombre de la ficha ya
    no son los comprobados) o el resultado.
  - Si la ficha cambia mientras se comprueba, la respuesta no se guarda: se vuelve a comprobar con lo de ahora. «No
    procesado» deja el tercero como estaba.
  - Cada petición queda en `envio_aeat` (servicio `censo`).
- **Avisos:**
  - **Ficha:** franja **Censo de la AEAT** con el estado, la fecha y el nombre de la AEAT; avisos `CENSO_NO_IDENTIFICADO`,
    `CENSO_BAJA`, `CENSO_REVOCADO`, `CENSO_SIMILAR`; en la portada de Terceros, **NIF no identificado** entre las fichas
    por revisar.
  - **Al emitir** una factura de la plataforma (SII o VeriFactu) o **registrar una recibida en el SII** con un tercero no
    identificado, de baja o revocado (y comprobado con el NIF y el nombre de ahora): `CENSO_NIF_NO_IDENTIFICADO`, que hay
    que confirmar (casilla «Entiendo que la AEAT puede rechazarla»; la API manda `aceptar_censo` y la base lo ve en
    `app.censo_aceptado`). Lo comprueban triggers de `factura` (al numerar la emitida y al contabilizar la recibida), así
    que vale para cualquier camino (factura, emisión en bloque: allí sale como error de esa factura).
    - No bloquea: el censo puede ir por detrás (una sociedad recién constituida) y la AEAT dice que se reintente.
    - «Similar», sin comprobar o desfasado: sin confirmación.
    - **Las rectificativas no preguntan:** van al cliente de la original, también la de una sustitución (§6).
    - Corregir una recibida ya contabilizada no vuelve a preguntar.
- **Sin entorno de pruebas en la AEAT:**
  - el worker solo registra el trabajo con `AEAT_CENSO=pro`, que pone quien despliega (nunca una sesión autónoma);
  - sin él, las comprobaciones esperan en la cola y los terceros quedan «sin comprobar» (en preproducción no se pregunta
    nada al emitir);
  - los tests usan un simulador (`apps/worker/test/censo.test.ts`, `packages/aeat/test/censo.test.ts`).

## 7 bis. Cuadre con la AEAT (ADR-0053, ampliación del 20/11/2026)

- **Para qué.** Saber qué tiene de verdad la AEAT: lo que la plataforma cree enviado puede no coincidir (cargas de otro
  programa, asientos borrados que nadie dio de baja, cálculos distintos).
- **Consulta** (`ConsultaLRFacturasEmitidas` / `Recibidas`, mismo servicio que el envío, con preproducción): por empresa, libro,
  ejercicio y mes, 10.000 registros por respuesta y paginada con el último registro. La pide el usuario (`sii.consultar`) o
  Enumbers en la migración, y la hace el worker (`sii.consultar`). Una consulta nueva del mismo periodo sustituye a la anterior.
- **Comparación en el formato de la AEAT.** Lo de la plataforma se escribe con el mismo generador del envío (desglose agrupado
  por tipo, textos recortados) y se lee con el mismo lector que la respuesta; textos sin diferencias de mayúsculas ni espacios.
  Por factura (NIF del emisor + número + fecha), además, si el periodo no coincide.
- **Resultados:**
  - **igual** — la AEAT tiene lo que la plataforma cree enviado, o lo que enviaría ahora (entonces lo pendiente se da por
    enviado);
  - **distinta** / **ya en la AEAT** — la AEAT la tiene con otros datos (la plataforma la daba por enviada / la tenía pendiente
    de alta);
  - **falta en la AEAT** — la plataforma la da por enviada (o pendiente de modificación o baja) y la AEAT no la tiene o la tiene
    anulada;
  - **solo en la AEAT** — la AEAT la tiene y la plataforma no;
  - **en envío** — se estaba enviando al consultar; se vuelve a consultar.
  - Lo pendiente de baja cuadra siempre (la baja lo resuelve).
- **La AEAT manda:**
  - el estado (registrada / con errores con su código), el CSV y el contraste con la otra parte (1 no contrastable … 5
    contrastada, con el descuadre si es parcial) se toman siempre: no se envía nada;
  - lo que difiere en el contenido queda **retenido** (`cuadre_pendiente`, estado «Distinta en la AEAT»): no sale ni con
    «Enviar» ni en el envío automático, y un cambio en la factura no lo suelta;
  - lo que la plataforma creía enviado se olvida en las distintas (la AEAT tiene otra cosa).
- **Decisiones** (`sii.enviar`, con motivo de 10 caracteres, en bloque, en `sii_evento`):
  - distinta / ya en la AEAT → **enviar la de la plataforma** (modificación pendiente) o **dejar la de la AEAT** (se da por
    igual a lo de ahora: no sale modificación hasta que la factura cambie);
  - falta en la AEAT → **volver a darla de alta** (alta pendiente, con su plazo original: fuera de plazo si toca) o **dejarla**
    (queda de baja en la plataforma);
  - solo en la AEAT → **darla de baja** (registro sin asiento solo para la baja, con la identificación, el periodo y el nombre
    que tiene la AEAT) o **dejarla**.
  - Lo decidido sale con «Enviar», con el aviso de fuera de plazo.
- **Migración** (decidido el 20/11/2026 con mconta0124; `app.cargar_estado_sii`, `etl/src/sii.ts`):
  - `pressii` trae por asiento el estado de la AEAT (Correcto, AceptadoConErrores o vacío si no se envió), el CSV, la fecha de
    envío y el error, pero **no el XML enviado**;
  - el tramo SII de la empresa empieza el día 1 del primer mes presentado (si no tiene uno);
  - la plataforma calcula lo que enviaría de cada asiento con IVA del tramo; lo presentado queda registrado (o con errores) con su
    CSV y lo no enviado, pendiente de alta; **todo «por cuadrar»** (`por_cuadrar`): no sale nada, ni a mano ni en automático,
    hasta que la consulta de su mes lo compare con la AEAT; entonces lo igual queda enviado, lo que falta queda pendiente como
    siempre y lo que difiere, para decidir;
  - los asientos con IVA sin envío que se anulan con otro del mismo documento (asiento y contraasiento que suman cero) no se dan
    de alta: anomalía `sii_anulados_entre_si`;
  - se cargan todos los ejercicios; el cuadre hace falta en los meses que siguen abiertos, y la migración no termina con
    diferencias sin decidir en ellos.

## 8. Avisos y pantallas

- **Fiscal → SII** (`/fiscal/sii`):
  - por enviar, para corregir, enviadas y todo;
  - tarjetas con lo que vence y lo vencido;
  - detalle con el contenido, el desglose y la respuesta;
  - configuración del envío.
  - Con `?ejercicio=&periodo=`, solo ese mes (desde el 303).
- **Factura y asiento:** franja con el estado SII y «Enviar»; el editor avisa de que guardar algo enviado manda la
  modificación.
- **Inicio:** fuera de plazo (rojo), lo que vence hoy o el siguiente día hábil y lo que hay que corregir.
- **303:** las facturas del periodo sin enviar o por corregir, con enlace.
- **Ficha del tercero:**
  - las facturas enviadas con la identificación anterior en meses con el IVA cerrado;
  - el resultado del censo.
- **Consola de Enumbers:** el sistema de facturación por tramos (ADR-0055).

## 9. Pendiente (H-089)

- **Cuadre de la migración** de los cuatro clientes con SII (0054, 0111, 0122, 0124): la carga ya trae `pressii` (§ 7 bis);
  falta hacerlo con el certificado de cada cliente en el modo sombra.
- **Bienes de inversión y cobros en metálico** (fase 3, anuales).
- **Inmuebles** (claves 12 y 13 con `DatosInmueble`): solo si alguno de los cuatro factura alquileres.
- **SII del IGIC** (ATC): sin clientes canarios en el SII; cuando haya uno.
- **Festivos nacionales de 2028.**
