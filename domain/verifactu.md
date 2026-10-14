# VeriFactu en ActivoPro

Normativa: RD 1007/2023 (sistemas informáticos de facturación). Modo VERI*FACTU: envío a la
AEAT; autenticación con certificado en la conexión (sin firma XAdES de cada registro).

## Reglas de negocio confirmadas

- **TipoFactura:** `F1` normal; `F2` simplificada cuando `FacCtaCod` = cuenta por defecto
  (`999999`); `R4` rectificativa normal y `R5` rectificativa simplificada cuando `FacNumRec > 0`.
- **Rectificativas = anulación en negativo.** Una rectificativa de ActivoPro es la misma factura
  en negativo (fac 25 = 100 → R 25 = −100) y anula totalmente la original; si hace falta, se
  emite después una factura nueva. Para la AEAT es una rectificativa **por diferencias**
  (`TipoRectificativa = I`), sin `ImporteRectificacion`, con `FacturasRectificadas` (la
  original). Nunca `FacturasSustituidas` (solo F3; con R4 da el error AEAT 1116). GeneXus manda
  `S` y el micro la declara `I` (ADR-0010).
- **F2 y R5 no llevan `Destinatarios`** aunque GeneXus envíe el cliente (error AEAT 1190).
- Una factura enviada a VeriFactu (aceptada o rechazada) **no se edita** en ActivoPro: se anula
  con una rectificativa y, si procede, se hace una nueva.
- En producción las rectificativas solo son por anulación e incluyen fecha de la rectificada y
  de operación. Numeración por ejercicio y serie, sin duplicados.
- **Cadena de huellas:** un registro rechazado sigue siendo eslabón de la cadena; no se limpia
  su huella. La subsanación es un registro nuevo al final de la cadena. Nunca se modifica la
  cadena retroactivamente.
- Los **albaranes no llevan huella**. Una factura generada desde albarán se envía una sola vez.
- Filtro de impuestos: `FacImpCod = 'I'` en los `for each` sobre `facturasfacimp`.
- Las **simplificadas** tienen serie propia: parámetro de empresa `SERSIMPL` en la tabla
  `pdefecto` ("Serie Simplificada para Verifactu", p. ej. `SIM`). No usan la serie de `VENTA`
  ni la concatenan. Si está vacío y la empresa tiene VeriFactu (`S1`/`S2`), se muestra un aviso
  y no se factura; no se autogenera. En la facturación por lotes desde presupuestos
  (`Fact_Presupuestor`) se bloquea toda la tanda si hay algún no cliente y falta la serie.
  Cuenta genérica de cliente: `4300` / `999999` (`CGENFAC`).
- Numeración por serie y ejercicio (`NumSerie`: `EmpCod + EjerCod + NumSerTip + NumSerPre`).
  Reiniciar cada ejercicio es válido; la cadena VeriFactu sí continúa entre ejercicios.
- Interruptor por empresa `MSVERACT` (`S` micro / `N` GeneXus nativo).
- **Pendiente:** usar `FacFec` y no `FacMod` como fecha de expedición, tanto en
  `FacturaEmitidaVeri` como en el micro.

Historia completa: `verifactu-evolucion.md`.

## Validado en preproducción AEAT

Con el micro 1.0.0 (14/10/2026): F1, F2 (sin destinatario), R4 y R5 por diferencias con
`FacturasRectificadas`, operaciones exentas (`E6`), acentos y escapado XML (`&`, apóstrofos,
`·`), importes con decimales, reenvío de un rechazado (alta por rechazo) y encadenamiento en
MySQL. Antes: factura desde albarán sin doble envío y reenvío manual con `SendVerifactu`.
Pendiente: factura con IRPF.

## Caminos de facturación válidos

Solo dos caminos generan facturas que se envían a VeriFactu: **Facturar desde la bandeja de
albaranes** (`Alba_factura16`) y **Facturar desde la bandeja de presupuestos**
(`Fact_Presupuestor`). El combo Facturar = Sí de la pantalla Albarán creaba facturas que no
llegaban a VeriFactu y se ha deshabilitado (ADR-0009).

Las facturas creadas con ese combo no afectan a VeriFactu: el único cliente con VeriFactu no
lo usa.

## Tabla `verifactu_registro` (en cada schema de tenant)

Tabla propia del micro, separada de `facturas`, para que el micro y GeneXus no escriban en la
misma tabla. Es la fuente de verdad de la cadena de huellas.

| Campo | Tipo | Notas |
|---|---|---|
| `id` | bigint PK auto_increment | |
| `emp_cod` | smallint | Empresa dentro del schema |
| `nif_emisor` | varchar(20), indexado | La cadena va por NIF |
| `serie` | varchar(3) | |
| `numero` | int | |
| `fecha` | date | |
| `tipo_factura` | varchar(2) | F1, F2, R4, R5… |
| `hash_data` | varchar(1000) | Cadena usada para calcular la huella |
| `hash_code` | varchar(64) | Huella SHA-256 |
| `csv` | varchar(20) | CSV devuelto por la AEAT |
| `qr_url` | varchar(500) | |
| `estado` | varchar(20), por defecto `pendiente` | `pendiente`, `aceptado`, `aceptado_con_errores`, `rechazado` |
| `error_codigo` / `error_desc` | int / varchar(500) | |
| `intentos` | tinyint, por defecto 0 | |
| `subsanacion` | char(1), por defecto `N` | `S` = reenvío de una factura rechazada (alta por rechazo) |
| `sif_version` | varchar(20) | Versión del micro que generó el registro (ADR-0007) |
| `xml_registro` | mediumtext | XML exacto del registro, para reenviar un pendiente sin recalcular |
| `created_at` / `updated_at` | datetime | |

