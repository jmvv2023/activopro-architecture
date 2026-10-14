---
id: 0011
title: VeriFactu — el micro resuelve los fallos; GeneXus solo reenvía
status: accepted
date: 2026-10-13
services: [verifactu, core]
supersedes: null
superseded_by: null
---

## Contexto

Entre el commit de la factura en GeneXus y la respuesta de la AEAT pueden fallar muchas cosas:
MySQL, la red, la AEAT, o que lleguen dos facturas del mismo emisor a la vez. GeneXus 16 tiene
muy poca capacidad para gestionar estados y reintentos (ADR-0004). Si se le reparte la lógica
de fallos, el resultado es complejo y frágil.

## Decisión

GeneXus queda fuera de la gestión de fallos. **Lo único que hace es reenviar.** El micro:

- Guarda cada registro como `pendiente`, con su XML, **antes** de enviarlo a la AEAT. La huella
  y el QR ya son válidos en ese momento.
- Envía con un único intento y actualiza el estado. Los pendientes anteriores del mismo NIF se
  reenvían en orden con la siguiente factura.
- Es idempotente: reenviar una factura nunca duplica el registro (NIF + serie + número +
  fecha + tipo).
- Serializa por NIF emisor con `GET_LOCK` y usa un pool de conexiones.
- Devuelve a GeneXus `C`/`E` y un código interno cuando no hay respuesta de la AEAT:
  - `9001`: sin acceso a la cadena en MySQL.
  - `9002`: cadena ocupada.
  - `9003`: registrado y pendiente de envío.

La tabla de respuestas está en `domain/verifactu.md`.

## Consecuencias

- Un fallo transitorio nunca rompe la cadena: el registro queda como pendiente y sale después.
- Un pendiente solo se reenvía cuando llega otra petición del mismo emisor, ya sea una factura
  nueva o un reenvío. El reintento en segundo plano está planteado en el issue #27 del micro, y
  el problema es cómo disponer del certificado sin una petición.

## Origen

Decisión de José María (13/10/2026): "genexus solo reenviar… la forma más limpia y menos
compleja".
