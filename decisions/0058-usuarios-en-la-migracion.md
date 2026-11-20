---
id: 0058
title: Los usuarios del programa anterior se cargan preparados y se invitan al activar el cliente
status: proposed
date: 2026-11-20
services: [platform]
supersedes: null
superseded_by: null
---

## Contexto

La carga de un cliente trae su contabilidad, terceros, cartera, tesorería, almacén y analítica, pero no sus usuarios: hoy cada
usuario se da de alta a mano en la consola de Enumbers y se invita por correo (ADR-0043). Con más de 300 usuarios eso no escala y
es fuente de errores (H-100).

En el programa anterior el usuario es por schema y empresa (`usuarios`: `EmpCod`, `UsuCod`, nombre, contraseña, baja, idioma,
correo opcional), con permisos por programa y acción (`segprg`, `segprgaccion`, `usuprg1`) y un registro de entradas (`acceso`). Una
misma persona de una asesoría aparece en varios schemas con códigos distintos. `SYSADM` está en todas las empresas y es de Enumbers.

En la plataforma la identidad es la de Supabase Auth (el correo), el acceso es por empresa con dos roles (administrador y usuario,
ADR-0015), las plazas contratadas se cuentan por cliente (`tenant.usuarios_contratados`) y el soporte de Enumbers va por accesos
temporales (ADR-0043, fase 3), no por un usuario dentro de cada empresa.

Las contraseñas no se pueden llevar: el formato es otro y, además, el usuario debe poner la suya al entrar por primera vez.

## Opciones consideradas

1. **Cargar los usuarios preparados, sin invitar** — el ETL crea por persona (por correo) su acceso a las empresas del cliente con
   el rol propuesto, en un estado «por invitar»; Enumbers revisa la lista en la consola y los invita en bloque el día que el cliente
   pasa a la plataforma. Nadie recibe un correo durante las pruebas del modo sombra.
2. **Invitar al cargar.** Más simple, pero manda correos a clientes que todavía trabajan en el programa anterior y que aún no deben
   entrar (la carga se repite varias veces en el modo sombra).
3. **Seguir a mano en la consola.** Sin trabajo nuevo, pero es lo que hoy no escala.

## Decisión

Opción 1. Propuesta concreta:

- **Quién**: los usuarios sin baja (`UsuBaj`), sin `SYSADM`, con correo. Los que no tienen correo salen como aviso en la carga y en
  la consola, para pedírselo al cliente; no se inventa ninguno. Una persona = un correo (sin distinguir mayúsculas), aunque esté en
  varios schemas: si son del mismo cliente, un usuario con acceso a todas sus empresas.
- **Rol**: administrador quien tiene acceso a los programas de seguridad y configuración en `usuprg1`; usuario el resto. Es una
  propuesta que Enumbers puede cambiar antes de invitar; los permisos por programa no se migran.
- **Idioma**: el de `IdiCod` (como el dashboard: 1 es, 2 ca, 3 en, 4 fr, 7 gl, 9 pt).
- **Plazas**: la carga avisa si los usuarios activos pasan de las contratadas; no bloquea, decide Enumbers.
- **Actividad**: de `acceso` solo se usa la fecha de la última entrada, para que la consola marque a quien lleva más de un año sin
  entrar (candidato a no invitar). El registro de entradas no se migra.
- **Consola**: en el cliente, «Usuarios por invitar» con su rol y empresas, editable, y **Invitar** (uno, varios o todos), que usa el
  mismo camino que hoy (`app.plataforma_preparar_invitacion` / `plataforma_invitar` y el correo de Supabase Auth, H-032).

## Consecuencias

- La activación de un cliente es un paso de la consola, no un trabajo a mano por usuario.
- Hace falta un estado nuevo del acceso («preparado») que no ocupa plaza ni da entrada hasta invitarse, y un export de `usuarios`,
  `usuprg1` y la última fecha de `acceso` en `exportar-terceros.cmd` (o uno propio).
- Antes de implementar: confirmar qué programas de `segprg` cuentan como «seguridad y configuración» (lista a sacar de producción) y
  arreglar el correo de invitación (H-032), que hoy sale en inglés.

## Origen

Análisis `analysis/2026-11-paridad-programa-anterior.md` (20/11/2026); hueco H-100 de `activopro-platform/docs/manual/huecos.md`.
