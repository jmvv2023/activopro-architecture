---
id: 0043
title: Alta de clientes, empresas y usuarios (consola de Enumbers) y puesta en marcha de la empresa
status: proposed
date: 2026-11-15
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

Al escribir el manual de la plataforma, el inventario de lo que existe y no se ve encontró el hueco que más bloquea (H-001): no se
puede dar de alta un cliente, una empresa, su plan de cuentas ni sus usuarios desde la plataforma. Hoy solo lo hace el script de
la demo, o el ETL cuando se carga un cliente de GeneXus.

ADR-0015 ya decidió **quién** lo hace: las funciones de la capa de plataforma (alta y baja de clientes y empresas, usuarios y número
de usuarios contratados, módulos contratados) son exclusivas de Enumbers. Las hacen operadores con identidad propia y MFA, y
sustituyen a `SYSADM`. ADR-0014 decidió el modelo: el cliente es un tenant, sus empresas cuelgan de él y los usuarios tienen acceso
por empresa con un rol. Lo que falta es **cómo**: dónde, con qué datos y qué recibe la empresa al nacer.

Lo que ya existe:

- `tenant`, `empresa`, `usuario`, `usuario_acceso` (rol administrador o usuario, desde–hasta) y `tenant_modulo`.
- Al crear una empresa, los triggers le dan las formas de pago iniciales, el catálogo inicial (unidades, tarifa general) y el
  almacén principal.
- `app.alta_ejercicio` y el plan de cuentas por empresa (`app.alta_cuenta`). Muchas cuentas se crean solas al usarse: impuestos,
  terceros, tesorería, caja, existencias.
- Datos fiscales de la empresa en `empresa_config_fiscal`, `empresa_actividad` y `empresa_representante`.

Lo que falta:

- La empresa no sabe en qué territorio fiscal está: si liquida IVA o IGIC se deduce de sus registros, y una empresa canaria nueva
  aparece como de IVA hasta su primer registro.

## Decisión

### 1. Consola de Enumbers dentro de la misma aplicación

- Una sección **Plataforma** en el mismo front y la misma API, con su propio catálogo de permisos (`plataforma.*`).
- Los operadores son usuarios marcados en una tabla `operador`. La API exige además que la sesión tenga MFA (nivel `aal2` del JWT
  de Supabase Auth); sin él, la consola no responde.
- Cada acción de la consola queda en `plataforma_evento`: quién, cuándo, sobre qué cliente o empresa, qué y con qué motivo.
- Un operador no tiene acceso a los datos de los clientes por ser operador. El acceso de soporte a un tenant, explícito, temporal y
  con motivo (ADR-0015), es la fase 3.

### 2. Alta de cliente y de empresa

El operador da de alta el **cliente** (tenant): nombre, módulos contratados y número de usuarios contratados. Un cliente se puede
**bloquear** con motivo: sus usuarios no entran y sus datos no se tocan. Después, una o varias
**empresas**, cada una con:

- nombre o razón social, NIF y si es persona física o jurídica;
- **territorio fiscal**: común, Canarias, Ceuta y Melilla, País Vasco o Navarra. Decide el impuesto de la empresa: IVA, IGIC o
  ninguno. Así deja de deducirse de los registros. Los territorios forales se pueden elegir, pero sus modelos no están en la
  plataforma y se avisa;
- **plan contable**: PGC o PGC de pymes;
- **primer ejercicio**: fecha de inicio, natural por defecto, creado con `app.alta_ejercicio`;
- periodicidad del impuesto: trimestral, o mensual si está en devolución mensual o en el SII (se guarda en la configuración fiscal);
- persona física: apellidos y nombre, que piden los modelos.

Al crear la empresa se copia el **plan modelo** (punto 3) y se ejecutan los triggers de siempre.

### 3. Plan modelo de la plataforma

- Catálogo global de solo lectura `plan_modelo` / `plan_modelo_cuenta`: el plan con el que GeneXus crea las empresas nuevas (schema
  `moperbase`), **completo**: títulos y subcuentas de los 12 planes, en castellano, catalán e inglés (normal y pymes, persona física,
  fundaciones de Cataluña, entidades sin fines lucrativos). El plan 52 (THEOS, de un cliente) no se ofrece. El de Canarias
  (`moperbase_ser`) es el mismo salvo dos títulos de IVA que no usa: no hace falta un catálogo aparte.
