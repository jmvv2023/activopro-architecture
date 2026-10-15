---
id: 0007
title: Versionado del SIF de VeriFactu con SemVer, implementado en la versión 1.0.0
status: accepted
date: 2026-10-13
services: [verifactu]
supersedes: null
superseded_by: null
---

## Contexto

ms-verifactu es el Sistema Informático de Facturación de ActivoPro. Cada registro de
facturación identifica el sistema que lo generó, incluida su versión, y la declaración
responsable del productor va ligada a la versión del sistema. Sin un versionado disciplinado no
se puede saber qué código generó cada registro ni cuándo hace falta una nueva declaración.

## Decisión

El versionado queda implementado en la **versión 1**, antes de pasar a producción:

- **SemVer** (`MAJOR.MINOR.PATCH`). Primera versión de producción: **1.0.0**.
  MAJOR para cambios que alteren el registro, la huella o el contrato con la AEAT o con
  GeneXus; MINOR para funcionalidad compatible; PATCH para correcciones.
- Fuente única: `version` de `package.json`, inyectada en `<sf:Version>` de cada registro y
  expuesta en `/health`.
- Columna `sif_version` en `verifactu_registro` con la versión que generó cada registro.
- Tag de Git por versión y `CHANGELOG.md`.
- En cada MAJOR o MINOR, revisar si procede actualizar la declaración responsable.
- Verificar los campos exigidos (identificación del SIF, versión, número de instalación) contra
  la especificación técnica vigente de la AEAT.

Nota: el núcleo GeneXus usa Major.Minor.Release.Build para sus objetos; son esquemas distintos
y no deben mezclarse.

## Consecuencias

- Bloqueante para producción: no se activa `AEAT_ENV=pro` hasta tenerlo (issue #7 del micro).
- La columna nueva exige el script en todos los schemas antes de desplegar.
- Facilita trazar incidencias de huella (registros generados con código antiguo).

## Origen

Decisión de José María (13/10/2026).
