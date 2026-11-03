---
id: 0018
title: Modelo de datos contable de la plataforma nueva (ola 1)
status: proposed
date: 2026-11-03
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

La ola 1 (ADR-0016) migra a los clientes que usan contabilidad sin facturación. El modelo contable es la base de todo lo demás (IVA, cartera, inmovilizado, conciliación, informes). Hechos del sistema actual, confirmados con datos (`analysis/legacy/2026-11-modelo-datos-tenant.md`):

- **Plan de cuentas por empresa**, elegido de un catálogo (pymes, sociedades…) al dar de alta la empresa y ampliable.
  - Títulos de 3 o 4 dígitos y subcuentas de título + 6 dígitos (9 o 10 dígitos en total).
  - Las cuentas de terceros son `4300`/`4000`/`4100` + código de 6 dígitos; en pantalla, el usuario ve el código de 6 dígitos del tercero.
- **No hay cabecera de asiento.** Cada apunte va a un solo lado (debe o haber) y todas las líneas de un asiento tienen la misma fecha.
- **5 asientos descuadrados** en mconta0037 (de 239.629).
- Las facturas y los cobros generan su asiento automáticamente, y **si se modifica la factura se actualiza el asiento**.
- **Cierre por mes y cierre de IVA por mes o trimestre.** Al cerrar el IVA se genera el fichero del 303 y queda cerrado el periodo; se puede reabrir para incorporar algo y volver a cerrar.
- `MovDiario` clasifica el origen del asiento (unos 25 valores).

## Decisión

### Entidades

| Entidad | Ámbito | Contenido |
|---|---|---|
| `plan_modelo` | Global | Planes del catálogo (PGC general, pymes…) con sus títulos |
| `cuenta` | Empresa | Título padre, subcuenta (6 dígitos), código completo, nombre, imputable sí/no, tercero asociado, activa |
| `ejercicio` | Empresa | Fechas de inicio y fin, estado, plan |
| `periodo` | Ejercicio × mes | Cerrado contable, cerrado IVA; cada cierre y reapertura auditado |
| `diario` | Global | Catálogo de tipos de asiento (lista a extraer de la KB) |
| `asiento` | Empresa | Ejercicio, número, fecha, diario, concepto, origen (manual, factura, cobro, amortización, apertura, cierre, regularización…) y referencia al documento de origen |
| `apunte` | Asiento | Línea, cuenta, lado (debe/haber), importe, concepto, documento, divisa |
| `registro_iva` | Apunte | Tipo (repercutido/soportado), clase, base, porcentaje, cuota, deducibilidad, clave de operación, país |
| `retencion` | Apunte | IRPF: clave, base, porcentaje, cuota |
| `declaracion` | Empresa × modelo × periodo | Estado (generada, presentada, reabierta), fichero, histórico de reaperturas |
| `saldo_mensual` | Cuenta × mes | Debe y haber acumulados; derivado |

### Reglas en la base de datos

- Un apunte tiene un solo lado. Se admite importe 0 (líneas que soportan registro de IVA con cuota 0).
- **Un asiento cuadra** (Σ debe = Σ haber), comprobado al commit.
  - Excepción: asientos migrados con descuadre heredado, marcados como tales; nunca para asientos nuevos o modificados.
- No se crean ni modifican asientos en periodos cerrados ni en ejercicios cerrados; desbloqueo solo explícito y auditado (ADR-0013, punto 11).
- `saldo_mensual` se actualiza en la misma transacción que los apuntes y se puede recalcular por empresa y ejercicio.

### Asientos automáticos

- El asiento generado por un documento (factura, cobro, amortización…) **pertenece al documento**: si el documento cambia, el asiento se regenera.
- No se edita a mano: los cambios se hacen en el documento. Así asiento y documento no pueden divergir.
- Si el periodo del asiento está cerrado, el documento no se puede modificar sin reabrir el periodo.

### Códigos de cuenta

- Se guarda el código completo (título + subcuenta) para ordenar y filtrar por prefijo (grupos, rangos en informes).
- La interfaz muestra y acepta el código como lo usa hoy cada pantalla (por ejemplo, el código de 6 dígitos del tercero).

## Migración

- **Títulos y subcuentas** de `tctactble` → `cuenta`. El plan modelo se identifica comparando con `defctactable`.
- **Asientos**: cabecera derivada de las líneas de `movctas` con el mismo ejercicio y `MovId`; fecha y diario comunes.
- **IVA e IRPF**: `movctaslevel1` y `movctaslevel2` → `registro_iva` y `retencion`.
- **Periodos**: `paramejerlevel1` → `periodo`.
- **Origen de cada asiento** (factura, cobro…): se deriva del diario y de los vínculos de los documentos. En la ola 1 no hay facturación, así que la mayoría serán manuales o de cartera.
- **Paridad**: `saldo_mensual` recalculado frente a `saldoslevel1`, por empresa, cuenta y mes.

## Consecuencias

- El asiento pasa a ser una entidad con cabecera y origen: se puede navegar de asiento a documento y viceversa.
- Las reglas de cuadre y de periodos cerrados pasan de la aplicación a la base de datos.

## Pendiente (KB)

- Catálogo de diarios: significado de cada valor de `MovDiario`.
- Significado de `MovCab`.
- Reglas de cierre, apertura y regularización de PyG; cierre mensual y de IVA.
- Si el usuario puede hoy editar a mano un asiento automático. Si es así, cómo se trata al migrar.

## Origen

Conversación con José María del 03/11/2026 y comprobaciones sobre mconta0037.
