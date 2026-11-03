---
id: 0015
title: Permisos en tres capas — plataforma (Enumbers), configuración de empresa y muy pocos roles de usuario
status: proposed
date: 2026-11-03
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

En GeneXus, los permisos son bloqueos por usuario, empresa, programa y acción (`usuprg1`). Análisis de producción (`analysis/legacy/2026-11-modelo-datos-tenant.md`, `patrones-bloqueo-usuarios.csv`):

- 1.053 usuarios activos, 101 patrones de bloqueo distintos.
- El 58 % no tiene bloqueos; los 4 patrones más frecuentes cubren el 83 %.
- Los patrones frecuentes bloquean la administración (usuarios, seguridad, accesos, plan de cuentas).

Según José María, estos bloqueos **mezclan tres cosas distintas**:

1. **Funciones reservadas a Enumbers.** Por ejemplo, el alta de usuarios: se cobra por usuario, así que solo la hace Enumbers. `SYSADM` es la cuenta que usa Enumbers en todas las empresas; los clientes no la usan.
2. **Parametrización de la empresa**: ocultar módulos o funciones que la empresa no usa. Muchos patrones bloquean IGIC (`IDecIgic`, `ILibRegIgi`, `IComCAdu`…), que en la práctica significa "esta empresa no tributa por IGIC", no "este usuario no puede".
3. **Roles de usuario** propiamente dichos.

## Opciones consideradas

1. **Replicar el modelo actual** (bloqueos por usuario y acción). Fiel, pero perpetúa la mezcla y obliga a mantener 101 patrones.
2. **Roles personalizables por el cliente desde el inicio.** Flexible, pero más complejo y sin demanda demostrada.
3. **Separar las tres capas y empezar con muy pocos roles.** Cada cosa se configura donde le corresponde; los roles se amplían cuando haya demanda.

## Decisión

Se adopta la opción 3.

### Capa 1 — Plataforma (Enumbers)

- Operadores de Enumbers con **identidad propia** (persona, no cuenta compartida) y MFA obligatorio. Sustituye a `SYSADM`, que no se migra.
- Funciones exclusivas de la plataforma:
  - alta y baja de tenants y empresas;
  - alta y baja de usuarios y número de usuarios contratados;
  - módulos contratados por el cliente.
- El acceso de soporte a los datos de un tenant es explícito y auditado: queda registrado quién entra, cuándo, en qué tenant y con qué motivo. No es una pertenencia permanente del operador al tenant.

### Capa 2 — Configuración de la empresa

- **Módulos contratados** (por tenant): lo que el cliente paga. Lo que no está contratado no aparece para nadie.
- **Parametrización de la empresa**: lo que aplica a esa empresa (régimen IVA o IGIC, SII, centros de coste, stock y lotes, gastos de viaje…). Lo que no aplica no aparece para nadie de esa empresa.
- Ambas son configuración, no permisos de usuario. Las gestionan Enumbers (contratación) y el administrador de la empresa (parametrización, dentro de lo contratado).

### Capa 3 — Roles de usuario (dentro de cada empresa)

Se empieza con **dos roles**:

| Rol | Puede |
|---|---|
| Administrador de empresa | Todo lo contratado y parametrizado, incluida la configuración de la empresa (series, plan de cuentas, parámetros, ejercicios). No da de alta usuarios (capa 1) |
| Usuario | Operar en todos los módulos contratados y parametrizados. Sin acceso a la configuración de la empresa |

- El rol se asigna por usuario y empresa (ADR-0014).
- El catálogo de permisos vive en el código (`módulo.acción`); los roles son conjuntos de permisos. Añadir un rol nuevo (por ejemplo, solo consulta) o roles personalizables es una evolución sin cambio de modelo, cuando haya demanda.
- El control se aplica en un único punto del backend, con tests. El front solo oculta.

## Migración

- **`SYSADM`:** no se migra; se sustituye por operadores de Enumbers (capa 1).
- **Rol de cada usuario**, aplicando la regla de que nadie gane acceso:
  - sin bloqueos de administración → Administrador de empresa;
  - con bloqueos de administración (usuarios, seguridad, accesos, plan de cuentas…) → Usuario.
- **Bloqueos de módulos fiscales o funcionales** (IGIC, SII, lotes…): se convierten en parametrización de la empresa cuando afectan a todos sus usuarios.
- **Patrones a medida** (~176 usuarios, la mayoría de 1–2 por patrón): Enumbers los revisa al migrar ese cliente y decide rol o parametrización. Si un caso no encaja en ninguno, es una señal de demanda para un rol nuevo.

## Consecuencias

- Desaparece la cuenta compartida `SYSADM`; el acceso de Enumbers queda personal y auditado.
- La configuración de qué aparece en pantalla pasa a depender de la empresa y de lo contratado, no de cada usuario.
- El modelo de permisos es pequeño y comprensible; algunos usuarios con bloqueos muy concretos (minoría) pueden notar diferencias, que se revisan cliente a cliente.
- La gestión de usuarios queda en manos de Enumbers, coherente con el cobro por usuario.

## Pendiente

- Confirmar que una fila de `usuprg1` significa "acción bloqueada" y el significado de `UsuSegAccEst`.
- Lista de módulos contratables y de parámetros de empresa (se define con el diseño de cada módulo).

## Origen

Conversación con José María del 03/11/2026 y análisis de patrones de bloqueo en producción.
