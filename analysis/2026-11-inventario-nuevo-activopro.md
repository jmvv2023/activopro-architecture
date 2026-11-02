# Inventario del nuevo ActivoPro — noviembre 2026

Foto del estado del nuevo ActivoPro (repo `jmvv2023/activopro` + proyecto Supabase `activopro`, `yhdjzflxcahxxkspqzuq`, eu-west-3) para estimar la reescritura que implica [ADR-0013](../decisions/0013-plataforma-destino-nuevo-activopro.md). Datos obtenidos el 2026-11-03.

## Front (`jmvv2023/activopro`)

- React 19 + Refine 5 + Ant Design 5 + Vite. ~14.400 líneas en `src/`.
- 31 ficheros de páginas: terceros, catálogo, documentos (presupuestos/pedidos/albaranes), facturas, contabilidad (asientos, balance, resultado), tesorería, remesas, suscripciones, fiscal (Mod.303), dashboard, configuración, admin, login, selección de empresa.
- Las pantallas más grandes: `facturas/form.tsx` (1.408 líneas), `configuracion/index.tsx` (1.233), `fiscal/modelos/mod303.tsx` (691), `documentos/form.tsx` (688).
- Acceso a datos: 60 RPCs distintas llamadas desde el front y lecturas directas a 3 catálogos (`tipos_impuesto`, `formas_pago_tipo`, `unidades_medida`).
- **No hay carpeta `supabase/` ni migraciones en el repo.** El repo real es `jmvv2023/activopro` (solo front); no coincide con el monorepo `activopro-platform` (apps/web, supabase/, docs/) que describe `system-map.md`.

**Qué se conserva:** pantallas, componentes, convenciones de UI. **Qué cambia:** la capa de datos (llamadas RPC → cliente de la API del backend) y el proveedor de auth/datos de Refine.

## Base de datos (proyecto Supabase `activopro`)

- Postgres 17.
- Sin historial de migraciones (`supabase_migrations` no existe): el esquema se ha construido a mano desde el SQL Editor y no es reproducible desde el repo.
- Schemas:
  - `activoprobase` (plantilla de tenant): 39 tablas — terceros y su configuración, productos y tarifas, documentos, facturas (líneas, IVA, vencimientos), asientos y apuntes, plan de cuentas, ejercicios, series, remesas, suscripciones, fiscal, configuración de empresa.
  - `public`: 29 tablas — empresas, usuarios y accesos, roles, catálogos, saldos e informes.
  - `activopro00000` (5 tablas: clientes, proveedores, bancos, empleados, acreedores), `activopro00001` (1 tabla), `activopro00002` y `activo0001` (vacíos): schemas de tenant **desalineados con la plantilla** — muestra de la deriva que produce el modelo de schema por tenant.
- Claves primarias enteras (p. ej. `factura_id integer`).

### Funciones (lógica de negocio)

- 116 funciones en `public`, ~244.000 caracteres de PL/pgSQL (≈ 6.000–7.000 líneas).
- 63 usan SQL dinámico (`EXECUTE format('… %I …', p_schema)`).
- 79 son `SECURITY DEFINER` (se saltan RLS); 68 de ellas son ejecutables por el rol `anon`.
- La mediana es pequeña (~860 caracteres): la mayoría son CRUD. La lógica real está concentrada en unas 15 funciones:

| Función | Caracteres |
|---|---|
| fiscal_mod303_generar_fichero | 20.728 |
| factura_contabilizar (2 sobrecargas) | 14.677 + 11.455 |
| factura_upsert | 9.977 |
| suscripcion_generar_facturas | 7.894 |
| factura_rectificar | 7.760 |
| dashboard_kpis | 7.475 |
| config_empresa_upsert | 7.121 |
| vencimiento_cobrar | 6.809 |
| documento_upsert | 6.611 |
| documento_convertir_factura | 6.202 |
| remesa_generar_xml | 6.004 |
| producto_get_precio | 4.904 |
| suscripcion_upsert | 4.640 |
| producto_upsert | 4.624 |

### Seguridad

- El control de acceso por tenant está **copiado a mano dentro de cada función** (comprobación contra `usuario_empresa` con `auth.uid()`).
- Al menos 4 funciones `SECURITY DEFINER` con parámetro `p_schema` no lo tienen y son ejecutables por `anon`: `serie_siguiente_numero`, `asiento_siguiente_numero`, `_upsert_tercero_config`, `_upsert_tercero_rol`. Con la clave pública del front, cualquiera podría avanzar contadores de series o asientos, o modificar configuración de terceros de cualquier tenant. Sin impacto hoy (0 clientes, entorno de desarrollo), pero es exactamente el tipo de fallo que la RLS forzada de ADR-0013 elimina por diseño.
- El asesor de seguridad de Supabase reporta además: tablas de `public` sin RLS (p. ej. `admin_usuarios`), una vista `SECURITY DEFINER`, funciones con `search_path` mutable, una tabla con RLS sin políticas, una extensión en `public` y la protección contra contraseñas filtradas desactivada.

## Estimación de la reescritura

Supuestos: Claude hace el trabajo mecánico (traducción de RPCs a servicios, adaptación de la capa de datos del front, tests) con convenciones escritas; José María revisa y decide.

| Bloque | Esfuerzo orientativo |
|---|---|
| Fundación: modelo con `tenant_id`/RLS/UUIDv7 para las ~68 tablas, migraciones en repo, backend base, auth, tests de aislamiento, CI/CD | 2–3 semanas |
| Portar las ~15 funciones con lógica real a servicios TypeScript con tests | 3–4 semanas |
| Portar el resto (~100 funciones CRUD) | 1–2 semanas |
| Adaptar la capa de datos del front (31 páginas, 60 llamadas) | 2–3 semanas |

**Orden de magnitud: 2–3 meses de trabajo efectivo**, mayoritariamente mecánico. La incertidumbre principal es cuánta lógica implícita hay en las funciones grandes (contabilización, rectificativas, Mod.303), que habrá que convertir en tests explícitos.

No se pierde: el front, las convenciones de UI, el conocimiento funcional ni los micros. El esfuerzo crece con cada mes que se siga construyendo sobre el modelo actual.