Índices: `idx_nif_emisor` e `idx_factura` (NIF, serie, número, fecha), **no único**: una factura
puede tener varios registros (el rechazado y su alta por rechazo). La unicidad la controla el
micro. Scripts en `sql/mysql/` del micro (001 crea la tabla completa; 002, 004 y 005 actualizan
schemas antiguos).

## Contrato con GeneXus y gestión de fallos (ADR-0011)

GeneXus llama a `VF_EnviarMS_Caller` después del commit de `ContaFacVen` y **solo sabe
reenviar**. El micro guarda cada registro como `pendiente` (con su XML) antes de enviarlo,
envía con un único intento y actualiza el estado; los pendientes anteriores del mismo NIF se
reenvían en orden con la siguiente factura. Un reenvío nunca duplica (idempotencia por NIF +
serie + número + fecha + tipo). Bloqueo por NIF (`GET_LOCK`) para que dos facturas del mismo
emisor no se encadenen a la vez.

Respuesta en XML (`Estado` `C`/`E` y `Error/Codigo`):

| Respuesta | Significado | GeneXus |
|---|---|---|
| `C` | Registrada por la AEAT | Nada |
| `C` + `Tipo = aviso` | Aceptada con errores (avisos) | Nada; **no** reenviar |
| `E` + `9001` | Sin acceso a la cadena en MySQL; no se ha enviado | Reenviar |
| `E` + `9002` | Cadena del emisor ocupada; no se ha enviado | Reenviar |
| `E` + `9003` | Registrada en la cadena y pendiente de envío (huella y QR válidos) | Reenviar o esperar a la siguiente factura |
| `E` + `Tipo = datos` | Rechazada por la AEAT (su código) o datos incoherentes (`0000`) | Corregir; reenviar igual vuelve a fallar |

`9001`–`9003` son códigos internos del micro; la AEAT no los usa.

## Rechazos, alta por rechazo y duplicados

- Un registro **rechazado** sigue siendo eslabón de la cadena. La AEAT no tiene esa factura.
- Reenviar una factura rechazada genera un registro nuevo al final de la cadena: es un **alta
  por rechazo** (espec. AEAT de servicios web, 9.1.3) y lleva `Subsanacion = S` +
  `RechazoPrevio = X`. No cambia la factura de ActivoPro, solo el registro (p. ej. cuando el
  fallo era del micro). La "subsanación" de un registro ya aceptado (`RechazoPrevio = N`) no
  se usa en ActivoPro.
- Si la AEAT responde que el registro está **duplicado** (devuelve `EstadoRegistroDuplicado`),
  significa que ya lo tenía: el micro guarda el estado que tenía (`aceptado` o
  `aceptado_con_errores`). Código de duplicado exacto pendiente de confirmar en el documento
  de validaciones (se usa `3000` como respaldo).
- El micro solo conoce los rechazos que constan en `verifactu_registro`: los de antes del micro
  se reenviarían como alta inicial.

## Activar VeriFactu en un cliente

1. En su schema: `sql/mysql/001_verifactu_registro.sql` del micro y `GRANT` al usuario del
   micro.
2. **Cliente nuevo en VeriFactu:** nada más. Con `verifactu_registro` vacía para su NIF, el micro
   envía `hashAnterior` vacío, que es lo que la AEAT espera en el primer registro de una cadena.
3. **Cliente que ya ha enviado facturas a la AEAT** (pasa del flujo nativo al micro): sembrar
   `verifactu_registro` con la última factura aceptada (`FacHashCode` de la última con
   `FacIdSIF = 'A1'`). Sin semilla, la AEAT responde con error 2007. Es el mismo proceso que se
   hizo en preproducción.
4. Cambiar `MSVERACT` a `S` para esa empresa.

La cadena va por NIF emisor: en schemas con varias `EmpCod`, la semilla se hace por cada NIF.

## Pendiente

- Flujo **nativo** de GeneXus (`FacturaEmitidaVeri`, `MSVERACT = N`): sigue declarando las
  rectificativas como `S` con la base rectificada en negativo. El cliente en producción no ha
  emitido ninguna; resolverlo o pasar el cliente al micro antes de que emita una.
- Issues del micro: #8 (que una caída de Supabase no pare la facturación), #27 (reintentar
  pendientes sin petición de GeneXus), #19 (rellenar huecos de la copia en Supabase).

## Arquitectura

ms-verifactu es el SIF de ActivoPro y escribe el resultado en MySQL (ADR-0004). Versionado
del SIF: ADR-0007. Detalle técnico y estado en el `CLAUDE.md` y los issues de ms-verifactu.

## Entornos (decisión del 14/10/2026)

- **Aislamiento por máquina:** las pruebas se hacen en local (micro + MySQL de pruebas en el
  equipo de desarrollo) y producción en Oxygen. `MSVERURL = http://127.0.0.1:3003` en ambos:
  cada GeneXus llama al micro de su propia máquina. El micro no se expone a Internet (el
  certificado del cliente y su contraseña viajan en cada petición).
- **Endpoint de la AEAT y URL del QR por `AEAT_ENV`** (`pre` en local, `pro` en Oxygen),
  nunca desde Supabase. `AEAT_ENV` es obligatorio: sin él el micro no arranca.
- **Supabase es una copia para el monitor, nunca una dependencia.** MySQL es la fuente de
  verdad; Supabase recibe una copia de cada registro con su `entorno`, y el monitor separa
  pruebas de producción. Rellenar huecos de la copia desde MySQL queda para más adelante.
- Logs del micro: una línea por factura (`[factura]`), por respuesta de la AEAT (`[aeat]`) y por
  petición rechazada (`[peticion]`); el XML completo solo con `LOG_XML=1`.
- **Antes de producción** se borran las trazas de pruebas de Supabase y la cadena de
  `mconta0048`.
