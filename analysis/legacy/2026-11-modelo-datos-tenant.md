# Modelo de datos del tenant GeneXus — análisis para la migración

Análisis de la estructura del schema de tenant de ActivoPro, tomada de `mconta0037` (copia local; uno de los tenants más grandes) el 2026-11-03. Sirve de base para el ADR del camino desde GeneXus (modo sombra, ETL nocturno).

Ficheros de apoyo en esta carpeta:

- `tenant-schema-ddl.sql`: DDL completo (237 tablas y 2 procedimientos), solo estructura.
- `mconta0037-filas-por-tabla.csv`: recuento aproximado de filas por tabla (`information_schema`).

## Cifras

- 237 tablas, 2.905 columnas, todas InnoDB.
- 235 tablas en `latin1` y 2 en `utf8mb4` (`pdefectomsg`, `pressii`).
- 229 claves foráneas declaradas: GeneXus genera la integridad referencial en la base.
- **0 triggers.** Solo hay 2 procedimientos almacenados, ambos de usuarios y login (`cambia_usupss`, `select_emp_usu`).
- Claves naturales compuestas: 174 tablas tienen `EmpCod` al principio de la PK (el schema admite hasta 4 empresas).
- ~5,1 millones de filas en el tenant.

## Tablas por área funcional (mconta0037)

| Área | Tablas | Vacías | Filas | Tablas principales |
|---|---|---|---|---|
| Contabilidad | 35 | 11 | 1.926.515 | ctacorriente, movctas, movctaslevel1, saldoslevel1, adjmovctas, saldos |
| Facturación | 15 | 5 | 1.628.647 | facturasfaclin, facturasfacimp, facturasfacven, facturas, facvtaproemail |
| Stock y lotes | 7 | 2 | 1.093.492 | faclinlote, lotearticulo, tlotartreglevel1, lote, artistock |
| Cartera, remesas y bancos | 31 | 9 | 154.680 | carteradecobros(ccbvto, ccbvtocob), cuadreban, carterapagos |
| Catálogos generales | 11 | 0 | 138.982 | divisasvigencia, localidad, iae, cenae, pais |
| Informes configurables | 10 | 1 | 75.779 | definfconconceptoscta, definfconallconceptosidiomacon |
| Artículos y tarifas | 12 | 1 | 53.097 | artitarifasimporte, artitarifas, artiprecio, articulos |
| Usuarios y seguridad | 16 | 7 | 15.315 | acceso, segprgaccion, usuprg1 |
| Inmovilizado | 11 | 3 | 9.341 | activofijoactcon, activofijoactamo, activofijo |
| Terceros | 28 | 13 | 4.423 | tctaterceros, clidir, clientes, proveedor, acreedores |
| Fiscal (IVA, IGIC, IRPF, 347, SII) | 25 | 9 | 2.676 | tivaintra, liqiva, tipirpf1, ivatiposctas |
| Empresa y configuración | 13 | 6 | 523 | pdefecto, empresas, empcen |
| Temporales y de trabajo | 17 | 11 | 663 | tmp347, tmpficban* |
| Gastos de viaje | 5 | 5 | 0 | gv* |

En total, **83 de las 237 tablas están vacías** incluso en uno de los tenants más grandes.

## Observaciones para la migración

1. **Toda la lógica de negocio está en GeneXus, no en la base de datos.** No hay triggers y los únicos procedimientos son de login. La KB (Transactions, procedures, reglas) es la única especificación de las reglas de negocio. Lo bueno: la base es un modelo de datos limpio, con claves foráneas que dan el orden de carga del ETL.

2. **Hay datos derivados que no se migran y que sirven como oráculo de paridad.**
   - `ctacorriente` (743.808 filas) es un índice de `movctas` por cuenta y fecha; no tiene importes.
   - `saldos` y `saldoslevel1` (~136.000 filas) son los acumulados de debe y haber por cuenta y mes que mantiene GeneXus.

   La plataforma nueva no los migra: los recalcula. A cambio, los saldos de GeneXus son una referencia gratuita para el modo sombra. Si los saldos por cuenta y mes que calcula el sistema nuevo coinciden con `saldoslevel1`, la contabilidad está bien migrada.

3. **Modelo contable.**
   - `movctas` contiene los apuntes, con PK `MovEmpCod, EjerCod, MovId, MovLin`. El asiento no tiene cabecera propia: es el conjunto de líneas con el mismo `MovId` dentro del ejercicio.
   - `movctaslevel1` es el registro de IVA de cada apunte (base, tipo, cuota, deducibilidad, clave de operación).
   - Las cuentas se identifican por `CtaTit char(4) + CtaCod char(6)`.

