# Multi-tenancy en ActivoPro

- Cada cliente tiene **su propio schema** MySQL `mconta####`. No comparten tablas; solo el
  login dirige a un schema u otro.
- Algunos schemas contienen **varias empresas** (`EmpCod`). Todo lo que sea por emisor
  (cadena VeriFactu, numeración SPFE) va por **NIF / empresa, no por schema**.
- GeneXus obtiene el schema de `EmpBase.EmpBase` quitando lo que va tras `$`
  (p. ej. `mconta0048$1` → `mconta0048`).
- **Recursos compartidos aunque los schemas estén aislados:** el proceso MySQL (buffer pool,
  I/O) y el proceso Tomcat (heap, pool de conexiones). Un tenant muy grande afecta a todos.
- **Tenant de pruebas:** `mconta0048`. Es el único sobre el que se trabaja en tareas autónomas.
- **Alta de schema nuevo:** hoy los objetos de los micros (p. ej. `verifactu_registro`, grants
  de `usrVerifactu`, outbox SPFE) se crean a mano. Pendiente: scripts idempotentes que los
  apliquen a todos los schemas.
- Charset: tablas legacy en `latin1`; GeneXus Java envía ISO-8859-1. La conversión a UTF-8 se
  hace en un único punto (el adaptador del micro).
