---
id: 0044
title: Configuración fiscal y contable de la empresa — lo que se trae de GeneXus y dónde vive
status: proposed
date: 2026-11-15
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

La ficha de empresa de GeneXus (`empresas`, transacción `TEmpresas`) tiene unos 90 atributos. La plataforma, hasta ahora, tiene:

- en `empresa`: nombre, NIF, territorio, plan modelo, y el domicilio y el contacto (ADR-0043, fase 2);
- en `empresa_config_fiscal`: persona física (sí/no), apellidos y nombre, cuentas de liquidación, devolución mensual, SII, marca del 347,
  clase de exentas y suplidos;
- en `empresa_regimen_deduccion`: total, prorrata general o prorrata especial, con vigencias;
- actividades (IAE y CNAE), representantes, y las configuraciones contable, de tesorería y de almacén.

Los valores de GeneXus, sacados de los combos de `TEmpresas` y del código:

| Atributo | Valores | Uso en el código de GeneXus |
|---|---|---|
| `EmpGrpo` (clase) | 1 Impuesto de Sociedades, 2 Persona física, 3 Atribución de rentas, 4 Grupo de empresas (y una `F` de fundación en código antiguo) | 2: apellidos y nombre en los modelos. 3: el 390 lo trata como persona física y la liquidación exige un contacto firmante, como en el 2. El 4 no se usa en ningún sitio |
| `EmpRegIva` | 1 General, 2 Simplificado, 3 Minorista, 4 Agencia de viajes, 5 Bienes usados, 6 Prorrata, 7 Actividades diferenciadas | 6: prorrata (ya cargada). 3 con persona física: recargo de equivalencia |
| `EmpBalance`, `EmpPerGan` | 1 Normal, 2 Pymes, 3 Abreviado | Modelo de las cuentas anuales |
| `EmpMemo` | 1 Normal, 2 Abreviada | Ídem |
| `EmpIvaDif` | S/N | IVA a la importación diferido ([77] del 303) |
| `EmpCCCPagos`, `EmpCCCDev` | CCC de 20 cifras | Cuenta de domiciliación y de devolución de Hacienda |
| `EmpRegMer` | texto | Registro mercantil |

Hoy hay datos que se escriben a mano en cada declaración: el IBAN del 303 y la persona de contacto del 347. Y hay casos que la
plataforma no distingue: una comunidad de bienes, un minorista en recargo de equivalencia (no presenta el 303 por esa actividad) o una
empresa en un régimen especial que los modelos no soportan.

## Opciones consideradas

1. **Copiar la ficha de GeneXus tal cual.** Rápido de cargar, pero arrastra interruptores de pantallas (previsión de cobros y pagos,
   contactos, centros), datos que ningún modelo pide (delegación de Hacienda) y secretos en claro (usuario y contraseña del SMTP).
2. **Traer solo lo que algo de la plataforma usa, cada dato donde se usa, y lo demás con su módulo.** Cada atributo tiene un dueño y
   una regla. Obliga a revisar la lista entera una vez (este ADR).

## Decisión

Opción 2. El reparto:

### Ahora

- **Tipo de entidad** en `empresa_config_fiscal.tipo_entidad`: `sociedad`, `persona_fisica`, `atribucion_rentas`, `entidad_sin_lucro`.
  Sustituye al sí/no de persona física (que queda como columna calculada para no romper lo que la usa). De él dependen:
  - la aplicación del resultado: la persona física va a la 550 (ya está), la atribución de rentas reparte entre los comuneros y no va a
    reservas;
  - los datos del declarante de los modelos (apellidos y nombre; contacto firmante en persona física y atribución, como GeneXus);
  - más adelante, los modelos de IRPF o IS que correspondan.

  «Grupo de empresas» no es un tipo de entidad sino una relación (grupo de IVA, consolidación del IS) y GeneXus no la usa: queda fuera
  hasta que haga falta. ETL: 1 → sociedad, 2 → persona física, 3 → atribución, 4 → sociedad con anomalía, F → entidad sin lucro.
