# Convenciones de microservicios

## Estructura y despliegue

- Node.js (Python FastAPI cuando hay OCR/ML), Docker, despliegue en IONOS tras Nginx +
  Certbot. Repos en GitHub bajo `jmvv2023`.
- Código o plantillas montados como volumen externo para actualizar sin reconstruir imagen
  cuando tenga sentido.
- Puertos publicados en `127.0.0.1`, nunca en `0.0.0.0`; Nginx del host hace de proxy.
- Endpoints `/health` y `/ready`; `/stats` o `/monitor` restringidos por IP en Nginx.
- Docker Compose **v1** (1.29.2) en IONOS: el error `KeyError: 'ContainerConfig'` al recrear se
  resuelve parando y borrando el contenedor huérfano y haciendo `up -d`.
- Imágenes Alpine: instalar `tzdata` y fijar `TZ=Europe/Madrid`; `TZ` sola no basta. MySQL
  trabaja en hora local, así que no usar `toISOString()` para fechas que se comparan con MySQL.
- `better-sqlite3` no compila en Windows sin Build Tools: probar en Docker.

## Integración con GeneXus

- GeneXus Java envía **ISO-8859-1**: middleware de parseo propio, no `express.json()`.
- GeneXus 16 no tiene `JsonReader` y el parseo JSON manual es frágil: si GeneXus tiene que
  leer la respuesta, devolver **XML**.
- Todas las llamadas `HttpClient` por HTTPS (`Secure=1`, `Port=443`) para evitar Mixed Content.
- Para operaciones largas, patrón asíncrono: POST guarda y devuelve id; GET recoge.
- No hacer HTTP dentro de una transacción GeneXus con `Commit on exit`; llamar después del commit
  (precedente: `VF_EnviarMS_Caller`) o usar tabla outbox.
- `Encrypt64` de GeneXus no es estándar: no se descifra con DES/AES normal.
- Importes hacia JSON desde GeneXus: `Str(&x, 10, 2)`, no `ToFormattedString()`.

## Seguridad

- Nunca `.env` en Git. `.gitignore` desde el primer commit y `.env.example` con placeholders.
  Precedente: en ms-import se subió un `.env` real; hubo que rotar credenciales y purgar el
  historial con `git filter-repo`.
- Usuarios MySQL por micro con permisos solo sobre lo que necesitan.

## Tests

- Cada micro debe poder ejecutar sus tests sin acceso a PROD (`npm test` / `pytest`).
- Datos de prueba sobre la **copia local** de `mconta0048` o fixtures (en producción es una empresa real).
- Antes de afirmar que un fix no funciona, comprobar cachés y la versión desplegada
  (lección de ms-ocr: `/debug/version`, `_cache_hit`).