4. **Tipos inconsistentes entre tablas.** El mismo concepto se guarda con tipos distintos; por ejemplo, el código de cuenta es `char(6)` en `tctactble`/`ctacorriente` y `mediumint` en `facturas.FacCtaCod`. El ETL tiene que normalizarlo.

5. **Ficheros guardados dentro de la base.** 18 tablas tienen columnas `blob`/`longblob`: adjuntos de apuntes (`adjmovctas`, 65.686 filas), documentos de apuntes, adjuntos y QR de factura, logos, mandatos SEPA, modelos de carta y factura… En la plataforma nueva van a almacenamiento de objetos. Probablemente son la mayor parte del tamaño del schema.

6. **Codificación.** Casi todo está en `latin1`; el ETL convierte a UTF-8 en un único punto (como ya hacen los micros).

7. **Identificadores.** La plataforma nueva usa UUIDv7 (ADR-0013). El ETL necesita una **tabla de correspondencia persistente** de clave legacy (`tenant + EmpCod + clave natural`) a UUID. Así cada carga nocturna es idempotente y los IDs no cambian entre ejecuciones.

8. **Volumen.** ~5 millones de filas en uno de los tenants más grandes es poco para Postgres. Al principio basta una carga completa nocturna por tenant. Más adelante se puede pasar a una carga incremental, porque muchas tablas tienen columnas de última modificación (`FacMod`, `CtaUltMod`, `EjerUltMod`…).

9. **Uso de lotes.** En este tenant, `faclinlote` (1.047.054 filas) tiene prácticamente una fila por línea de factura (`facturasfaclin`, 1.057.480): usa lotes de forma intensiva.

10. **Tablas sin uso.** Las 83 tablas vacías y las 17 temporales son candidatas a no migrarse. Para confirmarlo hace falta el recuento de filas por tabla en todos los tenants: lo que está vacío en todos no se migra.

## Riesgo de seguridad detectado en el núcleo actual

`cambia_usupss(bd, usu, pass)` construye un `UPDATE` concatenando los tres parámetros en el texto SQL y lo ejecuta con `PREPARE`. Si alguno de esos valores llega del usuario (la contraseña, por ejemplo), es **inyección SQL**: una contraseña con comillas puede alterar la sentencia, y el parámetro `bd` permite apuntar a cualquier schema.

- Hay que averiguar quién llama al procedimiento (GeneXus, ms-auth…) y con qué datos.
- La corrección es pasar `usu` y `pass` como parámetros del `PREPARE` (`EXECUTE s USING …`) y validar `bd` contra la lista de schemas.
- Afecta a producción y al núcleo: lo decide José María (regla 4 de `CLAUDE.md`).

`usuarios.UsuPss` (`char(40)`) contiene un MD5 sin sal en base64 (16 bytes): el mismo usuario tiene el mismo valor en todas las empresas. No es aceptable para la plataforma nueva (ADR-0013 delega la identidad en un proveedor gestionado). En la migración de usuarios no se pueden traer las contraseñas: los usuarios migrados tendrán que establecer una nueva.

## Preguntas abiertas

1. ~~**Tenant y empresa.**~~ Propuesto en ADR-0014 (los usuarios son por empresa; se mantiene la pertenencia usuario–empresa).
   Detalle original: Un schema puede contener varias empresas (`EmpCod`). En la plataforma nueva, ¿el tenant es el cliente que contrata (y las empresas cuelgan de él) o cada empresa es un tenant? Propuesta (03/11/2026): `tenant_id` = cliente que contrata, con RLS; `empresa_id` en todas las tablas de negocio, sin permisos por empresa de momento (hoy quien entra en un schema lo ve todo).
2. **Alcance real de uso.** Recuento de filas por tabla en todos los tenants, para saber qué módulos se usan y cuáles no.

## Uso de tablas en producción (03/11/2026)

Recuento sobre los **162 schemas `mconta%` de producción** (metadatos de `information_schema`, sin datos): `uso-tablas-todos-los-tenants.csv`.

**Volumen total: ~68,4 millones de filas**, repartidas así:

