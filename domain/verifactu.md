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

## Validado en preproducción AEAT

F1, F2, R4, R5, encadenamiento en MySQL, factura desde albarán sin doble envío, reenvío manual
con botón `SendVerifactu`.

## Gap conocido

Presupuesto aceptado que termina en albaranes y se factura por el camino Aceptado + Facturar = Sí
**no** se envía a VeriFactu. El camino albarán → Facturar sí funciona (ver notas de presupuestos
en el repo GeneXus / issue correspondiente).

## Arquitectura

Ver ADR-0004 (conflicto pendiente) y el `CLAUDE.md` de ms-verifactu.
