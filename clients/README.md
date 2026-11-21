# Migraciones de clientes

Aquí van **proceso, decisiones y lecciones** de cada migración, nunca datos del cliente ni
volcados. Los scripts SQL viven en su propio repo o carpeta de trabajo; aquí se enlazan.

## Patrón general (extraído de Torro e INFINIT AIR)

1. Ensayo completo en local sobre copia, documentado como scripts numerados.
2. Validación contra el origen (sumas y saldos, diario, consultas agregadas sobre `movctas`).
3. Autorización (cliente o asesoría) antes de tocar PROD.
4. Ejecución en PROD replicando los scripts.

## Criterio: lo que informó el cliente no se toca (decisión de José María, 21/11/2026)

ActivoPro da el programa; no es asesor fiscal ni está autorizado por el dueño de los datos a cambiar sus clasificaciones. En una
carga al programa nuevo:

- **Se carga tal cual** lo que el cliente o su asesoría registró y declaró: operaciones, claves, declaraciones presentadas,
  liquidaciones, imputaciones. La carga no reclasifica nada para que encaje en las reglas nuevas.
- Las reglas de la plataforma valen para **lo que calcula de nuevo**. Si con ellas el resultado de un periodo ya declarado sale
  distinto, la diferencia es una **anomalía visible** (en la carga y en el modo sombra, marcada como explicada cuando se sabe por
  qué), nunca una corrección.
- Lo que la plataforma no puede guardar como estaba (una regla de integridad, un código sin equivalente en el catálogo) entra
  **sin asignar y señalado**, con el dato original guardado, para que lo resuelva el cliente; nunca con una traducción supuesta.
- Si hay que replicar lo declarado (una complementaria), se hace con los ajustes del propio modelo, con motivo, por el cliente.

Ejemplos: los servicios a clientes de fuera de la UE registrados como exportación (fuera del 347 de la plataforma; el programa
anterior los declaraba): no se reclasifican, el modo sombra los marca `exportacion_registrada`. Las retenciones con códigos sin
clave del 190 (PRO, PRN…): sin clave y con su código, a asignar por el cliente.
