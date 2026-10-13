---
id: 0007
title: Versionado del SIF de VeriFactu según criterios estándar, requisito previo a producción
status: proposed
date: 2026-10-13
services: [verifactu]
supersedes: null
superseded_by: null
---

> **Decidido:** ms-verifactu, como SIF, debe tener gestión de versiones según criterios
> estándar, y es lo último que falta antes de pasar a producción.
> **Por concretar:** el esquema exacto (abajo, propuesta).

## Contexto

ms-verifactu es el Sistema Informático de Facturación de ActivoPro. Cada registro de
facturación identifica el sistema que lo generó, incluida su versión, y la declaración
responsable del productor va ligada a la versión del sistema. Sin un versionado disciplinado no
se puede saber qué código generó cada registro ni cuándo hace falta una nueva declaración.

## Propuesta (pendiente de validar)

- **SemVer** (`MAJOR.MINOR.PATCH`) para el micro: MAJOR para cambios que alteren el registro,
  la huella o el contrato con la AEAT o con GeneXus; MINOR para funcionalidad compatible; PATCH
  para correcciones.
- Una única fuente de la versión (p. ej. `package.json`) que se inyecta en el campo de versión
  del sistema de cada registro y se expone en `/health`.
- Tag de Git por versión y `CHANGELOG.md` con lo que cambia en cada una.
- Guardar en `verifactu_registro` la versión que generó cada registro.
- Revisar en cada MAJOR/MINOR si procede actualizar la declaración responsable.
- Verificar los campos exactos exigidos por la normativa (identificación del SIF, versión,
  número de instalación) contra la especificación técnica vigente de la AEAT.

Nota: el núcleo GeneXus usa Major.Minor.Release.Build para sus objetos; son esquemas distintos
y no deben mezclarse.

## Consecuencias

- Bloqueante para producción: no se activa `AEAT_ENV=pro` hasta tenerlo.
- Facilita trazar incidencias de huella (p. ej. registros generados con código antiguo).

## Origen

Indicación de José María (13/10/2026).
