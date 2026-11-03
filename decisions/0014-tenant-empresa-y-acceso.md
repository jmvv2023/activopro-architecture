---
id: 0014
title: Tenant = cliente que contrata; empresa como dimensión con pertenencia usuario–empresa
status: accepted
date: 2026-11-03
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

ADR-0013 fija tablas compartidas con `tenant_id` y RLS. Falta decidir qué es un tenant y cómo encajan las empresas y los centros.

Hechos del sistema actual (ver `analysis/legacy/2026-11-modelo-datos-tenant.md`):

- Cada cliente tiene un schema `mconta####` (162 en producción).
- Cada schema admite hasta 4 empresas (`EmpCod` en la clave de 174 tablas) y se crea con las 4 preparadas. Solo unos 20 clientes tienen de verdad varias empresas.
- Una empresa puede tener varios centros (`empcen`).
- **Los usuarios son por empresa**: `usuarios` tiene `EmpCod` en la clave. Un usuario solo puede entrar en las empresas donde está dado de alta. El login elige schema y empresa (`EmpBase` = `mconta####$N`; `prueba_db.usuariosemp` y `select_emp_usu`).
- No existe ningún perfil que vea todas las empresas sin estar dado de alta en cada una. `SYSADM` se crea por defecto en todas las empresas.
- Contraseñas: `UsuPss` es MD5 sin sal en base64.

## Opciones consideradas

1. **Cada empresa es un tenant.** Aislamiento máximo entre empresas, pero rompe lo que hoy es un único cliente (contrato, usuarios, catálogos compartidos) en varios tenants y complica a los ~20 clientes multi-empresa.
2. **Tenant = cliente; empresa sin control de acceso** (todos ven todas las empresas del tenant). Más simple, pero es una regresión de seguridad para los clientes multi-empresa: usuarios que hoy no ven una empresa la verían.
3. **Tenant = cliente; empresa como dimensión con pertenencia usuario–empresa** comprobada en el backend. Mantiene exactamente el comportamiento actual.

## Decisión

Se adopta la opción 3:

- **Tenant = cliente que contrata** (hoy, un schema). Es la frontera de seguridad dura, con RLS forzada (ADR-0013).
- **`empresa_id` en todas las tablas de negocio.** Sin límite de número de empresas.
- **Tabla de pertenencia usuario–empresa desde el primer día.** La comprobación de empresa vive en un único punto del backend, con tests. No va en la RLS: un fallo ahí afectaría a otra empresa del mismo cliente, no a otro cliente. Si un cliente lo exigiera, puede añadirse a la RLS sin cambiar el modelo.
- **El centro es un atributo de la empresa** (documentos, series, analítica), no un permiso.
- **Identidad delegada** en un proveedor gestionado (ADR-0013). Un usuario es una persona con un único login, aunque hoy exista repetido en varias empresas.
- **Login:** usuario + contraseña (y MFA cuando aplique). Una vez dentro, el usuario elige empresa en un desplegable con las empresas a las que tiene acceso; si solo tiene una, entra directamente. Puede cambiar de empresa sin volver a hacer login. Sustituye al login actual de empresa + usuario + contraseña.
- **Roles y permisos:** ADR-0015.

## Migración

- **Varios schemas por cliente (asesorías), 03/11/2026:** un cliente que contrata puede tener varios schemas. Una asesoría es la cliente de ActivoPro y cada empresa que lleva es un schema (p. ej. mconta0065, 0075, 0077, 0091, 0098, 0105 y 0114 son de la misma asesoría). Todos sus schemas migran a **un único tenant** (la asesoría) con una empresa por cada empresa real de cada schema, y los usuarios de la asesoría pasan a ser un único login con acceso a esas empresas. La correspondencia schema → cliente que contrata se obtiene de `prueba_db` (usuarios con acceso a varias bases) y la confirma Enumbers.

- **Empresas:** solo se migran las reales (con apuntes, facturas u otros datos, o con NIF informado). Los huecos preparados no.
- **Usuarios:** se migran los que tienen `UsuBaj = 'N'`. Un mismo `UsuCod` en varias empresas del schema se convierte en un único usuario con pertenencia a esas empresas.
- **Usuarios de plantilla** de baja (`CONTABLE`, `EMPRESA`, `FACTURAS`, `USUARIO`…): no se migran.
- **Contraseñas:** no se migran (MD5 sin sal). Cada usuario establece la suya en el primer acceso, mediante un enlace de activación a su email. Los usuarios sin email (`UsuMail` vacío) necesitan que el administrador del cliente lo informe antes de migrar.
- **`SYSADM`:** es la cuenta de soporte de Enumbers; no se migra (ADR-0015).

## Consecuencias

- El comportamiento de acceso es idéntico al actual para todos los clientes.
- Los clientes multi-empresa ganan un login único para todas sus empresas.
- Se elimina el límite de 4 empresas por cliente.
- La migración necesita email válido por usuario.

## Pendiente

- Comprobar si `empcen` tiene también centros preparados vacíos.

## Origen

Conversación con José María del 03/11/2026 (datos de `mconta0037`, recuento de producción y tabla `usuarios`).
