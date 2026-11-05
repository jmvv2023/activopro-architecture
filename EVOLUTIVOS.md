# Evolutivos posibles

Mejoras sobre lo que hace hoy ActivoPro (GeneXus) que no forman parte de la migración. Se anotan aquí al detectarlas.
Ninguna está decidida: entrar en la lista no es un compromiso. Cada una indica de dónde sale y si la plataforma nueva ya la deja preparada.

## Fiscal

| Evolutivo | Situación hoy | Preparado en la plataforma |
|---|---|---|
| **303 rectificativo con el justificante de la presentación anterior.** Al volver a cerrar un periodo ya presentado, el fichero sale marcado como autoliquidación rectificativa, con el nº de justificante de la anterior. | GeneXus deja esas posiciones en blanco; la rectificativa se hace a mano en la sede. | Sí: cada versión guarda el justificante y la fecha de presentación (`app.registrar_presentacion`). Falta rellenar el fichero. |
| **Página 04 del 303 con el diseño vigente** (exonerados del 390: actividades, 347, territorio, volumen de operaciones). | GeneXus genera una página 04 con el diseño antiguo (prorrata por CNAE, casillas 500–504) y en la página 01 marca al revés el «volumen anual distinto de cero» (posición 129: pone «2» cuando hay operaciones). | Sí, con el diseño DR303e26v101 (activopro-platform #29). |
| **Régimen simplificado y complementarias del 303.** | No previsto en GeneXus. | No. |
| **Tipos especiales en el 303** (0 %, 2 %, 5 %, 7,5 % y sus recargos). | En `IVA_303_2017` las casillas 150, 165 y 153 leen las tres la subcuenta 000000 y el 5 % (000500) no tiene casilla: en mconta0037, 3T2024, quedaron sin declarar en [153] 218.081,51 € de base al 5 %. | Sí, por periodo según las instrucciones de la AEAT (activopro-platform #33). Para revisar con los clientes afectados lo ya presentado. |
| **390 de 2025: deducible al 2 %, 5 % y 7,5 % forzado a 0** (`Mode390_25`), aunque el diseño oficial lo admite ([695]–[698], [724]/[725]). En mconta0037 faltan 2.456,26 € de IVA deducible y el 390 no cuadra con los 303. El devengado a esos tipos sí debe ir a 0. | Corrección en GeneXus; afecta a cualquier cliente con compras a esos tipos recibidas en 2025. | La plataforma suma lo declarado y no tiene el problema. |
| **Modelos forales (País Vasco, Navarra): 303/390 de Bizkaia, Gipuzkoa, Álava y Navarra**, con su propia numeración de casillas y diseño. | Hoy no hay clientes en esos territorios. | Hay que contemplar la evolución: el territorio fiscal es atributo de la empresa (ADR-0016) y las casillas y el fichero se generan por modelo, así que un territorio nuevo es otro mapeo y otro generador, no un cambio del modelo de IVA. |
| **390: marca de declaración del 347 automática** (página 01, «Declaración anual de operaciones con terceras personas»). | GeneXus la escribe siempre a «0» («No en AP»). | Configurable por empresa y sin marcar por defecto; se rellenará sola cuando el 347 esté en la plataforma. |
| **Ventas al 0 % registradas como exentas** (mconta0037, de 1T2023 a 3T2024). | Las clasifica el cliente; afectaría a lo presentado en esos trimestres. | Para revisar con el cliente; no es de la plataforma. |
| **Prorrata en ISP e importaciones (IGIC/IVA)**: la parte no deducida no aparece en el resumen (`&pornodedu` sin asignar en `GenResIgic`/`GenResIva`), y un ejercicio en prorrata sin porcentaje dado de alta deduce al 0 % sin avisar (mconta0032, 1T2025: 341,32 €). | Corrección en GeneXus; lo segundo afecta a lo que el cliente presentó y debe revisarlo él. | Sí: cuota entera y deducible por registro (ADR-0021); el 0 % queda como anomalía en la carga. |
| **Regularización por la prorrata definitiva del IGIC automática** (420 [39], 425 [93]). | En GeneXus la definitiva y el importe se teclean a mano en el resumen del 4T (`GenResIvaExtras`, línea 903); solo para el IVA hay cálculo (`PorrataDef`). | Sí: `app.prorrata_definitiva` la propone en el último periodo, editable con lápiz y aviso (ADR-0022). |
| **Prorrata definitiva sin las rectificativas de ventas** (`PorrataDef`: solo LiqIvaTpo 1). | GeneXus calcula la definitiva sin las modificaciones de bases del año. En mconta0013 2024 da 87 % en vez de 86 %, y se presentó una regularización de 94,28 € a favor del cliente que con el criterio correcto sería 0. | La plataforma las incluye (ADR-0022). Para revisar con el cliente o su asesor lo ya presentado. |
| **Ventas con inversión del sujeto pasivo en el 303** (diario 49). | GeneXus las declara como no sujetas por reglas de localización [120] y deja siempre a 0 la [122] «operaciones sujetas con inversión del sujeto pasivo» (`IVA_303_2017`). En mconta0124 son unos 3 M€ desde 2024. | Sí: operación `venta_isp`, a la [122] y al volumen [125] del 390. |
| **Regularización de bienes de inversión automática** (303 [43], 420 [37], 425 [91]): registro de bienes con su periodo de regularización (5 años, 10 los inmuebles), cálculo en el último periodo de cada año cuando la prorrata definitiva se separa más de 10 puntos de la del año de compra, y regularización única si se vende dentro del periodo. | GeneXus no la calcula: el importe se teclea en el resumen del último periodo (`GenResIvaExtras`, `&RegBienInv`). En los clientes revisados no procede (mconta0013, único con prorrata y bienes de inversión, no varía 10 puntos y sus bienes de 2016–2020 ya han cumplido el plazo). | Parcial: la casilla se ajusta con lápiz, motivo y aviso, y el asiento la lleva a IVAINV. El registro de bienes se construirá cuando migre un cliente que lo necesite. |
| **Fichero del 420 para el programa de ayuda de la ATC** (`.atc`, importable en `pa-mod420.jar`). | GeneXus no genera fichero: el 420 se teclea en el programa de ayuda. | Parcial: la plataforma cierra el 420 con borrador (ADR-0022). Referencia del formato: `erseco/facturascripts-plugin-ModelosIGIC` (AGPL-3.0: se usa el formato, los ejemplos ficticios y el codificador oficial para un test byte a byte, sin copiar su código). Siguiente paso del hilo IGIC tras el 347/415. |
| **Compensación de periodos anteriores automática** (casilla 110 a partir de la liquidación anterior). | Se teclea a mano en GeneXus. | Próximo paso del hilo IVA (ADR-0019). |

## Contabilidad

| Evolutivo | Situación hoy | Preparado en la plataforma |
|---|---|---|
| **Saldos desfasados frente a los apuntes.** | En mconta0124 los saldos de mayo de 2026 llevan una factura de compra (2.550 + 535,50 € de IVA, proveedor 4000/000133) que ya no tiene apuntes: GeneXus no actualizó la tabla de saldos al borrarla o cambiarla. | Sí: los saldos se mantienen por trigger y se recalculan con `app.recalcular_saldos`. En GeneXus se arregla regenerando los saldos del cliente. |

## Seguridad

Ver `REVISION-PENDIENTE.md`: credenciales en la KB y riesgo de inyección SQL en `cambia_usupss`.
