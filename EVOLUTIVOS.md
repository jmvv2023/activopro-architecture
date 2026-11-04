# Evolutivos posibles

Mejoras sobre lo que hace hoy ActivoPro (GeneXus) que no forman parte de la migración. Se anotan aquí al detectarlas.
Ninguna está decidida: entrar en la lista no es un compromiso. Cada una indica de dónde sale y si la plataforma nueva ya la deja preparada.

## Fiscal

| Evolutivo | Situación hoy | Preparado en la plataforma |
|---|---|---|
| **303 rectificativo con el justificante de la presentación anterior.** Al volver a cerrar un periodo ya presentado, el fichero sale marcado como autoliquidación rectificativa, con el nº de justificante de la anterior. | GeneXus deja esas posiciones en blanco; la rectificativa se hace a mano en la sede. | Sí: cada versión guarda el justificante y la fecha de presentación (`app.registrar_presentacion`). Falta rellenar el fichero. |
| **Página 04 del 303** (exonerados del 390, prorrata). | GeneXus la genera. | No: el generador da error en esos casos. Necesario antes de migrar a esos clientes, así que es más migración que evolutivo. |
| **Régimen simplificado y complementarias del 303.** | No previsto en GeneXus. | No. |
| **Tipos especiales en el 303** (0 %, 2 %, 5 %, 7,5 % y sus recargos). | En `IVA_303_2017` las casillas 150, 165 y 153 leen las tres la subcuenta 000000 y el 5 % (000500) no tiene casilla. Sin cotejar con el diseño de registro oficial. | Da error con esos tipos en lugar de suponer una casilla. |
| **Ventas al 0 % registradas como exentas** (mconta0037, de 1T2023 a 3T2024). | Las clasifica el cliente; afectaría a lo presentado en esos trimestres. | Para revisar con el cliente; no es de la plataforma. |
| **Compensación de periodos anteriores automática** (casilla 110 a partir de la liquidación anterior). | Se teclea a mano en GeneXus. | Próximo paso del hilo IVA (ADR-0019). |

## Seguridad

Ver `REVISION-PENDIENTE.md`: credenciales en la KB y riesgo de inyección SQL en `cambia_usupss`.
