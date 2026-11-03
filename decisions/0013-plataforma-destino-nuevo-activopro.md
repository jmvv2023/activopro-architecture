---
id: 0013
title: Plataforma destino del nuevo ActivoPro — Postgres gestionado, tenant_id con RLS y monolito modular TypeScript
status: accepted
date: 2026-11-03
services: [core, all]
supersedes: null
superseded_by: null
---

## Contexto

ActivoPro en producción es un monolito GeneXus 16 U8 (Java/Tomcat) sobre MySQL 8, con un schema por cliente (`mconta####`, ~160 tenants, >300 usuarios). Desde 2025 se construye un "nuevo ActivoPro" (React/Refine + Supabase) que, a noviembre de 2026, no tiene ningún cliente.

El avance es lento por tres motivos que se refuerzan entre sí:

1. Se hacen tres migraciones a la vez: tecnología, modelo de datos y lógica de negocio.
2. La paridad funcional con GeneXus no se puede demostrar, así que nunca hay confianza para migrar a un cliente.
3. El diseño del nuevo ActivoPro acumula deuda estructural (ver [inventario 2026-11](../analysis/2026-11-inventario-nuevo-activopro.md)): lógica de negocio en 116 funciones PL/pgSQL, 63 de ellas con SQL dinámico por schema, control de acceso copiado a mano en cada función, sin migraciones versionadas y schemas de tenant ya desalineados con la plantilla.

Esta ADR fija **el destino** (qué plataforma queremos tener a 5–10 años). **El camino** (cómo llegar desde GeneXus sin big bang) se decidirá en un ADR posterior que concretará ADR-0003.

No cambia ADR-0002: mientras dure la transición, MySQL sigue siendo el motor y la fuente de verdad del núcleo GeneXus. Esta ADR trata del modelo de la plataforma nueva.

## Opciones consideradas

1. **Seguir con el enfoque actual** (Supabase con lógica en RPCs PL/pgSQL y schema por tenant). Sin coste de cambio; deuda estructural creciente, seguridad dependiente de comprobaciones copiadas a mano.
2. **Backend propio sobre el modelo MySQL actual**, compartiendo base con GeneXus. Transición rápida; hereda el modelo legacy y obliga a una segunda migración.
3. **Mover GeneXus a Postgres y construir encima.** Permite estrangular por pantallas; mismo problema de herencia del modelo y riesgo alto en el núcleo (ADR-0002).
4. **Plataforma limpia: Postgres gestionado, tablas compartidas con `tenant_id` y RLS, backend TypeScript.** Exige reescribir la capa de datos del nuevo ActivoPro; es la opción que mejor cumple los criterios.

### Criterios

Por orden de prioridad: seguridad propia de una plataforma contable; mantenimiento mínimo (sin servidores administrados por nosotros); código limpio, tipado y testeable (también para que Claude pueda avanzar de forma autónoma); despliegue automático; capacidad de evolucionar. La velocidad de la transición **no** es criterio para el destino.

## Decisión

Se adopta la opción 4. Detalle:

### 1. Base de datos: PostgreSQL gestionado

- PostgreSQL gestionado, región UE, con PITR. Supabase (plan de pago) es aceptable como proveedor; la arquitectura no depende de él.
- Motivos frente a MySQL: constraints diferibles (cuadre de asientos al commit), DDL transaccional (migraciones atómicas), Row Level Security, ecosistema y oferta gestionada.
- MySQL queda solo como origen de datos durante la transición.

### 2. Multi-tenancy: tablas compartidas con `tenant_id` y RLS forzada

- Todas las tablas de datos de cliente llevan `tenant_id`. Las tablas globales (catálogos, plan contable maestro, tipos de impuesto…) están en una lista explícita.
- RLS habilitada y **forzada** en todas las tablas de tenant. El rol de la aplicación no es propietario de las tablas ni tiene `BYPASSRLS`.
- El tenant se fija **por transacción** (`SET LOCAL app.tenant_id = …`), nunca por sesión (con pooling se filtraría entre clientes).
- Prohibido el SQL dinámico con nombre de schema por tenant.
- CI comprueba que toda tabla nueva tiene `tenant_id` y política RLS (salvo la lista de globales) y ejecuta tests de aislamiento: un usuario del tenant A intenta leer y escribir datos de B en cada tabla y debe fallar.

Alternativa descartada: schema por tenant. Da aislamiento solo lógico (mismo usuario de BD para todos), multiplica las migraciones por N, fragmenta el catálogo y obliga a SQL dinámico. Su ventaja real (borrar o restaurar un cliente aislado) se cubre con los puntos 7 y 8.

### 3. Identificadores: UUIDv7

- Claves primarias UUIDv7 en todas las tablas. Nunca autoincrementales.
- Permite mover datos de un tenant entre bases sin colisiones (base dedicada, exportación/importación).
- Las numeraciones de negocio (facturas, asientos) son campos aparte, gestionados por series con bloqueo transaccional.

### 4. Backend: monolito modular en TypeScript

- Un único backend Node/TypeScript para el core (facturación, contabilidad, IVA, tesorería, stock…), organizado en módulos con fronteras internas claras.
- **La lógica de negocio vive en servicios TypeScript con tests**, no en funciones PL/pgSQL. En la base de datos solo van garantías de integridad (constraints, triggers de invariantes como el cuadre de asientos o la inalterabilidad de registros VeriFactu).
- Acceso a datos tipado (query builder con tipos generados del esquema).
- El front React habla solo con la API del backend.

### 5. Microservicios: solo para capacidades periféricas

