# GeneXus 16 U8 — gotchas conocidos

Una sesión autónoma no puede editar ni compilar la KB. Esto sirve para diseñar y revisar.

## Despliegue

- "Build with this only" no despliega: hay que copiar los `.class` a mano a
  `WEB-INF/classes` del contexto Tomcat y recargar desde el manager.
- Procedimientos nuevos requieren Build All.
- En el servidor los ficheros son de `tomcat9`: `sudo cp` + `chmod 644` a un directorio propio
  para descargarlos.
- Versionado Major.Minor.Release.Build. Control de versiones en GeneXus Server
  (`enumbers.genexusserver.com`).

## Lenguaje y transacciones

- `Commit on exit` sobrescribe campos escritos por otros procesos dentro de la misma unidad de
  trabajo. No cambiarlo en `ContaFacVen` ni `CalcFacVen2`.
- `for each` anidados pueden provocar conflictos de cursor silenciosos (filas duplicadas en grids).
- Los Supertypes son de solo lectura: usar `FromXml`/`ToXml` y colecciones paralelas en memoria.
- `return` dentro de eventos o subrutinas de Web Panels provoca navegación inesperada: usar
  `if/else`.
- Las Transactions recargan atributos desde la BD; `error()` en reglas sobre variables no es fiable.
- `Event After Trn` no siempre se dispara según el ciclo de la Transaction.
- Las recompilaciones pueden perder propiedades de controles (p. ej. `Multi` de `uploadify1`).

## UI

- La personalización visual sobrevive a Build All con `activopro-skin.css` aplicado vía
  `post-build.bat` y componentes JS que ocultan el original e inyectan HTML (menú lateral).
- Clases Java propias que extienden `com.genexus.GXProcedure` cuando falta una capacidad nativa.
