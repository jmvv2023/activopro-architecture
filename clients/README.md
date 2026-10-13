# Migraciones de clientes

Aquí van **proceso, decisiones y lecciones** de cada migración, nunca datos del cliente ni
volcados. Los scripts SQL viven en su propio repo o carpeta de trabajo; aquí se enlazan.

## Patrón general (extraído de Torro e INFINIT AIR)

1. Ensayo completo en local sobre copia, documentado como scripts numerados.
2. Validación contra el origen (sumas y saldos, diario, consultas agregadas sobre `movctas`).
3. Autorización (cliente o asesoría) antes de tocar PROD.
4. Ejecución en PROD replicando los scripts.