- **Regímenes especiales de IVA / IGIC** en `empresa_regimen_especial` (régimen, desde, hasta; varios a la vez): simplificado,
  recargo de equivalencia, agencias de viaje, bienes usados, agricultura (REAGYP), criterio de caja. Los «sectores diferenciados» son un
  régimen de deducción: valor nuevo de `empresa_regimen_deduccion`. Regla: un modelo con un régimen que no soporta da error (como los
  tipos sin casilla, nunca una suposición). Una empresa que solo está en recargo de equivalencia no liquida: la puesta en marcha no le
  pide las cuentas de liquidación y la portada fiscal no le ofrece el 303. ETL: `EmpRegIva` 2, 3, 4, 5 y 7.
- **Cuentas de Hacienda**: `cuenta_domiciliacion_id` y `cuenta_devolucion_id` en `empresa_config_fiscal`, apuntando a cuentas de
  tesorería (IBAN validado). El cierre del 303 / 420 propone el IBAN según el resultado. ETL: el CCC de GeneXus pasado a IBAN y buscado
  entre las cuentas de tesorería; si no está, anomalía.
- **Contactos de la empresa** en `empresa_contacto` (cargo, nombre, NIF, móvil, teléfono, email), con uno marcado como «persona con
  quien relacionarse» para las cabeceras del 347, el 390 y el 349. Los representantes con firma siguen en `empresa_representante` (el
  390 pide su domicilio y datos del poder). ETL: `empresa_contacto` y `EmpCon1..3`.
- **Registro mercantil** y **móvil** en `empresa`. El registro mercantil sale en las facturas de una sociedad (art. 24 del Reglamento
  del Registro Mercantil).
- **IVA a la importación diferido**: marca con vigencias en `empresa_config_fiscal`. La [77] se calcula cuando se registren las
  importaciones del periodo (factura DUA, ADR-0030).
- **Identificador de acreedor SEPA**: sigue en la cuenta de tesorería; se propone calculado del NIF (ES + control + 000 + NIF).

### Con su módulo

| Dato de GeneXus | Módulo |
|---|---|
| Modelos de balance, pérdidas y ganancias y memoria; tamaño; auditoría y datos del auditor | Cuentas anuales e informes (ADR-0017) |
| Última contabilización de amortizaciones, última auditoría del inmovilizado | Inmovilizado |
| Logo, logo de carta, pies de factura | PDF de la factura |
| Centros y divisiones (S/N y códigos) | Analítica |

### No se traen

- **Divisa**: la contabilidad española es en euros; la divisa irá en la factura si llega.
- **Delegación, administración y código de Hacienda**: no los pide ningún diseño que se genere; la AEAT los deduce del domicilio.
- **Interruptores de pantalla** (previsión de pagos y cobros, contactos): en la plataforma son funciones del módulo contratado.
- **Numeración automática de terceros**: la plataforma siempre propone la siguiente subcuenta y deja cambiarla.
- **Servidor, usuario y contraseña de correo**: el correo es de la plataforma (H-032), y GeneXus los guarda en claro.

### Pantalla

Todo lo que es «Ahora» va en **Datos de la empresa** (ADR-0043): pestañas Identificación y domicilio, Fiscal (tipo de entidad,
regímenes, cuentas de Hacienda, diferimiento), Actividades, Representantes y contactos. Configurar es `empresa.configurar`.

## Consecuencias

- Cada dato de la ficha de GeneXus tiene un sitio decidido o una razón para no traerse.
- El IBAN del 303 y el contacto del 347 dejan de escribirse en cada declaración.
- Los regímenes especiales quedan registrados aunque la plataforma no los liquide: el error es explícito en vez de un modelo mal hecho.
- El ETL de la configuración fiscal crece (clase, régimen, CCC, contactos).
- Pendiente de comprobar con el diseño del 390: GeneXus marca la atribución de rentas como persona física; la plataforma no lo replica
  hasta confirmarlo.

## Pendiente

- Liquidar los regímenes especiales (simplificado, REAV, REBU, recargo con otras actividades): ADR propio cuando se aborde.
- IRPF e IS según el tipo de entidad: decidido no hacerlo por ahora (15/11/2026).

## Origen

Conversación con José María del 15/11/2026: los atributos de la ficha de empresa de GeneXus, y que la configuración de la empresa
vaya en un ADR propio para tener juntas todas sus decisiones. Los valores de `EmpGrpo` y `EmpRegIva`, de los combos de `TEmpresas` y
del código de la KB.
