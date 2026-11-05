---
id: 0024
title: Un tercero por NIF con roles; la cuenta enlaza el rol
status: accepted
date: 2026-11-05
services: [core]
supersedes: 0023 (solo la decisión 1)
superseded_by: null
---

## Contexto

El ADR-0023 (decisión 1) cargaba una ficha de tercero por cada ficha de GeneXus, sin fusionar por NIF. GeneXus tiene una tabla por rol (`clientes`, `proveedores`, `acreedores`, `bancos`), así que la misma persona aparece varias veces y con el nombre escrito distinto en cada ficha.

El nuevo ActivoPro (`jmvv2023/activopro`, proyecto Supabase `activopro`) ya lo resolvió de otra manera:
- `terceros` con NIF único;
- `tercero_roles` (cliente, proveedor, acreedor, empleado, banco);
- `tercero_config` por rol: cuenta contable, IRPF, vencimientos, IBAN, SEPA, `incluir_347`, intracomunitario.

**mconta0037** (1.069 fichas) tiene 25 NIF repetidos:
- 21 entre roles distintos:
  - 13 cliente + proveedor;
  - 2 acreedor + banco con el NIF de relleno `00000000T`;
  - el resto con acreedor.
- En 17 de esos 21 el nombre está escrito distinto.
- 4 repetidos dentro del mismo rol: dos fichas de cliente con su 430 cada una.

Los NIF de relleno («varios», «diversos»: `00000000T`, `B00000000`…) tienen la letra de control válida, así que no se detectan validando.

## Opciones consideradas

1. **Una ficha por ficha de GeneXus** (ADR-0023). Replica la inconsistencia: el usuario ve varias fichas de la misma persona con nombres distintos.
2. **Un tercero por NIF con roles, como el nuevo ActivoPro.** La identidad (NIF, nombre, país, provincia) es una sola. Lo propio de cada rol cuelga del rol.

## Decisión

Decidido por José María el 2026-11-05: opción 2.

1. **`tercero`**:
   - es por empresa (como GeneXus y la contabilidad; compartirlo entre las empresas de un cliente puede venir después);
   - el NIF es único salvo los de relleno (`nif_generico`) y los terceros sin NIF, que no fusionan.
2. **`tercero_rol`**:
   - un rol por tercero: cliente, proveedor, acreedor, banco o empleado;
   - guarda las fichas de GeneXus de las que sale y con qué nombre estaban;
   - la configuración por rol (cuenta, IRPF, cobros…) se añadirá con facturación y cartera.
3. **La cuenta enlaza el rol** (`cuenta.tercero_rol_id`), no el tercero:
   - la 430 es del rol cliente y la 400 del proveedor, así que en cada apunte se sabe con qué rol actúa el tercero;
   - un rol puede tener varias cuentas;
   - dos fichas del mismo rol con el mismo NIF quedan como un tercero con varias cuentas.
4. **Al fusionar, el nombre se hereda de la primera ficha**: la de la cuenta con el movimiento más antiguo (con empate, por rol y código).
   - Las discrepancias de nombre, país o provincia quedan como anomalía de la carga para que el cliente las revise.
   - Las pantallas identifican siempre de forma inequívoca el rol con que actúa el tercero.

## Consecuencias

- **Encaja con el nuevo ActivoPro**: misma separación entre tercero, rol y configuración por rol.
- **El 347 y el 415 agrupan por NIF** desde un tercero ya único. Los de NIF de relleno o sin NIF salen con aviso y no se suman entre sí.
- **mconta0037**:
  - de 1.069 fichas salen 1.043 terceros con 1.064 roles;
  - 19 terceros tienen varios roles y 4 roles vienen de varias fichas;
  - 19 discrepancias de nombre y 4 de provincia quedan para revisión del cliente.
- Las fichas que no se fusionan por NIF de relleno o sin NIF se depurarán con facturación.

## Origen

Conversación con José María, 2026-11-05 (revisión del modelo de terceros del nuevo ActivoPro).
