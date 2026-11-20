# Costes y despliegue de la plataforma — noviembre 2026

Foto del 20/11/2026 de lo hablado con José María: qué cuesta hoy la infraestructura, qué costaría la plataforma, dónde se
despliega y qué hay que ajustar de seguridad. Cifras sin IVA; Supabase factura en dólares (cambio aproximado 0,9 €/$) a Enumbers con
inversión del sujeto pasivo, así que el IVA no es coste.

## Hoy

| Servicio | € / mes |
|---|---|
| Oxygen: GeneXus, Tomcat y MySQL de producción | ~434 |
| IONOS, servidor dedicado AR8-64 (8 núcleos, 64 GB, 2 × 960 GB NVMe en RAID 1): copias nocturnas de producción y micros | 98 |
| IONOS, VPS 2 vCore / 4 GB (Cloud Server XL) | 30 |
| IONOS, Microsoft Exchange (1 licencia) | 10 |
| **Total** | **~572** |

## Tamaño de producción (MySQL, 20/11/2026)

103 GB en los schemas `mconta%`, de los que:

- ~83 GB son ficheros dentro de la base: adjuntos de asientos (`adjmovctas`, 81 GB, ~477.000), facturas, inmovilizado, modelos.
  En la plataforma van al archivo, no a la base (ADR-0057).
- ~4 GB son catálogos repetidos en cada schema (`localidad`, `divisasvigencia`, informes definibles): en la plataforma, una sola vez.
- ~3 GB son temporales y tablas recalculables.
- ~12 GB son datos de verdad (`movctas` 7,6 GB con índices, cartera, facturas y líneas…).

Estimación en Postgres: **10–20 GB de base y ~85 GB de archivo**.

## Supabase para la plataforma

Plan Pro: 25 $/mes con 10 $ de crédito de cómputo (cubre solo el Micro). El cómputo se paga por proyecto. Disco: 8 GB incluidos y
0,125 $/GB. Archivo: 100 GB incluidos y 0,021 $/GB. Tráfico de salida: 250 GB incluidos. Copias diarias de 7 días incluidas; PITR,
100 $/mes por 7 días.

| | $ / mes |
|---|---|
| Pro | 25 |
| Producción en Medium (4 GB): 60 − 10 de crédito | 50 |
| Proyecto de demostración y desarrollo (Micro) | 10 |
| Disco por encima de 8 GB | ~3 |
| Archivo (dentro de los 100 GB al principio) | 0 |
| **Total** | **~88 (~80 €)**; con PITR, ~188 |

Medium es la propuesta para empezar; se mide con la primera ola de clientes y se pasa a Large (8 GB, +50 $) solo si hace falta.

## Despliegue

- **Plataforma (API, worker y Gotenberg) en el dedicado de IONOS**, junto a los micros: le sobra capacidad (necesita 2–3 GB, sobre
  todo por Chromium) y no tiene coste añadido. El VPS de 4 GB se queda corto.
- **Durante la convivencia**: ~572 + ~80 = **~652 €/mes**.
- **Destino** (sin Oxygen): dedicado, VPS, Exchange y Supabase, **~218 €/mes**; ~188 si el VPS no hace falta. Ahorro de unos
  4.300–4.650 € al año. Si el dedicado deja de recibir copias de MySQL y basta un servidor menor para la copia propia de Supabase
  (`pg_dump` diario, recomendable), bajaría a ~130–150 €/mes.
- Oxygen: los clientes entran directamente a la aplicación; la lista de IPs protege el servidor y las bases, y la IP de IONOS está
  en ella para llevarse las copias. El dedicado de IONOS tiene el SSH limitado por IP.

## Seguridad pendiente (tarea de infraestructura)

El dedicado sirve aplicaciones abiertas a internet (micros y, mañana, la plataforma) y guarda las copias nocturnas de producción de
todos los clientes. Una vulnerabilidad en una aplicación no entra por SSH sino por el 443, y la lista de IPs no la para:

1. Comprobar qué abre el cortafuegos (panel de IONOS y `ufw` / `iptables`): 80 y 443 para todos; SSH y el resto, solo IPs de Enumbers.
2. Que ningún contenedor monte la carpeta de las copias, y que la carpeta solo la lea la cuenta que las recibe (sin los permisos
   abiertos que se encontraron en Oxygen).
3. Aplicaciones en contenedores con usuario sin privilegios.
4. A medio plazo, sacar las copias del dedicado a un almacenamiento de objetos.

## Proyecto Supabase `activopro`

Además de la demo de la plataforma (`activopro_platform`), en `public` están los datos de Reporting (`activopro-reporting`): saldos
reales de producción sincronizados cada noche (~315 MB). El modelo anterior del front se retiró y quedó en cuarentena el
20/11/2026 (esquema `retirado` y `retirado_*`, para borrar tras comprobar que Reporting sigue bien). Pendiente: sacar Reporting a su
propio proyecto; con él dentro, el proyecto está cerca del límite de 500 MB del plan gratuito.
