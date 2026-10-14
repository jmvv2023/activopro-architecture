# Evolución de VeriFactu en ActivoPro

Por qué el SIF es como es. Leer antes de proponer cambios de arquitectura en VeriFactu: varias
ideas "obvias" ya se probaron y se descartaron.

## Fase 0 — VeriFactu nativo en GeneXus (en producción)

- Flujo síncrono dentro del `Save()` de la factura: `facvtapro_bc.Save()` → `CalcFacVen2` →
  `ContaFacVen` → `FacturaEmitidaVeri`, que construye el registro y lo envía a la AEAT.
- Escribe en las columnas `Fac*` de `facturas`: `FacHashData`, `FacHashCode`, `FacIdSIF`,
  `FacQR`, `FacVeriCSV`, `FacVeriEst`, `FacVeriErrCod`.
- May 2026: corregido el error AEAT 1116 en rectificativas (`FacturasSustituidas` →
  `FacturasRectificadas`), versión 1.0.0.0 → 1.0.1.1.

## Fase 1 — Primer micro (hasta mediados de sep 2026)

- Tres piezas: `ms-certificados`, `ms-verifactu`, `ms-verifactu-web` (desplegado en Fly),
  con Supabase.
- Interruptor por empresa: parámetro **`MSVERACT`** (`S` = flujo micro, `N` = flujo GeneXus).
  Se lee en `ContaFacVen`; con `N` el flujo es el nativo sin cambios. El interruptor vive en
  GeneXus: el micro no lo comprueba si se le llama directamente.
- Añadió 11 columnas `msFacVeri*` a `facturas`, varias duplicando a las `Fac*`.
- F1 y R4 aceptadas en preproducción.

## Fase 2 — Micro aparcado (19–21/09/2026)

Un error al generar una factura simplificada destapó problemas de fondo:

- **Desfase de esquema:** `facturas` tenía 82 columnas en la KB y 93 en las BDs reales. Desplegar
  código con columnas que no existen en todos los schemas habría bloqueado la facturación de
  todos los clientes.
- **Estado duplicado** entre columnas `Fac*` y `msFacVeri*`, sin fuente de verdad clara, y dos
  sistemas escribiendo por SQL directo en la misma tabla.
- **Fecha de expedición:** tanto `FacturaEmitidaVeri` (GeneXus) como el micro usan `FacMod`
  (última modificación) en vez de `FacFec` para `FechaExpedicionFactura`, encadenamiento y
  `FechaHoraHusoGenRegistro`. Bajo riesgo hoy porque las facturas VeriFactu son inmutables tras el
  alta, pero inconsistente. **Pendiente para la siguiente fase.**
- Falta de contrato claro entre GeneXus y el micro.

**Decisión de José María:** trabajar con el VeriFactu nativo de GeneXus, ampliándolo solo para
enviar simplificadas, y retomar el micro más adelante. El micro se retiró de Fly y quedó solo en
Docker local.

En esa misma fase se resolvió la **serie propia de simplificadas** (parámetro `SERSIMPL`),
validada en 5 escenarios. Las simplificadas no usan la serie de `VENTA` ni la concatenan.

## Fase 3 — Micro rediseñado (desde el 29/09/2026)

- El micro pasa a ser el **único SIF**: GeneXus envía los datos brutos tras el commit de
  `ContaFacVen` (`VF_EnviarMS_Caller`) y muestra el resultado.
- La intención era que GeneXus escribiera la respuesta en MySQL, pero no fue capaz de gestionarla
  (GX16 sin `JsonReader`, conflictos con `Commit on exit`). Por eso **el micro escribe en
  MySQL**. Primera versión aceptada (ADR-0004).
- Supabase deja de ser fuente de verdad de la cadena (pasa a MySQL), pero **se mantiene** para
  el Rule Store, los lotes y la trazabilidad que alimenta el monitor. Se llegó a plantear
  eliminarlo; el 13/10/2026 se decidió conservarlo por transversalidad con el nuevo ActivoPro.
- Certificado en el payload: `ms-certificados` fuera de la ruta crítica.
- Despliegue previsto en Oxygen, junto a GeneXus. Fly descartado.
- Respuesta a GeneXus en XML. Cadena de huellas en `verifactu_registro`.
- Se eliminan columnas duplicadas (`msFacVeriCSV`, `msFacVeriEst`, `msFacVeriHash`): los
  resultados convergen en las columnas `Fac*`, y las `msFacVeri*` restantes son de
  orquestación (pendiente, intentos, último envío, lote, error detallado, QR).
- F1, F2, R4 y R5 validadas en preproducción.
- Antes de producción: versionado del SIF (ADR-0007).

## Fase 4 — Micro 1.0.0, preparación para producción (13–15/10/2026)

- **Decisiones:**
  - Tabla propia `verifactu_registro`.
  - Supabase como copia del monitor, con columna `entorno`.
  - `AEAT_ENV` obligatorio para fijar endpoint y QR.
  - Aislamiento por máquina: pruebas en local y producción en Oxygen.
  - SemVer (ADR-0007).
  - El micro resuelve los fallos y GeneXus solo reenvía (ADR-0011).
- **Errores encontrados al probar en preproducción** y corregidos:
  - `&ImporteTotal`/`&CuotaTotal` eran variables enteras en GeneXus y truncaban los totales.
    El micro ahora valida que el desglose cuadre con los totales.
  - Acentos rotos: GeneXus envía ISO-8859-1/CP1252. Se añadió un parser propio.
  - Una `INTERNAL_API_KEY` errónea daba 401 silenciosos. Se añadieron logs por petición y el
    motivo en la respuesta.
  - F2/R5 con destinatario: error AEAT 1190.
  - La clave única `uk_factura` impedía guardar el reenvío de un rechazado.
  - Faltaban las marcas de alta por rechazo (`Subsanacion`/`RechazoPrevio`) y la detección de
    duplicados por `EstadoRegistroDuplicado`.
  - Rectificativas declaradas `S` en negativo y sin `FacturasRectificadas` (ADR-0010).

## Lecciones

1. Toda columna nueva en una tabla del núcleo exige el `ALTER` en todos los schemas **antes** de
   desplegar el código GeneXus que la usa.
2. Un solo dueño por dato: evitar que dos sistemas mantengan el mismo estado en columnas distintas.
3. El interruptor por empresa (`MSVERACT`) permite convivir y volver atrás. Mantenerlo hasta
   que el micro esté estable en producción.
4. Que la AEAT acepte un registro no quiere decir que sea correcto: no valida el signo ni la
   coherencia entre los tipos de rectificativa. Hay que contrastar con la especificación, no
   solo con preproducción.
5. Cuando un valor no se puede verificar en una fuente oficial (p. ej. el código de duplicado),
   se detecta por la estructura de la respuesta y el valor queda solo como respaldo.
