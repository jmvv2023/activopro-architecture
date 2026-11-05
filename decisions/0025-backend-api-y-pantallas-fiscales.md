---
id: 0025
title: Backend Fastify con identidad de Supabase Auth; pantallas fiscales nuevas sobre su API
status: accepted
date: 2026-11-05
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

La plataforma (`activopro-platform`) tiene el modelo fiscal completo en la base de datos:
- liquidaciones del 303 y el 420 (borrador, ajustes con avisos, cierre, reapertura, presentación y asiento);
- el 390 y el 425;
- el 347 y el 415;
- los generadores de ficheros en TypeScript.

Para hacer las pantallas falta lo que hay entre el front y la base:
- **Backend.** El ADR-0013 (§4) fija un monolito modular en TypeScript con el que habla el front. No existe todavía, y la plataforma gestionada donde desplegarlo sigue pendiente.
- **Identidad y accesos.**
  - El ADR-0014 pide una tabla de pertenencia usuario–empresa desde el primer día, con usuarios (asesorías) que acceden a varios tenants, y la comprobación de la empresa en un único punto del backend.
  - El ADR-0015 define tres capas: plataforma, configuración de la empresa y roles (administrador de empresa y usuario), con el catálogo de permisos en el código.
  - Nada de esto existe en la plataforma.
  - Las funciones fiscales exigen `app.usuario` y `app.tenant_id` por transacción.
- **Front.** Las pantallas fiscales de `jmvv2023/activopro` (`fiscal/modelos/mod303.tsx`, `fiscal/index.tsx`) van contra el modelo antiguo: RPCs con schema por tenant, sin ajustes, versiones, reapertura ni asiento.

## Opciones consideradas

- **Framework:**
  - Fastify + zod (esquemas validados, OpenAPI para tipar el front);
  - Hono (más ligero y portable, ecosistema más joven);
  - NestJS (más estructura de serie y más ceremonia).
- **Identidad:** Supabase Auth, que ya usa el nuevo ActivoPro y cuyo token el backend valida sin depender del resto de Supabase, u otro proveedor gestionado.
- **Front:** rehacer las pantallas fiscales contra la API, o que convivan un tiempo con las actuales.
- **Orden:** la base del backend primero, o las pantallas primero con un backend provisional.

## Decisión

Decidido por José María el 2026-11-05:

1. **Backend con Fastify + zod**, en `activopro-platform/api`. Va en el mismo repositorio que el esquema, así que los tests de la API corren contra la misma base.
   - Organizado en módulos (`fiscal`, después el resto).
   - Las rutas validan entrada y salida con zod y publican OpenAPI, del que se generan los tipos del front.
2. **Identidad: Supabase Auth.**
   - El backend valida su JWT (JWKS del proyecto) y no usa nada más de Supabase.
   - El usuario de la plataforma se enlaza al sujeto del token.
3. **Base del backend antes que nada:**
   - **`usuario`** (persona, global): identidad del proveedor, email y estado.
   - **`usuario_acceso`** (usuario × tenant × empresa × rol): administrador o usuario (ADR-0015).
   - **`tenant_modulo`**: módulos contratados. Lo no contratado no aparece para nadie.
   - **Contexto de cada petición:**
     - token → usuario;
     - empresa elegida → acceso, comprobado en un único punto;
     - transacción con `app.tenant_id` y `app.usuario`;
     - permiso del catálogo (`modulo.accion`) según el rol.
   - **Operadores de Enumbers (capa 1)** con acceso explícito y auditado: se hacen cuando haga falta el panel de plataforma, no ahora.
4. **API fiscal fina:** cada endpoint llama a las funciones de la base (`app.borrador_liquidacion`, `app.ajustar_liquidacion`, `app.cerrar_liquidacion`…) y a los generadores de ficheros. La lógica no se duplica.
   - Permisos:
     - `fiscal.consultar` y `fiscal.preparar` (borrador, ajustes): los dos roles;
     - `fiscal.cerrar` (cerrar, reabrir, guardar versiones, registrar la presentación): los dos roles;
     - `fiscal.configurar` (régimen de deducción, prorrata, cuentas, suplidos): solo el administrador de empresa.
5. **Pantallas nuevas en `jmvv2023/activopro`** contra la API, con las convenciones actuales de UI (Refine + antd). Las antiguas se retiran al terminar. Orden:
   1. 303 y 420 (mismo motor);
   2. 390 y 425;
   3. 347 y 415;
   4. configuración fiscal de la empresa;
   5. ficha mínima de tercero para corregir NIF y provincia (lo que piden los avisos).

## Consecuencias

- Es el primer código de backend de la plataforma. Fija el patrón de los módulos siguientes: contexto por petición, transacción por tenant, permisos en un único punto, lógica de negocio en la base o en servicios, nunca en el front.
- El front deja de llamar a RPCs de Supabase en el módulo fiscal. El resto de módulos del nuevo ActivoPro sigue en el modelo antiguo hasta que se migre cada uno.
- **Pendiente:**
  - plataforma gestionada donde desplegar el backend (ADR-0013);
  - migración de usuarios desde GeneXus (ADR-0014): con la base del backend se puede cargar, sin contraseñas.
  - limpieza en Supabase cuando se despliegue: decidir si la plataforma va a un proyecto nuevo o al `activopro` actual, y retirar lo que sobre del modelo antiguo (schema `activoprobase`, RPCs `fiscal_*`…). Hasta ahora la plataforma solo ha corrido en local; en Supabase no se ha cambiado nada.
  - al terminar las pantallas fiscales: borrar las ramas `fiscal-plataforma`, `fiscal-anuales` y `fiscal-configuracion` de `jmvv2023/activopro` (ya fusionadas en #1, #2 y #3; se conservan por si hay algo que aprovechar).

## Origen

Conversación con José María, 2026-11-05.
