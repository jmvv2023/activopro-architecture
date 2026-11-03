---
id: 0016
title: Camino desde GeneXus — modo sombra con verificación automática y migración por olas de clientes
status: accepted
date: 2026-11-03
services: [core, all]
supersedes: null
superseded_by: null
---

## Contexto

ADR-0013 fija el destino. ADR-0003 establece la coexistencia temporal y que cada cliente migra completo. Falta el **cómo**: hasta ahora la migración no avanzaba porque no había forma de demostrar la paridad con GeneXus.

Datos de producción (`analysis/legacy/2026-11-modelo-datos-tenant.md`):

- 160 clientes (162 schemas menos 2 demos).
- Unos 20 millones de filas de negocio reales.
- No hay lógica de negocio en la base de datos: está toda en la KB de GeneXus.
- GeneXus guarda saldos por cuenta y mes (`saldos`, `saldoslevel1`): un oráculo de paridad gratuito para la contabilidad.
- Uso por módulo:

| Módulo | Clientes |
|---|---|
| Contabilidad | 157 |
| Conciliación bancaria | 134 |
| IVA (liquidación) | 118 |
| Cartera de pagos | 112 |
| Inmovilizado | 108 |
| Cartera de cobros | ~95 |
| Facturación | 79 |
| Stock | 59 |
| Lotes | 3 |

## Opciones consideradas

1. **Big bang por cliente cuando haya paridad total, verificada a mano.** Es lo que se hacía. No avanza: nunca hay confianza para migrar.
2. **Base de datos compartida con GeneXus** (estrangulador por pantallas). Hereda el modelo legacy y obliga a migrar dos veces (descartado en ADR-0013).
3. **Modo sombra**: ETL nocturno al modelo nuevo, recálculo y comparación automática con GeneXus; migración por olas de clientes según los módulos que usan.

## Decisión

Se adopta la opción 3. Es una estrategia, no un calendario: las olas y los momentos de cambio se ajustan a las necesidades de cada momento.

### Modo sombra

- **ETL nocturno** de cada cliente desde MySQL (solo lectura) a la plataforma nueva:
  - repetible e idempotente, con una tabla persistente que asigna a cada clave legacy su UUID;
  - convierte de `latin1` a UTF-8;
  - normaliza tipos;
  - pasa los blobs a almacenamiento de objetos;
  - excluye derivados (`ctacorriente`, `saldos*`), temporales, copias manuales (`bk_*`, `*_bak_*`, `fix_*`), tablas vacías y empresas no reales (ADR-0014).
- **La plataforma nueva recalcula** sus salidas sobre esos datos: saldos, libros y liquidaciones de IVA, modelos, amortizaciones, cartera…
- **Comparador automático** contra GeneXus, con informe por cliente y módulo. La primera comprobación: saldos por cuenta y mes frente a `saldoslevel1`.
- **Cada diferencia es una regla de negocio por descubrir**, que se documenta y se convierte en test.
- **La paridad se mide**: porcentaje de clientes idénticos por módulo.

### Olas de migración

- **Ola 1 — clientes sin facturación en ActivoPro** (~78). Módulos necesarios:
  - contabilidad;
  - IVA y modelos;
  - cartera de pagos y cobros;
  - inmovilizado;
  - conciliación bancaria;
  - informes configurables (ADR-0017).
- **Ola 2 — clientes con facturación**: añade facturación, VeriFactu, SEPA y remesas, artículos y tarifas, stock.
- **Ola 3 — casos especiales**: lotes, analítica por centros, gastos de viaje y clientes con patrones atípicos.
- Dentro de cada ola, primero los clientes que el modo sombra da como idénticos en los módulos que usan.
- **La unidad de migración es el tenant (cliente que contrata), no el schema** (03/11/2026): una asesoría migra con todas sus empresas a la vez, porque sus usuarios trabajan sobre todas. La ola de una asesoría la marca el módulo más exigente de sus empresas.
- **Fiscalidad especial antes de migrar**: además de la paridad de saldos, la ola tiene en cuenta el régimen fiscal (empresas de Canarias con IGIC y modelos 420/425, fundaciones y entidades sin fines lucrativos…), que exige que esos módulos fiscales estén listos.

### Cambio de un cliente

- **El cliente migra completo**, con todo su histórico. Los ejercicios cerrados quedan en solo lectura.
- **Momento recomendado**: justo después de presentar las declaraciones de un trimestre, para que ningún periodo fiscal abierto quede repartido entre dos sistemas. Se puede ajustar a cada cliente (por ejemplo, inicio de ejercicio).
- **Secuencia**:
  1. congelar en GeneXus;
  2. última carga del ETL;
  3. comparación;
  4. activación en la plataforma nueva;
  5. activación de los usuarios (ADR-0014).
- **Red de seguridad**: GeneXus queda en solo lectura para ese cliente durante un periodo tras el cambio.

### Consecuencia para el plan de construcción

El orden de construcción del nuevo ActivoPro se alinea con la ola 1: contabilidad, IVA y modelos, cartera, inmovilizado, conciliación bancaria e informes, antes que facturación.

## Consecuencias

- Hay criterio objetivo para migrar a un cliente.
- La lógica de negocio se extrae de datos reales, no se adivina.
- El primer cliente puede migrar sin esperar a la paridad de toda la plataforma.
- Hay que construir y mantener el ETL y el comparador; ambos se reutilizan en cada ola.
- Durante la coexistencia, un cambio de esquema en GeneXus puede romper el ETL; el ETL avisa de columnas o tablas inesperadas.
- MySQL sigue siendo la fuente de verdad de los clientes no migrados (ADR-0002).

## Origen

Conversación con José María del 02–03/11/2026.
