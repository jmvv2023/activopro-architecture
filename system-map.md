# Mapa del sistema

Estado a octubre de 2026. Fuente: conversaciones y notas de José María. Verificar contra cada
repo antes de confiar en un detalle concreto (puertos, rutas).

## Servidores

| Servidor | Uso | Notas |
|---|---|---|
| **Oxygen** (`157.97.66.27`, vCloud VM) | Producción del núcleo GeneXus: Tomcat 9, MySQL 8 | `contabilidad.activopro.net:8443`, contextos PROD y TEST. Se valora migrar fuera (caro para sus specs). |
| **IONOS** (`217.160.229.211`, Ryzen 8 núcleos, 64 GB, ~874 GB NVMe) | Microservicios (Docker Compose v1), backups, Nginx + Certbot | Mucha capacidad libre. |

Secuencia nocturna en Oxygen: parada Tomcat → despliegue → backup SQL → compresión → reinicio
MySQL → reinicio LibreOffice → arranque Tomcat. Backups con retención de 1 día (mejorable).

## Microservicios

| Micro | Repo | Stack | Dónde | Relación con el núcleo |
|---|---|---|---|---|
| ms-verifactu | `jmvv2023/ms-activopro-verifactu` | Node, MySQL, Supabase | Local :3003 → Oxygen, junto a GeneXus. 1.0.0 validada en preproducción (14/10/2026); pendiente de desplegar | SIF de VeriFactu de ActivoPro. Recibe facturas de GeneXus, calcula huella/QR, envía a AEAT y guarda la cadena en `verifactu_registro` (MySQL, fuente de verdad). Supabase: lotes y copia para el monitor, nunca dependencia; reglas del registro en el código (ADR-0004). Fallos: ADR-0011; rectificativas: ADR-0010. En PROD hoy solo un cliente tiene VeriFactu activo, por el flujo nativo de GeneXus; será el primero en pasar al micro (con semilla de cadena, ver `domain/verifactu.md`). Se elige por empresa con `MSVERACT`. Historia: `domain/verifactu-evolucion.md`. |
| ms-einvoice | `ms-activopro-einvoice` (verificar owner) | Node, SaxonJS | En desarrollo | Factura electrónica B2B (SPFE). Schema central `ms_einvoice` + outbox `ms_spfe_outbox` por tenant. |
| ms-ocr | `jmvv2023/ms-activopro-ocr` | Python FastAPI, SQLite | `ocr.activopro.net` (IONOS) | GeneXus (`OCR_ExtractJson`, `OCR_BuscarTercero`) vía patrón asíncrono POST/GET. |
| ms-docgenerator | verificar | Node, Puppeteer, Handlebars | `pdf.activopro.net` | Genera PDFs de factura/albarán/presupuesto. Plantillas montadas como volumen. |
| ms-fiscal-alerts | `jmvv2023/ms-activopro-fiscal-alerts` | Node, SQLite, React | `alertas.activopro.net`, API en `127.0.0.1:4400` | Recordatorios de obligaciones fiscales. Independiente del núcleo. |
| ms-import | `jmvv2023/ms-activopro-import` | Node + React + Python | Local (:3010 / :5173), Oxygen pendiente | Importa extractos bancarios y facturas e-commerce a MySQL de tenants. |
| reporting | `jmvv2023/activopro-reporting` | React/Vite/AntD + Node, Supabase/Postgres | `reportes.activopro.net`, `reportes-sync.activopro.net` | Lee `Saldos` / `SaldosLevel1` sincronizados desde MySQL. |
| ms-auth | verificar | Node, Alpine | `auth.activopro.net` | Recuperación de contraseña. GeneXus solo presenta. |
| ms-certificados | verificar | — | — | Fuera de la ruta crítica de VeriFactu (certificado viaja en el payload). Candidato a retirar. |

## Monorepos

- `jmvv2023/activopro-monorepo`: **público** — manual (Starlight) y webs de Enumbers y ActivoPro.
  No poner aquí nada interno.
- `activopro-platform`: nuevo ActivoPro (apps/web, supabase/, docs/). Los micros existentes
  **no** entran ahí (ADR-0001).

## Tablas del núcleo que tocan los micros

Mantener esta tabla al día: es lo que permite saber qué rompe un cambio de esquema en GeneXus.

| Tabla (schema del tenant) | Lee | Escribe |
|---|---|---|
| `facturas` | verifactu, einvoice (adaptador), docgenerator | verifactu (columnas `msFacVeri*` y `Fac*` de VeriFactu); GeneXus (resto). Lista exacta de columnas por escritor: pendiente de documentar |
| `verifactu_registro` | verifactu | verifactu |
| `ms_spfe_outbox` | einvoice | GeneXus (vía `sp_spfe_encolar()`) |
| `adjmovctas` | — | GeneXus (`print_attach`) |
| `movctas`, `Saldos`, `SaldosLevel1` | reporting, import | import |
| `acreedores`, `proveedor`, clientes | import, ocr | import |
