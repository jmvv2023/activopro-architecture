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

- **Servicio** `VNifV2` de la AEAT (NIF + nombre):
  - `Identificado`, `No identificado`, `No identificado-similar`, `Identificado-Baja`, `Identificado-Revocado`;
  - hasta 10.000 por petición;
  - con el certificado de la empresa.
  - Solo para cumplir obligaciones tributarias: se comprueba una vez por NIF y cuando cambia.
- **Cuándo.** Terceros con NIF español de una empresa con certificado vigente:
  - al darlos de alta o cambiar el NIF o el nombre;
  - desde la ficha («Comprobar en la AEAT»);
  - al emitir o registrar con uno nunca comprobado.

  Trabajo `censo.comprobar` por empresa, en lote.
- **Resultado** en el tercero (estado, NIF y nombre comprobados, fecha). Si cambia el NIF o el nombre, está desfasado.
- **Avisos:**
  - en la ficha y en «por revisar»;
  - al emitir (SII o VeriFactu) o registrar una recibida en el SII con un tercero no identificado, de baja o revocado,
    hay que aceptar el aviso para seguir (`CENSO_NIF_NO_IDENTIFICADO`). No bloquea: el censo puede ir por detrás.
- **Sin entorno de pruebas en la AEAT:**
  - solo con `AEAT_CENSO=pro`;
  - en pruebas queda «sin comprobar»;
  - los tests usan un simulador.

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

- **Cargar del programa anterior lo ya enviado (`pressii`).** Imprescindible antes de migrar los cuatro clientes con
  SII (0054, 0111, 0122, 0124): que conste como registrado para que lo siguiente sea `A1` y no un alta duplicada.
- **Consulta y cuadre** con la AEAT (fase 2): lo que tiene la AEAT frente a la plataforma y el contraste con la otra parte.
- **Bienes de inversión y cobros en metálico** (fase 3, anuales).
- **Inmuebles** (claves 12 y 13 con `DatosInmueble`): solo si alguno de los cuatro factura alquileres.
- **SII del IGIC** (ATC): sin clientes canarios en el SII; cuando haya uno.
- **Festivos nacionales de 2028.**
