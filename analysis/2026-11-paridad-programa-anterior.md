# Paridad con el programa anterior — noviembre 2026

Foto del 20/11/2026: qué tablas con datos del programa anterior (GeneXus) tienen ya su sitio en la plataforma, cuáles se cargan
con el ETL, qué falta y qué no se va a migrar. Sirve para decidir el orden de lo que queda antes de la primera ola de clientes.

**Fuentes:** `legacy/uso-tablas-todos-los-tenants.csv` (las 259 tablas del tenant en los 162 schemas de producción: 212 con datos
en algún schema), `legacy/tenant-schema-ddl.sql`, los tamaños de producción del 20/11 (103 GB, 81 de ellos adjuntos de asientos),
los scripts de exportación del ETL (`activopro-platform/etl/legacy-export/*.cmd`) y `activopro-platform/CLAUDE.md`.

**Criterio:** una tabla con las mismas filas por schema en todos (p. ej. 15 en `facmod`, 92 en `claacr`) es un catálogo sembrado en
el alta, no un uso real del cliente; esas se marcan «a confirmar» y no cuentan como hueco hasta ver si algún cliente las cambió.

## Resumen

| Estado | Áreas |
|---|---|
| **Cubierto y con carga** | Contabilidad (asientos, plan, saldos, plantillas, retenciones), IVA (registros, liquidaciones, 347/415, 349, prorrata, datos fiscales de la empresa), terceros (seis fichas, contactos, direcciones, mandatos), cartera (vencimientos, cobros, efectos), tesorería (cuentas, reglas N43), catálogo, almacén y lotes, albaranes, analítica |
| **Cubierto, carga pendiente** | Inmovilizado, recurrencias (`cuotas`), remesas, personalizaciones de informes (`definfcon*`, `defexplo*`), SII ya enviado (`pressii`), historial de envíos por correo |
| **Falta en la plataforma** | Documentos adjuntos (H-098), usuarios y accesos (H-100), histórico de facturas como documento (H-101), préstamos (H-102), inmuebles (H-099) |
| **A confirmar con datos** | Facturación en divisa, modelos propios de factura y cartas, clasificación de terceros |
| **No se migra** | Temporales, cachés recalculables, conciliaciones antiguas, gastos de viaje, integración RICOH, copias de trabajo |

## Por tabla

### Cubierto y con carga

- **Contabilidad** (`exportar-contabilidad.cmd`): `movctas`, `movctaslevel1`, `movctaslevel2`, `saldos`, `saldoslevel1`, `tctactble`,
  `defctactable`, `defctactablelevel1`, `paramejer`, `paramejerlevel1`, `platip`, `tconceptos`, `tipirpf`, `tipirpf1`, `idiomas`,
  plantillas `asidef*` (6 tablas).
- **IVA** (`exportar-iva.cmd`): `liqiva`, `tivaintra`, `prorrata`, `iae`, `empresasiae`, `empresa_contacto`, `tctareferencia`,
  tipos `ivatipos`, `ivatipos1`, `ivatiposctas`, `ivavigencia`, `igictipos`, `igictiposctas`, `igictiposvigencia`.
- **Terceros** (`exportar-terceros.cmd`): `clientes`, `proveedor`, `acreedores`, `empleados`, `bancos`, `bancosbcta`, `otros`, `clidir`,
  `cliest`, `climandatos`, `climandatoslevel1`, `tclientes_contactos`, `forcob`, `forpag`, `pais`, `localidades`, `limdeclara`,
  `mayores347`, `tmp347` (modo sombra).
- **Cartera** (`exportar-cartera.cmd`): `carteradecobros`, `carteradecobrosccbvto`, `carteradecobrosccbvtocob`, `carterapagos`,
  `carterapagoscpgvto`, `carterapagoscpgvtopag`, `carteraefectos`, `docscartera`, `riesgoefectos`; `cyppdtes` solo a `etl.legacy_cyppdtes`.
- **Tesorería** (`exportar-tesoreria.cmd`): `prgama`, `prgctascab`, `tplann43`, `tmpficbanconceptos`, `tmpficbanoperacion`.
- **Catálogo, almacén y albaranes** (`exportar-almacen.cmd`): `articulos`, `artiprecio`, `artitarifas`, `artitarifasimporte`,
  `artistock`, `familias`, `famgru`, `familiasfamgru`, `ttarifas`, `cliarticulostarifa`, `uniconsumo`, `lote`, `lotearticulo`,
  `tlotartreglevel1`, `faclinlote`, y de `facturas` / `facturasfaclin` / `facturasfacdto` lo que mueve stock.
- **Analítica** (`exportar-analitica.cmd`): `empcen`, `empcenlevel1`, `empdiv`, `tasiimpcen`, `tplaredcen`, `sdocentros` (modo sombra).
- **Empresa**: `empresas`, `pdefecto` (lo que se usa de sus parámetros).

### Cubierto en la plataforma, carga pendiente

