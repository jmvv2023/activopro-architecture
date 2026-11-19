---
id: 0055
title: VeriFactu y SII como tramos sucesivos de la empresa, cambiados solo por Enumbers, con fecha de inicio de periodo de liquidación y sin registros en curso
status: proposed
date: 2026-11-19
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Una empresa que lleva los libros por el SII queda fuera del reglamento de sistemas de facturación (RD 1007/2023): no envía
registros a VeriFactu ni imprime el QR. Se entra en el SII por REDEME, por volumen de operaciones o por opción voluntaria (036),
con efecto desde el periodo de liquidación siguiente; quien entra a mitad de año deja de enviar a VeriFactu desde ese momento, sin
esperar al final del año (preguntas frecuentes de la AEAT). Se sale por baja en REDEME, renuncia o al dejar de ser gran empresa,
y entonces vuelve a aplicarle el reglamento.

En la plataforma, VeriFactu (`empresa_config_fiscal.verifactu_desde`, ADR-0046) y el SII (`sii`, `sii_desde`, ADR-0053) son dos
marcas independientes que se excluyen (`VERIFACTU_CON_SII`, `SII_CON_VERIFACTU`) y no tienen fecha de fin: una empresa con
VeriFactu no puede pasar al SII ni volver. VeriFactu lo activa el administrador de la empresa en Datos de la empresa.

Es un cambio delicado: cortado sin reglas deja registros a medias, rechazados sin camino de subsanación o facturas de un mismo
periodo en dos sistemas.

## Opciones consideradas

1. **Fecha de fin en cada marca** (`verifactu_hasta`, `sii_hasta`). Barata, pero no aguanta un segundo cambio (ir y volver).
2. **Tramos sucesivos en una tabla**, como los regímenes especiales, con reglas fijas de cuándo y cómo se cambia.
3. **Permitir el cambio en cualquier fecha** y resolver los casos al vuelo. Más flexible para el cliente y la vía segura a
   contenidos inconsistentes.

## Decisión

Opción 2, con reglas cerradas: si son claras, el sistema las aplica y no hay discusión.

- **Tramos** en `empresa_sistema_facturacion` (sistema `verifactu` / `sii`, desde, hasta; sin solapes; sin tramo = ninguno). La
  aplicación solo lee. `app.verifactu_activo(empresa, fecha)` y `app.sii_activo(empresa, fecha)` salen de ahí. `verifactu_desde`,
  `sii` y `sii_desde` pasan a la tabla.
- **Solo Enumbers**, desde la consola, con motivo, también el primer alta en VeriFactu. En Datos de la empresa el cliente ve su
  sistema y el cambio programado, sin poder tocarlo.
- **Cuándo**: el día 1 de un periodo de liquidación futuro de la empresa (trimestral: 1 de enero, abril, julio u octubre; mensual:
  el 1 de cualquier mes), nunca hoy ni hacia atrás. Así un periodo nunca queda en dos sistemas y el corte cae donde la AEAT pone
  el efecto. El cambio se programa antes y entra solo en esa fecha; se puede cancelar antes, con motivo. Pasar al SII deja el 303
  mensual desde esa fecha (la periodicidad «Mensual: SII» de la consola, que ya existe).
- **Sin registros en curso**: no se programa si el sistema que se deja tiene registros pendientes o enviándose
  (`CAMBIO_SISTEMA_EN_PROCESO`); se espera a que terminen.
- **Advertencia que se acepta**: los rechazados o con errores del sistema que se deja se listan y hay que aceptarlos para
  programar el cambio; queda en `plataforma_evento` con la lista. Desde la fecha:
  - **VeriFactu** es un registro al expedir: las facturas de su tramo que aún estén pendientes al llegar la fecha se envían
    (son de su periodo), pero un rechazado ya no se subsana por VeriFactu (`VERIFACTU_FINALIZADO`).
  - **SII** son los libros de un periodo: lo de su tramo se sigue enviando y corrigiendo (A1, baja) por la fecha del registro,
    como hoy hace `app.sii_activo`.
- **La cadena de VeriFactu sigue**: al volver, el primer registro encadena con el último eslabón del NIF guardado en la base.
- Las facturas expedidas desde la fecha del cambio no generan registro ni llevan QR si el tramo es SII, y entran en el SII; al
  revés, lo mismo.

## Consecuencias

- Una empresa puede ir y volver tantas veces como cambie su situación fiscal, sin periodos mezclados ni registros cortados.
- El cliente que quiere cambiar lo pide y se le dice desde qué fecha puede ser; no hay cambios inmediatos.
- Por hacer: migración de los datos actuales a tramos; trigger `factura_verifactu`, PDF (QR) y `app.reenviar_registro` por
  tramo; `app.contenido_sii` / sincronización por tramo; función de la consola para programar y cancelar, con la comprobación de
  registros en curso y la lista de rechazados; pantalla en la consola y estado en Datos de la empresa; manual.
- Riesgo asumido: un rechazado que no se subsanó antes del cambio queda sin subsanar por VeriFactu; se acepta de forma expresa.

## Origen

Conversación con José María, 19/11/2026: «una empresa con VeriFactu puede decidir pasar a SII…» y «si las reglas son claras no es
un problema; los problemas vienen cuando, queriendo permitir todo, terminamos con contenidos inconsistentes».