- Se mantienen como servicios autónomos los que no comparten transacciones con el core: OCR, generación de PDF, VeriFactu, alertas fiscales, importación, factura electrónica.
- No se parte el core en microservicios.
- Cada micro guarda sus datos por tenant y es capaz de purgar un tenant por sí mismo (punto 8), sin depender de otros servicios.

### 6. Identidad y autenticación

- Delegada en un proveedor de identidad gestionado (Supabase Auth u otro equivalente): MFA, políticas de contraseña, gestión de sesiones y SSO futuro.
- No se reutiliza la tabla de usuarios de GeneXus como sistema de identidad definitivo (sí puede usarse para el alta inicial de usuarios migrados).

### 7. Base de datos dedicada: preparada, no ofrecida

Preparado desde el inicio:

- Registro de tenants con su destino de conexión; el backend resuelve tenant → base en cada petición.
- Sin claves foráneas entre datos de tenant y datos globales; los catálogos globales son datos de referencia.
- El ejecutor de migraciones recorre todas las bases; el despliegue no termina hasta que todas están en la misma versión y el backend verifica la versión al arrancar.
- Exportación/importación completa por tenant.
- `tenant_id` y RLS se mantienen también en una base dedicada (mismo código, sin ramas especiales).

No se construye todavía: aprovisionamiento automático, monitorización por base, precio y SLA. Usos previstos: tenants muy grandes que afecten al resto, requisitos de privacidad de clientes concretos, aislamiento de incidencias. Solo se ofrece si se cobra.

### 8. Ciclo de vida del tenant

| Estado | Cuándo | Efecto |
|---|---|---|
| Activo | Alta, y también cliente en proceso de baja que sigue pagando la cuota | Operativa completa, consulta y descarga |
| Bloqueado | Impago, tras los avisos y plazos contractuales | Acceso cerrado, datos intactos; se reactiva al pagar |
| Purgado | Confirmación escrita del cliente, o fin del proceso de impago | Datos eliminados; queda solo un registro mínimo sin datos personales |

- **Alta:** función transaccional sin DDL que registra el tenant y siembra datos iniciales (plan contable, ejercicio, series, impuestos, usuario administrador). La importación desde el software anterior del cliente es un módulo de producto aparte.
- **Purga:** proceso único y orquestado:
  - borra por lotes, en orden de dependencias, en la base de datos;
  - borra los ficheros en storage bajo `tenants/{tenant_id}/`;
  - emite el evento "tenant purgado" para que cada micro se limpie a sí mismo;
  - verifica automáticamente que no quedan filas ni ficheros del tenant y registra el resultado.
- **Prueba de la instrucción de borrado:** se guarda la confirmación del cliente (o la constancia de los avisos de impago) asociada al registro de purga.
- **Backups:** los datos purgados persisten en los backups hasta que caduca la ventana de PITR; debe constar en el contrato y en la documentación RGPD.
- **Exportación:** además del Excel/PDF de autoservicio, a petición se entrega un fichero SQLite con todos los datos del tenant, nombres limpios y diccionario de datos (sustituye a la entrega del schema MySQL a los asesores). Es la misma herramienta que sirve para mover un tenant a base dedicada.
- **CI:** test que crea un tenant con datos en todas las tablas, lo purga y verifica que no queda nada.

### 9. Infraestructura y despliegue

- Ningún servidor administrado por nosotros: base de datos gestionada y backend en contenedor sobre plataforma gestionada.
- El esquema vive en el repo como migraciones versionadas; se aplican solo desde CI. Nunca cambios manuales en el SQL Editor de producción.
- GitHub Actions: tests, migraciones y despliegue en cada merge. Entornos de preview por PR cuando el proveedor lo permita.
- Secretos en el gestor de la plataforma, no en ficheros.
- Producción: acceso de lectura como máximo para herramientas y agentes (incluido Claude); los cambios entran solo por el repo.

### 10. Seguridad (requisitos mínimos)

- MFA disponible para todos los usuarios y obligatorio para administradores.
- Audit log inmutable de cambios en datos de negocio (quién, qué, cuándo).
- Cifrado en tránsito y en reposo.
- Restauraciones probadas periódicamente (completa y de un solo tenant).
- Escaneo de dependencias en CI.
- Mínimo privilegio en todas las credenciales.
- Contratos de encargado de tratamiento (RGPD) con los proveedores.

## Consecuencias

**Positivas:** una sola migración de esquema para todos los clientes; aislamiento garantizado por la base de datos; lógica de negocio testeable; despliegue automático; alta de clientes en segundos; base dedicada posible sin reescribir.

**Negativas / costes:**

- Se reescribe la capa de datos y lógica del nuevo ActivoPro (RPCs PL/pgSQL → servicios TypeScript; schema por tenant → `tenant_id`). Se conserva el front, las convenciones de UI y el conocimiento funcional. Es el momento más barato para hacerlo: 0 clientes y 0 datos en producción.
- Restaurar un único tenant requiere un procedimiento específico (restaurar a un entorno aparte y extraer sus filas).
- Hay que construir y mantener la herramienta de exportación/purga por tenant.

## Pendiente

- ~~ADR del camino~~: resuelto en ADR-0016.
- Validar con el asesor legal la redacción contractual de baja, impago y conservación en backups.
- Elegir plataforma gestionada para el backend.

## Origen

Conversación con José María del 2–3/11/2026 sobre el replanteamiento del nuevo ActivoPro, con decisión explícita suya sobre cada punto (incluidas las objeciones de privacidad del schema por cliente, la base dedicada como opción y el ciclo de baja e impago). Inventario de soporte: `analysis/2026-11-inventario-nuevo-activopro.md`.