| Tablas | Empresas con datos | Módulo | Nota |
|---|---|---|---|
| `activofijo`, `activofijoactcos`, `activofijoactamo`, `activofijoactcon`, `activofijoactbaj`, `activofijoclase`, `activofijo2actmod`, `grupoinmov`, `clainmo`, `metodoamort`, `tmpinm` | 108 | Inmovilizado | ADR-0045, fase 4 (ETL y modo sombra) |
| `cuotas`, `cuotaslevel1` | 26 | Recurrencias | Aplazado en ADR-0039 |
| `remesacobro`, `remesacobrolevel1`, `remesapago`, `remesapagorpag`, `empsepa` | 7 (`empsepa` 62) | Remesas | Aplazado en ADR-0038; el acreedor SEPA de `empsepa` va a la cuenta de tesorería |
| `definfcon`, `definfconceptos`, `definfconconceptos`, `definfconconceptoscta`, `definfconallconceptosidiomacon`, `definfconallidi`, `definfconconceptosinflinemp`, `defexplo`, `defexplolevel1` | 162 (`defexplo` 24) | Estados financieros, informes por centro | Pendiente en ADR-0017 / ADR-0049: cargar solo lo que el cliente personalizó, con su modo sombra |
| `pressii` | 6 | SII | H-089: con el cuadre de dos ejercicios en la migración |
| `facvtaproemail`, `tbandejaemail` | 30 / 68 | Envío por correo, bandeja | Historial de envíos y documentos pendientes de la bandeja: baja prioridad |
| `tcliadmcen`, `tcliadmcenrol` | 5–9 | Facturae (centros DIR3) | Pocas empresas: cargarlos con los terceros |
| `numserie`, `numeradores`, `numbasicos` | 144–162 | Series | Las series de facturación de la plataforma se crean al migrar; falta llevar el número siguiente de cada serie activa |

### Falta en la plataforma

| Hueco | Tablas | Empresas | Prioridad |
|---|---|---|---|
| **H-098** Documentos adjuntos al asiento, la factura y el inmovilizado | `adjmovctas` (477.000, 81 GB), `facturasadjuntos`, `activofijoactdoc`, `uploadfile` | 148 | Alta: sin esto no se migra a quien adjunta |
| **H-100** Usuarios y accesos | `usuarios`, `acceso`, `segprg`, `segprgaccion`, `usuprg1` | 162 | Alta: hoy cada usuario se da de alta a mano en la consola |
| **H-101** Histórico de facturas como documento | `facturas`, `facturasfaclin`, `facturasfacimp`, `facturasfacven`, `facturasfacdto`, `dtocarfac` | 79 | Alta: la carga trae el registro contable y el de IVA, no el documento (líneas, vencimientos, PDF); sin él no se reimprime ni se rectifica desde el libro, y VeriFactu necesita su semilla |
| **H-102** Préstamos | `prestamos`, `prestamosprescon`, `prestamospresint`, `prestamospresrev` | 36 | Media: cuadro de amortización, cuota con intereses y reclasificación a corto plazo |
| **H-099** Inmuebles (347, factura de alquiler, 115/180, SII) | — | mconta0050 de referencia | Media |

### A confirmar con datos de producción

- **Facturación en divisa** (`divisas` en 35 empresas, `divisasvigencia`, `monedas`): la plataforma guarda la divisa en los apuntes
  cargados, pero no emite ni registra facturas en divisa. Comprobar si hay facturas en otra moneda:
  `select table_schema, count(*) from information_schema.columns where column_name = 'FacDiv%'…` (consulta exacta por preparar con
  el nombre de la columna en `facturas`).
- **Modelos propios de factura y cartas** (`facmod`, `cartamod`, 15 por schema; `modlistados` en 95): por el recuento parecen los
  sembrados en el alta. Ver qué clientes tienen uno cambiado: la plataforma tiene tres diseños con el estilo de la empresa (ADR-0046)
  y no tiene cartas (reclamación de deuda, etc.).
- **Clasificación de terceros** (`clacli`, `clapro`, `claacr`, `tclaotr`, `tercercladoc`): también parecen sembrados; si algún
  cliente clasifica terceros para sus listados, la plataforma no tiene ese campo.
- **Historial de modificaciones de asientos** (`movctasupd*`, 152 empresas, 254.000 filas): la plataforma guarda su propio
  `audit_log` desde la carga. Decidir si el historial anterior se carga como consulta (`etl.legacy_*`) o se queda en la copia del
  schema.

### No se migra

- **Temporales y cachés**: `tmpexcel`, `tmpiva`, `tmp347` (solo modo sombra), `tmpficban`, `tmpficban1`, `tmporides*`, `infcalculo`,
  `tempcenparcentros`, `numfratmp`, `ctacorriente` (cuenta corriente recalculable: la cartera y el mayor la sustituyen).
- **Conciliaciones antiguas**: `cuadreban` y `conbanco` (sin uso desde 2020–2023, ADR-0037).
- **Gastos de viaje** (`gvconceptos*`, `gvdesplazamiento`, `gvnotadiariadetalleconcepto`, `gvliquidacion`): catálogo sembrado; solo
  1–2 empresas lo usaron.
- **Integración RICOH** (`ricoherp`, 3 empresas): la bandeja de entrada la sustituye.
- **Catálogos generales** que la plataforma tiene como norma central o deriva: `localidad`, `provincia`, `divisas2`, `tpaisestpo`,
  `viatpo`, `cenae`, `ivasujecion`, `tipigic`, `tipigictip`, `tipivaplano`, `exctpo`, `departamento`, `tcargos`, `troles`.
- **Seguridad del programa**: `segprg*` y `usuprg1` como permisos por programa; la plataforma usa roles (ADR-0015). Los usuarios sí
  se migran (H-100).
- **Copias de trabajo** en producción: `bk_*`, `fix_*`, `*_bak_*` (correcciones de octubre de 2026).

## Siguiente paso propuesto

Los tres altos (H-098 adjuntos, H-100 usuarios, H-101 histórico de facturas) bloquean la primera ola de clientes reales; los
pendientes de carga (inmovilizado, cuotas, remesas, personalizaciones de informes) son trabajo de ETL sobre módulos ya hechos. El
orden lo decide José María.