| Tipo | Filas | Tratamiento |
|---|---|---|
| Catálogos y configuración replicados en cada schema (localidades, divisas, CNAE, IAE, tipos de IVA/IGIC/IRPF, plantillas de cuentas, definiciones de informes, seguridad de programas…) | ~36,8 M | En la plataforma nueva son datos globales: se cargan una vez. Hay que comprobar qué parte de la configuración de informes (~12 M filas `definf*`) ha personalizado algún cliente |
| Derivados (`ctacorriente`, `saldos`, `saldoslevel1`) | ~11,3 M | No se migran; se recalculan y sirven de oráculo de paridad |
| Temporales (`tmp*`), log de accesos (`acceso`) y copias manuales (`bk_*`, `*_bak_*`, `fix_*`) | ~0,6 M | No se migran |
| **Datos de negocio reales** | **~19,7 M** | Lo que migra el ETL |

**Tablas:**
- 45 tablas vacías en todos los schemas: no se migran.
- 14 tablas de copias y arreglos manuales de octubre de 2026 (`bk_*`, `*_bak_*`, `fix_*`) en algunos schemas. El ETL las excluye; conviene limpiarlas cuando ya no hagan falta.
- `verifactu_registro` aún no existe en ningún schema de producción.

**Uso por módulo** (schemas con datos, de 162):

| Módulo | Schemas | Comentario |
|---|---|---|
| Contabilidad (`movctas`) | 157 | El núcleo del producto |
| Liquidación de IVA (`liqiva`) | 118 | |
| Cartera de pagos | 112 | |
| Inmovilizado (`activofijo`) | 108 | Pendiente en el nuevo ActivoPro |
| Cartera de cobros | 94–96 | |
| SEPA (mandatos) | 80 | Pero remesas de cobro solo en 6 y de pago en 7 |
| **Facturación (`facturas`)** | **79** | **Solo la mitad de los schemas factura con ActivoPro** |
| Artículos y tarifas | 60–70 | |
| Stock (`artistock`) | 59 | |
| Operaciones intracomunitarias (`tivaintra`) | 44 | |
| Préstamos | 36 | |
| Centros de coste / analítica (`sdocentros`, `tasiimpcen`) | 28–29 | No está en el nuevo ActivoPro |
| Lotes (`faclinlote`, `lote`) | 3 | 2 millones de filas concentradas en 3 schemas |
| Gastos de viaje | 2 | Configurado en 110, usado en 2 |

**Consecuencias:**
- ActivoPro es ante todo un producto de **contabilidad**: 157 schemas llevan contabilidad y solo 79 facturan. Unos 78 schemas usan contabilidad, IVA, cartera e inmovilizado sin facturación.
- Esos schemas podrían formar una **primera ola de migración** sin depender de facturación, VeriFactu ni stock.
- **Jerarquía:** schema (cliente que contrata) → empresas → centros.
  - `empresas` suma 583 filas en 149 schemas, pero **no son empresas reales**: cada schema se crea con las empresas 1 a 4 preparadas. Según José María, solo unos 20 de los ~160 clientes tienen de verdad varias empresas.
  - El ETL tiene que **distinguir empresas reales de huecos preparados**. Criterio propuesto: una empresa es real si tiene datos (apuntes, facturas…) o datos fiscales completos (NIF). Las vacías no se migran.
  - `empcen` (781 filas en 156 schemas) puede tener el mismo efecto; pendiente de comprobar.

## Permisos de usuario (03/11/2026, producción)

- `mconta0999` y `mconta9999` son demos, no clientes: 162 schemas = 160 clientes + 2 demos.
- Diferencias de estructura entre schemas: mínimas. Un schema no tiene 3 columnas (`artistock.ArtIntCod`, `empcen.CentState`, `remesapagorpag.RpagLinEjer`) y las columnas `msFacVeri*` de `facturas` solo existen en un schema (micro VeriFactu). Basta un único ETL.
- `usuprg1` contiene bloqueos por usuario, empresa, programa y acción (hipótesis pendiente de confirmar: una fila = acción bloqueada). Patrones por usuario activo (`UsuBaj = 'N'`) en `patrones-bloqueo-usuarios.csv`:
  - 1.053 usuarios activos y 101 patrones distintos.
  - 608 usuarios (58 %) sin ningún bloqueo.
  - Los 4 patrones más frecuentes cubren 877 usuarios (83 %): sin bloqueos; sin administración de usuarios/seguridad/accesos ni caja/cuadro; sin administración de usuarios/seguridad/accesos; sin administración de usuarios/seguridad.
  - El resto (~176 usuarios) son patrones de 1–10 usuarios, varios con bloqueos fiscales (IVA/IGIC, libros, declaraciones) o de mantenimiento (`INS`/`UPD`/`DLT`).

Pendiente: confirmar el significado de una fila y de `UsuSegAccEst`; decidir roles en un ADR propio.
