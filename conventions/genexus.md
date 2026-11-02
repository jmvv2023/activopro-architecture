# GeneXus 16 U8 — gotchas conocidos

Una sesión autónoma no puede editar ni compilar la KB. Esto sirve para diseñar y revisar.

## Despliegue

- "Build with this only" no despliega: hay que copiar los `.class` a mano a
  `WEB-INF/classes` del contexto Tomcat y recargar desde el manager.
- Procedimientos nuevos requieren Build All.
- **Columnas nuevas:** el `ALTER` debe aplicarse en los ~160 schemas antes de desplegar el
  código que las usa. La KB y las BDs reales pueden estar desfasadas (precedente sep 2026:
  `facturas` con 82 columnas en la KB y 93 en las BDs). Comprobar siempre ambas.
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
- Variables nuevas: declararlas siempre con su tipo (basado en atributo cuando aplique). Si no,
  GeneXus asume un tipo (`C(40)`, `N(10.2)`) y métodos como `IsEmpty()` dejan de reconocerse.
- Tras recompilar, recargar por completo las pantallas abiertas: un formulario de la versión
  anterior provoca 403 al enviar eventos.
- `BC.Save()`: comprobar `Success()` y mostrar el error. Varios fallos silenciosos (facturas que
  no llegaban a crearse) venían de no hacerlo.
- Nunca credenciales en el código de los objetos (precedente: contraseña SMTP en
  `WpImPresupuesto`). Van en parámetros o configuración del servidor.

## UI

- La personalización visual sobrevive a Build All con `activopro-skin.css` aplicado vía
  `post-build.bat` y componentes JS que ocultan el original e inyectan HTML (menú lateral).
- Clases Java propias que extienden `com.genexus.GXProcedure` cuando falta una capacidad nativa.
