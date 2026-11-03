---
id: 0017
title: Informes configurables — plantillas estándar globales y personalización por empresa
status: proposed
date: 2026-11-03
services: [core, reporting]
supersedes: null
superseded_by: null
---

## Contexto

GeneXus guarda en cada schema la definición de los informes configurables (balances, PyG y similares): `definfcon`, `definfconceptos`, `definfconconceptos`, `definfconconceptoscta`, `definfconallconceptosidiomacon`, `definfconallidi`… Son unos 12 millones de filas en producción, en su mayoría copias idénticas de la plantilla estándar.

Requisito de José María (03/11/2026): **los informes que los clientes tienen personalizados deben seguir funcionando, y la posibilidad de personalizar se mantiene.**

## Opciones consideradas

1. **Copiar todas las definiciones a cada tenant**, como hoy. Simple, pero cada mejora del estándar hay que propagarla a 160 copias.
2. **Solo plantillas globales.** Incumple el requisito.
3. **Plantillas estándar globales y personalización por empresa.** El estándar vive una vez; una empresa solo guarda lo que ha cambiado.

## Decisión

Se adopta la opción 3:

- **Plantillas estándar globales** (balance, PyG, etc.), mantenidas por Enumbers y versionadas.
- **Una empresa usa el estándar por defecto.** Si personaliza un informe, se crea una **copia propia** a partir de la plantilla, que pasa a ser suya.
- Las mejoras del estándar llegan automáticamente a quien no ha personalizado. A quien sí ha personalizado se le avisa y decide si incorpora el cambio.
- **El motor de cálculo es único** para estándar y personalizados.

## Migración

- Para cada informe de cada empresa, el ETL compara su definición con la plantilla estándar:
  - **si es idéntica**, la empresa queda apuntando al estándar;
  - **si difiere**, se migra como informe personalizado de esa empresa.
- **Paridad**: el modo sombra (ADR-0016) compara los importes de cada informe entre GeneXus y la plataforma nueva, tanto estándar como personalizados.

## Consecuencias

- Los ~12 millones de filas replicadas se reducen al estándar más las personalizaciones reales.
- Se conserva la personalización y se mantiene la capacidad de personalizar.

## Pendiente

- Medir cuántas empresas tienen informes personalizados. Requiere identificar el schema de referencia de la plantilla y comparar.
- Valorar si el motor de `activopro-reporting`, que ya cuadra con los totales de GeneXus, sirve de base para el motor de informes de la plataforma nueva.
- Confirmar si las cuentas asociadas a conceptos (`definfconconceptoscta`) dependen del plan de cuentas de cada empresa. Si es así, la "plantilla" incluye reglas de asignación por rango de cuentas, no cuentas concretas.

## Origen

Conversación con José María del 03/11/2026.
