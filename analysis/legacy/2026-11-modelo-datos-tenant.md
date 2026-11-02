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
- Claves naturales compuestas: 174 tablas tienen `EmpCod` al principio de la PK (varias empresas por schema).
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

`usuarios.UsuPss` es `char(40)`, que encaja con un hash SHA-1 en hexadecimal o con texto plano. Ninguna de las dos opciones es aceptable para la plataforma nueva (ADR-0013 delega la identidad en un proveedor gestionado). En la migración de usuarios no se pueden traer las contraseñas: los usuarios migrados tendrán que establecer una nueva.

## Preguntas abiertas

1. **Tenant y empresa.** Un schema puede contener varias empresas (`EmpCod`). En la plataforma nueva, ¿el tenant es el cliente que contrata (y las empresas cuelgan de él) o cada empresa es un tenant? La propuesta es `tenant_id` = cliente que contrata y `empresa_id` dentro de él, con RLS por tenant y permisos por empresa. Hay que decidirlo antes de diseñar el modelo nuevo.
2. **Alcance real de uso.** Recuento de filas por tabla en todos los tenants, para saber qué módulos se usan y cuáles no.

## Uso de tablas en todos los schemas (03/11/2026)

Recuento sobre los schemas `mconta%` disponibles (22 schemas): `uso-tablas-todos-los-tenants.csv`.

**Volumen total: ~21,4 millones de filas**, repartidas así:

| Tipo | Filas | Tratamiento |
|---|---|---|
| Catálogos y configuración replicados en cada schema (localidades, divisas, CNAE, IAE, tipos de IVA/IGIC/IRPF, definiciones de informes, seguridad de programas…) | ~5,1 M | En la plataforma nueva son datos globales: se cargan una vez, no por tenant. Hay que comprobar qué parte de la configuración de informes ha personalizado algún cliente |
| Derivados (`ctacorriente`, `saldos`, `saldoslevel1`) | ~4,0 M | No se migran; se recalculan y sirven de oráculo de paridad |
| Temporales (`tmp*`) y log de accesos (`acceso`) | ~0,2 M | No se migran |
| **Datos de negocio reales** | **~12,0 M** | Lo que migra el ETL |

**Tablas:**
- 46 tablas vacías en todos los schemas: no se migran.
- 27 tablas con datos en solo 1 o 2 schemas.

**Uso por módulo** (número de schemas con datos, de 22):

| Módulo | Schemas | Comentario |
|---|---|---|
| Contabilidad (`movctas`) | 21 | Núcleo para todos |
| Inmovilizado (`activofijo`) | 18 | Muy usado; pendiente en el nuevo ActivoPro |
| Cartera de pagos y cobros | 16–18 | |
| Facturación (`facturas`) | 15 | Unos 6 schemas son solo contabilidad |
| SEPA (mandatos) | 14 | Pero remesas de cobro solo en 4 |
| Artículos y tarifas | 13 | |
| Centros de coste / analítica (`sdocentros`, `tasiimpcen`) | 6–9 | 763.000 filas en `sdocentros`; no está en el nuevo ActivoPro |
| Operaciones intracomunitarias (`tivaintra`) | 9 | |
| Préstamos | 7 | |
| Stock (`artistock`) | 12 | |
| Lotes (`faclinlote`, `lote`) | 2 | 2 millones de filas concentradas en 2 schemas |
| Gastos de viaje | 1 | Configurado en 11, usado en 1 |
| VeriFactu (`verifactu_registro`) | 1 | |

**Multi-empresa:** `empresas` suma 75 filas en 22 schemas, es decir, unas 3,4 empresas por schema. Varias empresas por schema es lo habitual, no la excepción, y eso apoya modelar el tenant como el cliente que contrata, con sus empresas dentro.
