# VeriFactu en ActivoPro

Normativa: RD 1007/2023 (sistemas informáticos de facturación). Modo VERI*FACTU: envío a la
AEAT; autenticación con certificado en la conexión (sin firma XAdES de cada registro).

## Reglas de negocio confirmadas

- **TipoFactura:** `F1` normal; `F2` simplificada cuando `FacCtaCod` = cuenta por defecto
  (`999999`); `R4` rectificativa normal y `R5` rectificativa simplificada cuando `FacNumRec > 0`.
- Todas las rectificativas de ActivoPro son **por sustitución** (`TipoRectificativa = S`).
  R4 y R5 llevan `ImporteRectificacion` y `FacturasRectificadas`, **no** `FacturasSustituidas`
  (este último solo con F3; enviarlo con R4 provoca el error AEAT 1116).
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

F1, F2, R4, R5, encadenamiento en MySQL, factura desde albarán sin doble envío, reenvío manual
con botón `SendVerifactu`.

## Caminos de facturación válidos

Solo dos caminos generan facturas que se envían a VeriFactu: **Facturar desde la bandeja de
albaranes** (`Alba_factura16`) y **Facturar desde la bandeja de presupuestos**
(`Fact_Presupuestor`). El combo Facturar = Sí de la pantalla Albarán creaba facturas que no
llegaban a VeriFactu y se ha deshabilitado (ADR-0009).

**Pendiente:** buscar en los tenants facturas creadas con ese combo antes de deshabilitarlo. Son
albaranes en estado B cuyo `FacAsi` apunta a una copia de presupuesto en estado K o L, y no
están registradas en VeriFactu.

## Activar VeriFactu en un cliente

1. Ejecutar el script de migración en su schema: `ALTER TABLE` de las columnas, `CREATE TABLE
   verifactu_registro` y `GRANT` al usuario del micro.
2. **Cliente nuevo en VeriFactu:** nada más. Con `verifactu_registro` vacía para su NIF, el micro
   envía `hashAnterior` vacío, que es lo que la AEAT espera en el primer registro de una cadena.
3. **Cliente que ya ha enviado facturas a la AEAT** (pasa del flujo nativo al micro): sembrar
   `verifactu_registro` con la última factura aceptada (`FacHashCode` de la última con
   `FacIdSIF = 'A1'`). Sin semilla, la AEAT responde con error 2007. Es el mismo proceso que se
   hizo en preproducción.
4. Cambiar `MSVERACT` a `S` para esa empresa.

La cadena va por NIF emisor: en schemas con varias `EmpCod`, la semilla se hace por cada NIF.

## Arquitectura

ms-verifactu es el SIF de ActivoPro y escribe el resultado en MySQL (ADR-0004). Antes de
producción falta el versionado del SIF (ADR-0007). Detalle técnico en el `CLAUDE.md` de
ms-verifactu.