- `app.copiar_plan_modelo(empresa, plan)` lo copia al crear la empresa. Después el plan es de la empresa y evoluciona con ella. Las
  cuentas que no están en el plan (impuestos por tipo, terceros, bancos…) se siguen creando al usarse.
- El ETL ya no sobrescribe el catálogo con el plan del export de un cliente; un plan del cliente que no está en el catálogo queda guardado
  sin ofrecer.

### 4. Usuarios por invitación

- El operador escribe el email, las empresas y el rol en cada una. La API invita con Supabase Auth: el usuario recibe un enlace y
  pone su contraseña, como en la migración (ADR-0014).
- `usuario` queda pendiente hasta el primer acceso. El operador puede reenviar la invitación o retirarla.
- No se pueden tener más usuarios activos que los contratados por el cliente. Ocupa plaza quien tiene un acceso vigente a alguna empresa
  del cliente, también el invitado que aún no ha entrado. Un usuario con acceso a varios clientes (asesorías) cuenta en cada cliente.
  La plaza se comprueba antes de mandar el correo. Un cliente cargado antes de la consola, sin número, no tiene límite.
- Quien ya tiene login (otro cliente, la migración) no recibe correo: se le da el acceso.
- El primer acceso lo registra la plataforma al entrar el usuario. El enlace del correo lleva a una pantalla del front para poner la
  contraseña.
- Dar de baja un acceso pone fecha `hasta`. Un usuario no se borra.
- La invitación necesita la clave de servicio de Supabase en la API. Va en el `.env`, nunca en Git, y solo la usan las rutas de la
  consola.

### 5. Puesta en marcha de la empresa

- La portada de la empresa muestra al administrador una lista **Puesta en marcha** con lo hecho y lo pendiente. Cada punto lleva a
  su pantalla:
  - datos fiscales y actividad;
  - ejercicio;
  - cuentas de liquidación del impuesto;
  - series de facturación;
  - cuentas de banco y caja;
  - formas de pago;
  - saldos de apertura (el asiento de apertura del primer ejercicio, a mano);
  - terceros.
- La lista no bloquea trabajar y desaparece al completarse o al descartarla.
- Cada punto se calcula de los datos (`app.puesta_en_marcha(empresa)`), no se marca a mano. Si algo se deshace, vuelve a aparecer.

## Fases

1. Consola: operadores con MFA, auditoría, alta de cliente y empresa, territorio fiscal, plan modelo, módulos y usuarios
   contratados, invitaciones.
2. Puesta en marcha: la lista en la portada y las pantallas que falten (datos fiscales de la empresa, asiento de apertura).
3. Acceso de soporte auditado a un tenant.

## Opciones descartadas

- **Aplicación aparte para Enumbers:** duplica el acceso, los permisos y los despliegues para una sección que usa muy poca gente.
- **Plan vacío o copiado de otra empresa como única vía:** un plan vacío obliga a dar de alta lo básico a mano. Copiar de otra
  empresa no sirve para el primer cliente de una asesoría y arrastra lo que tenga la empresa de origen. Copiar de otra empresa
  puede añadirse después como opción.
- **Contraseña provisional:** circula una contraseña por canales que no controlamos, y la invitación ya es el camino de la
  migración.
- **Asistente obligatorio al primer acceso:** bloquea a quien solo quiere consultar o tiene la empresa a medias, y no sirve a las
  empresas cargadas de GeneXus, que ya están preparadas.

## Consecuencias

- La plataforma puede recibir un cliente nuevo sin scripts.
- El impuesto de la empresa sale de su configuración y no de sus registros. Las empresas cargadas de GeneXus reciben su territorio
  en el ETL.
- La API necesita la clave de servicio de Supabase para invitar. Es un secreto nuevo en el `.env`.
- Habrá que dar de alta a los operadores de Enumbers y que activen el MFA antes de usar la consola.

## Pendiente

- El alta y la baja de operadores desde la consola (en la fase 1, a mano en la base).
- Facturación a clientes por usuarios y módulos (fuera de la plataforma).

## Origen

Conversación con José María del 15/11/2026. Decisiones: consola en la misma aplicación, plan modelo más cuentas creadas al usarse,
usuarios por invitación por email y puesta en marcha como lista en la portada. El mismo día, con los schemas `moperbase` y
`moperbase_ser`, se concretó el plan modelo (el catálogo completo de GeneXus) y se implementó la fase 1 (activopro-platform #110).
