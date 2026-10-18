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
- Envía con un único intento y actualiza el estado. Los pendientes anteriores del mismo NIF van
  en el mismo envío, en orden.
- Es idempotente: reenviar una factura nunca duplica el registro (NIF + serie + número +
  fecha + tipo).
- Serializa por NIF emisor con `GET_LOCK` y usa un pool de conexiones.
- Devuelve a GeneXus `C`/`E` y un código interno cuando no hay respuesta de la AEAT:
  - `9001`: sin acceso a la cadena en MySQL.
  - `9002`: cadena ocupada.
  - `9003`: registrado; envío a la AEAT en curso.
- Respeta el **control de flujo de la AEAT** por NIF (`TiempoEsperaEnvio` o 1.000 registros):
  lo que llega antes queda pendiente y sale en segundo plano, en un solo envío con los demás
  pendientes del NIF. GeneXus muestra `9003` como "en curso" (ampliación del 15/10/2026,
  issue #27 del micro).
- Para ese envío en segundo plano, el micro conserva el certificado del último envío de cada
  NIF **solo en memoria** (24 h). Tras un reinicio, los pendientes salen con la siguiente
  petición del emisor.

La tabla de respuestas está en `domain/verifactu.md`.

## Consecuencias

- Un fallo transitorio nunca rompe la cadena: el registro queda pendiente y sale solo.
- El usuario no tiene que hacer nada con un `9003`: la factura ya tiene huella y QR válidos.
- El certificado del cliente vive en la memoria del micro: no se expone el micro a Internet
  (aislamiento por máquina, `domain/verifactu.md`).

## Origen

Decisión de José María (13/10/2026): "genexus solo reenviar… la forma más limpia y menos
compleja". Envío en segundo plano y control de flujo: 15/10/2026 ("lo que se ha quedado
pendiente debe salir lo antes posible, y si es posible antes de que se entere el usuario").
