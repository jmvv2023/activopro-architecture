---
id: 0041
title: Almacén (existencias, lotes, entradas, inventario y coste) y documentos de venta (presupuestos, albaranes y devoluciones)
status: accepted
date: 2026-11-13
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

ADR-0040 dejó el catálogo de venta hecho (familias, productos, unidades, tarifas y precios pactados) y separó el stock en un
módulo propio, **Almacén**, que se contrata aparte y lleva sus propios permisos. El stock va ligado a la venta: el albarán es
lo que saca la mercancía, la factura agrupa albaranes y el abono la devuelve. Por eso este ADR cubre las dos cosas: el almacén
y los documentos de venta que lo mueven.

La referencia es **TORRO** (`mconta0037`), el único cliente con almacén y lotes. Trabaja con albaranes sin presupuesto, factura
agrupando albaranes y hace abonos parciales y abonos que agrupan varias facturas. La lógica de abonos con lotes se corrigió en
GeneXus en octubre de 2026 (`PStockActualiza`, marcas «NUEVO 20102026 / 28102026»).

### Lo que hay en GeneXus

- **Existencias por partida doble que se desincroniza.**
  - Por un lado, `artistock`: cantidad por artículo y centro, con el centro 9999 si la empresa no usa centros. También guarda
    mínimo, máximo, reservas y precio medio.
  - Por otro, los lotes: lo que queda es lo entrado − lo salido ± las regularizaciones.
  - Hay procesos para recuadrar las dos cuentas: `StkRegularizaStkLot` («el dato bueno es el de la ficha»), `StkVerificaDif`
    y `CargaStockinicial`.
- **Almacén = centro** (`empcen`), el mismo centro que reparte la analítica.
- **Entrada de género** (`TLote`): es un «lote/partida», numerado por año (`LOT`).
  - La cabecera lleva el proveedor (si no hay, uno genérico, `PGENLOT`), la referencia de la factura del proveedor
    (`LotFraPro`, texto), un número de orden de compra y gastos de compra (`lotgastos`, por concepto de `comgas`).
  - Cada línea lleva el artículo, el lote del proveedor, la caducidad, la cantidad, el precio de compra, el precio recomendado,
    la ubicación, los bultos y unidades por bulto, los palés y la tara.
  - Se entra por cantidad o por bultos (`STKENTG`; TORRO, por cantidad).
- **Salida al servir.** Al guardar un albarán, o una factura sin albarán, `PStockActualiza` asigna los lotes:
  - en orden FIFO por fecha de entrada, o eligiéndolos (`STOCK` = FIFO / SELECT; TORRO, FIFO);
  - y guarda en `faclinlote` qué lote sirvió cada línea y cuánto.
  - Con stock insuficiente, avisa o bloquea según `STOCKMSG` (TORRO: aviso).
- **Facturar albaranes** (`FacAlbaran`): uno o varios albaranes del cliente pasan a una factura.
  - La factura copia las líneas y los lotes, con una línea de texto «Albarán nº … de …» delante de cada uno.
  - El albarán queda en estado B (facturado). Se puede filtrar por dirección de envío (`STOCKDIR`).
- **Abono.** La rectificativa vuelve a meter en el lote de origen lo devuelto, como regularización de entrada (`tlotartreglevel1`
  con la factura).
  - Busca el lote en la factura rectificada y, si no está, en el albarán de origen; así cubre el abono que agrupa productos de
    varias facturas.
- **Regularización de lote** (`TLotArtReg`): mermas, unidades devueltas al proveedor y otras entradas, con observación y
  usuario.
- **Precio medio**: la media de los precios de compra de los lotes abiertos, recalculada en cada entrada. No es un método
  reconocido (cambia al cerrar un lote) y no lleva los gastos de compra.
- **Regularización de existencias contable** (`IngExistencia`, concepto 88): asiento de variación de existencias, mensual o de
  apertura, por centro y con la última fecha en `FCHEXIST` (TORRO: 31/12/25).
- **Venta por cajas** (`STOCKCAJ`, `ArtUniCaj`): TORRO la usa. Las cajas se muestran también en las regularizaciones.
- **Reservas** de stock por pedido y por factura (`PStockReserva`), con mínimos y máximos solo para aviso.
- **Albarán de terceros** (`AlbaranTer`): albarán de compra pendiente de factura, contabilizado contra 4009 / 4109 (`ALBTP`,
  `ALBTA`). Es un documento contable, no de stock.
- **Precios pactados** (`cliarticulostarifa`): por cliente, **dirección** y artículo, con vigencia desde–hasta. Pueden ser un
  importe o **una tarifa**.

### Lo que hay en la plataforma

- Catálogo (ADR-0040):
  - `producto` con `clase` producto/servicio, unidad con decimales, código y EAN;
  - familias con cuentas;
  - tarifas por vigencia, precio pactado (precio o % de descuento, desde–hasta, por cliente) y tarifa del cliente y de su
    dirección de envío, sin fechas.
- Factura emitida (ADR-0031 y ADR-0036):
  - borrador → emitida inmutable, con líneas comerciales que guardan producto y unidad;
  - rectificativa en su serie, con varias facturas rectificadas;
  - `fecha_operacion` para VeriFactu.
- Factura recibida con el desglose a mano; no usa el catálogo.
- Plan de cuentas, asientos de origen no editable y la regla de periodos (B1) para enganchar asientos generados.

## Opciones consideradas

### 1. Alcance y empaquetado

1. **Documentos de venta en Facturación, existencias en Almacén** (recomendada).
   - El presupuesto y el albarán son documentos de Facturación: los usan clientes sin almacén. Cada uno tiene sus estados y
     puede convertirse en factura o no (ver el punto 7 bis).
   - Con el módulo Almacén contratado, el albarán, la factura sin albarán y el abono mueven existencias de los productos con
     control de stock.
   - Almacén son las existencias, los almacenes, los lotes, las entradas, el inventario y el coste.
2. **Todo en Almacén.** El albarán solo existiría con el módulo. Deja fuera a quien usa albaranes sin stock (hoy los hay: ADR-0009).

### 2. Cómo se llevan las existencias

1. **Un libro de movimientos** (recomendada).
   - Un único registro `movimiento_stock`: producto, almacén, lote, fecha, cantidad con signo, coste y documento de origen
     (entrada, albarán, factura, abono, traspaso, regularización, inventario).
   - Las existencias por producto, almacén y lote son un saldo mantenido por trigger y recalculable, como los saldos contables
     (ADR-0018).
   - No hay contadores que se puedan tocar a mano ni dos verdades que recuadrar.
2. **Contadores como GeneXus** (`artistock` más los lotes). Es lo que hoy obliga a regularizar diferencias.

### 3. Almacenes

1. **Almacén como entidad propia** (recomendada).
   - Por empresa: código, nombre, dirección, activo. Toda empresa con el módulo nace con uno («Principal»).
   - Traspaso entre almacenes: una salida y una entrada con el mismo coste y lote.
   - Sin relación con los centros analíticos, que cuando lleguen serán otra cosa.
2. **Reutilizar los centros**, como GeneXus. Mezcla analítica y logística, y la plataforma aún no tiene centros.

### 4. Lotes y caducidad

1. **Por producto, opcionales, con FIFO o FEFO y selección manual** (recomendada).
   - En la ficha de Almacén del producto: `controla_stock`, `controla_lotes` y `controla_caducidad`. Los servicios nunca
     controlan stock.
   - Un lote es (producto, código): el código propio, numerado por año como en GeneXus, y además el del proveedor, la caducidad
     y la entrada de la que sale.
   - Al servir, los lotes se asignan según la empresa:
     - FIFO, por fecha de entrada: por defecto, como TORRO;
     - o FEFO: primero lo que caduca antes, útil en alimentación.
   - Siempre se pueden cambiar a mano en la línea.
   - La línea guarda qué lotes sirvió (trazabilidad: de un lote, a qué clientes fue; de una venta, de qué entradas sale).
2. **Solo FIFO automático**, como GeneXus.

### 5. Coste (valoración)

1. **Precio medio ponderado (PMP) móvil por producto y almacén** (recomendada).
   - Cada entrada recalcula: (existencia × PMP + cantidad × coste) / (existencia + cantidad).
   - El coste de entrada es el precio de compra más los gastos de compra repartidos por importe.
   - La salida va al PMP del momento y da el coste y el margen de la venta.
   - Corregir una entrada pasada recalcula los costes desde su fecha (`app.recalcular_costes`, como `app.recalcular_saldos`).
   - El lote guarda su coste de entrada para información. Es un método admitido por el PGC (norma 10.ª).
2. **FIFO de coste por lote**: cada salida, al coste del lote que sirve. Más exacto con lotes, pero un ajuste en una entrada
   vieja cambia el coste de ventas ya hechas, y sin lotes obliga a llevar capas de coste igualmente.
3. **Como GeneXus** (media de los lotes abiertos). No es un método reconocido y no lleva los gastos de compra.

### 6. Entradas de mercancía (compras)

1. **Entrada de género como documento propio, enlazable con la factura recibida** (recomendada).
   - La entrada lleva proveedor, fecha, almacén y número de albarán del proveedor, más sus líneas: producto, cantidad, precio,
     lote del proveedor, caducidad, ubicación y bultos. Lleva también los gastos de compra.
   - Al confirmarla mueve stock.
   - Después se enlaza con la factura recibida (una o varias entradas en una factura), con aviso si no coinciden cantidades o
     precios. La factura no mueve stock por sí sola.
   - Si la factura llega con otro precio, se corrige el coste de la entrada (y con él el PMP desde esa fecha).
   - El asiento provisional de mercancía recibida sin factura (4009, el «albarán de terceros» de GeneXus) queda para después y
     es opcional.
2. **Entrada solo desde la factura recibida** con líneas de producto. Más simple, pero el género llega y se vende antes que la
   factura (TORRO trabaja así).

### 7. Salidas: albarán, factura y abono

1. **Albarán de venta con su serie, y facturación de albaranes** (recomendada).
   - Borrador → confirmado (con número; mueve stock) → facturado. Un albarán se puede anular si no está facturado, y la
     anulación devuelve el stock.
   - Facturar albaranes: uno o varios del mismo cliente, y opcionalmente de la misma dirección de envío, en una factura en
     borrador.
     - La factura lleva las líneas del albarán con su referencia (número y fecha) y la fecha de operación de cada albarán
       para VeriFactu.
     - Cada albarán queda enlazado y facturado.
   - La factura hecha de albaranes no vuelve a mover stock. La factura sin albarán lo mueve al emitirse. Un borrador no mueve
     nada, pero avisa del disponible.
   - Abono (rectificativa): sus líneas negativas devuelven el género al lote de la línea original (de la factura o de su
     albarán), también cuando agrupa varias facturas.
     - Por línea se puede marcar «no vuelve a stock» (roto, caducado): entra y sale como merma.
     - También hay albarán de devolución, para devolver sin abonar todavía.
2. **Sin albarán:** el stock solo se mueve con la factura. Deja fuera a TORRO.

### 7 bis. Presupuestos y conversión de documentos

Lo decidido en GeneXus (ADR-0009) se mantiene como flujo, sin sus estados en clave (H, I, K, L, J):

- **Presupuesto**, con su serie:
  - borrador → enviado → aceptado, no aceptado o caducado (por fecha de validez);
  - se puede hacer sin cliente dado de alta, pero para aceptarlo hace falta el cliente;
  - no mueve stock.
- **Desde un presupuesto aceptado:**
  - **albaranes**, con entregas parciales: cada línea lleva lo entregado y lo pendiente, y el presupuesto queda «pendiente de
    entrega» hasta servirlo todo o darlo por terminado;
  - o **la factura directamente** (borrador), si no hay entrega.
  - Una vez convertido, no vuelve atrás: para rehacerlo se anula lo generado.
- **Albarán**:
  - confirmado → facturado, o «no se factura» (entregas sin cargo, que quedan registradas);
  - se puede anular mientras no esté facturado.
- **Factura**: de uno o varios albaranes, de un presupuesto o directa. Siempre por el camino de la emitida (borrador → emitida
  con VeriFactu): no hay ningún camino de facturación fuera de él, que es el fallo que ADR-0009 cerró en GeneXus.
- Cada documento sabe de dónde viene y en qué se convirtió (presupuesto → albaranes → factura → abono), y se ve en su ficha.

### 8. Stock insuficiente

1. **Política por empresa: avisar (por defecto, como TORRO) o bloquear** (recomendada).
   - Con aviso, las existencias pueden quedar negativas.
   - En productos con lotes, lo que no tiene lote que lo cubra queda «pendiente de lote» (visible en Almacén). La próxima
     entrada lo cubre o se regulariza.
2. **Bloquear siempre.** Impide facturar cuando la entrada aún no está registrada, que pasa a diario.

### 9. Inventario, regularización y contabilidad

1. **Regularizaciones con motivo, recuento de inventario y asiento de existencias propuesto** (recomendada).
   - Regularización: entrada o salida suelta, con su motivo (merma, rotura, caducado, devolución a proveedor, recuento, otros)
     y su observación.
   - Recuento: se cuenta un almacén (o una familia) a una fecha. El programa propone la diferencia con lo que hay y, al
     confirmar, crea las regularizaciones.
   - Valoración a una fecha: existencias × PMP por almacén, familia y producto.
   - Asiento de variación de existencias, mensual o al cierre, propuesto desde la valoración. Las cuentas salen de la familia
     (existencias 30x y variación 610/71x) y el asiento es de origen no editable y se rehace en el sitio, como `IngExistencia`.
2. **Solo regularizaciones**, sin asiento: la variación de existencias se seguiría haciendo a mano.

### 10. Unidades, cajas y bultos

1. **Unidad de stock = unidad del producto, con unidades por caja** (recomendada).
   - La ficha de Almacén del producto puede tener unidades por caja, y opcionalmente por palé. Así se teclea y se muestra en
     cajas (TORRO vende por cajas), pero se guarda en unidades.
   - Tara, palés y bultos de la entrada quedan como información de la línea.
2. **Varias unidades con conversiones** (kg ↔ caja ↔ palé con factores libres). Más potente, pero ningún cliente lo necesita hoy.

### 11. Precios por cliente y periodo

El catálogo ya tiene el precio pactado por cliente con fechas (precio o % de descuento) y la tarifa del cliente y de su
dirección, sin fechas. GeneXus permite además pactar por dirección y que lo pactado sea «usar la tarifa X» durante un periodo.

1. **Completar el catálogo** (recomendada).
   - La tarifa asignada al cliente (o a la dirección) pasa a tener vigencia desde–hasta, con historial.
   - El precio pactado puede ser de una dirección y puede ser «tarifa X».
   - La resolución sigue siendo: pactado → tarifa de la dirección → del cliente → general, todo a la fecha.
2. **Dejarlo como está**: lo de por dirección y por periodo se resolvería con varios precios pactados a mano.

### 12. Lo que queda fuera de este ADR

- Pedidos de cliente con reserva de stock.
- Pedidos a proveedor y propuesta de compra por mínimos.
- Varias divisas en tarifas.
- Ubicaciones como entidad (pasillo, estante).
- Números de serie por unidad.

Los mínimos y máximos por producto y almacén sí entran, solo como aviso de reposición.

### 13. Módulo y permisos

- **Almacén**: módulo `almacen`, con estos permisos:
  - `consultar`: existencias, movimientos, lotes, trazabilidad y valoración;
  - `preparar`: entradas, traspasos y regularizaciones;
  - `inventario`: recuentos y asiento de existencias;
  - `configurar`: almacenes, política de lotes y de stock insuficiente, y cuentas.
- **Albaranes**: dentro de `facturacion`, con los mismos permisos que la factura (`preparar` y `emitir`).
- Con Almacén contratado, el coste y el margen se ven con `almacen.consultar`.

## Decisión

Decidido por José María el 13/11/2026 (7 bis incluido):

- **1.1** Presupuestos y albaranes son documentos de Facturación, con sus estados y su conversión en factura o no, para todos los
  clientes. Con Almacén contratado, además mueven existencias.
- **5.1** PMP móvil por producto y almacén, con los gastos de compra.
- **6.1** Entrada de género propia, enlazable con la factura recibida.
- **8.1** Stock insuficiente según la empresa: avisar (por defecto) o bloquear.

Y con la recomendación del análisis:

- 2.1 Libro de movimientos con existencias por trigger y recalculables.
- 3.1 Almacén propio, con traspasos.
- 4.1 Lotes y caducidad opcionales por producto; FIFO o FEFO por empresa y selección manual.
- 7.1 Albarán con facturación de albaranes; el abono devuelve al lote original.
- 7 bis. Presupuesto con aceptación, entregas parciales y conversión a albarán o factura, como ADR-0009.
- 9.1 Regularizaciones, recuento y asiento de existencias propuesto.
- 10.1 Unidades por caja.
- 11.1 Tarifa del cliente con vigencia y pactado por dirección o con tarifa.

### Fases

1. **Documentos de venta** (sin Almacén):
   - presupuesto, albarán y albarán de devolución, con sus series y estados;
   - aceptación y entregas parciales;
   - facturar uno o varios albaranes y factura desde presupuesto;
   - trazabilidad entre documentos.
2. **Almacén base**:
   - almacenes y ficha de Almacén del producto;
   - libro de movimientos y existencias;
   - lotes y caducidad;
   - entradas de género con gastos;
   - traspasos, regularizaciones y recuento;
   - PMP;
   - consulta de existencias, movimientos y trazabilidad de lotes.
3. **Venta con stock**:
   - salida en el albarán y en la factura sin albarán;
   - devolución en el abono y en el albarán de devolución;
   - asignación de lotes FIFO o FEFO o a mano, con su impresión en el documento;
   - política de stock insuficiente.
4. **Contabilidad y precios**:
   - valoración y asiento de variación de existencias;
   - enlace de la entrada con la factura recibida y corrección de coste;
   - precios del punto 11.
5. **Después**: ETL de TORRO, con modo sombra de existencias por artículo y lote frente a `artistock` y los lotes, y lo del
   punto 12 cuando haga falta.

### Lo que enseñan TORRO (`mconta0037`) y sus incidencias

Datos de la empresa 1 (export del 13/11/2026, 2020–2026):

- 69.091 facturas contabilizadas, casi todas desde albarán (68.813; 1,4 albaranes por factura, hasta 63) y 4.954 rectificativas.
  1,2 millones de líneas; 1,05 millones de líneas de lote servidas (11.938 en rectificativas).
- 1.241 artículos, 1.180 con lote; unidades KG 533, U 477, C 148. 64 sin unidades por caja (se venden a peso): es legítimo.
- 5.826 entradas de género (unas 900 al año, 140 proveedores), 4 líneas de media; 5.723 con su factura de proveedor. Caducidad
  en el 71 % de las líneas y lote del proveedor en el 77 %; ubicación, tara y palés sin uso. Sin gastos de compra.
- 16.428 regularizaciones: 13.711 nacen de rectificativas («Rectificación de la factura…», entradas negativas o positivas),
  unas 2.400 de inventario (texto libre, sin tipo) y solo 210 mermas y 116 devoluciones de unidades.
- Pactados: 477 precios de 85 clientes, con vigencia (normalmente anual) y el 29 % por dirección de envío; solo uno referencia
  una tarifa. 7 tarifas de la empresa.
- Sin centros (todo `9999`): un almacén.

Incidencias resueltas en GeneXus que este diseño evita:

- Dos verdades del stock: la ficha (`ArtStockCan`) dejó de bajar con las ventas en 2019 y no coincide con los lotes. → 2.1: una
  sola fuente, los movimientos.
- El abono que agrupa líneas de otras facturas no encontraba el lote y la devolución se perdía sin aviso (corregido el
  28/10/2026 buscando en el albarán de origen). → la línea rectificativa referencia la línea y sus lotes; sin lote, error.
- Signo de las cajas mal en abonos y colisiones del contador de líneas de regularización que se perdían en silencio. → cajas
  derivadas de la cantidad y nada se descarta sin error.
- En el almacén consultan el stock antes y después de cada abono, y la trazabilidad por lote es la que piden las inspecciones y
  las alertas alimentarias: consulta de un lote hacia adelante (a qué clientes fue) y hacia atrás (de qué proveedor y factura).
- La regularización por inventario es la habitual: recuento por lote con motivo tipificado (inventario, merma, caducado, rotura),
  no solo texto.

## Consecuencias

- Una sola fuente de las existencias: lo que se ve sale de los movimientos y se puede recalcular.
- La factura emitida sigue inmutable. Con stock, su salida o su devolución es un movimiento enlazado a la línea, no un cambio en
  la factura.
- Un abono puede necesitar el lote de una línea de otra factura: la línea de la rectificativa referencia la línea original.
- TORRO se carga con su configuración: FIFO, aviso de stock, venta por cajas, albaranes sin presupuesto, lote impreso y
  agrupación por dirección de envío.
- El export `etl/legacy-export/exportar-almacen.cmd` (en la plataforma) saca de un schema GeneXus lo necesario para el ETL y
  el modo sombra: artículos, lotes, regularizaciones, stock, documentos de venta con lotes, tarifas y parámetros.

## Origen

Conversación del 13/11/2026 («vamos con la gestión de stocks… albaranes, abonos, tarifarios, tarifa por cliente y durante
determinado periodo»). Análisis sobre la KB de GeneXus (`PStockActualiza`, `TLote`, `TLotArtReg`, `FacAlbaran`,
`IngExistencia`, `AlbaranTer`, `StkRegularizaStkLot`), la estructura de `mconta0037` y sus parámetros (`pdefecto`), su export
(`exportar-almacen.cmd`) y las conversaciones de las incidencias de TORRO (albaranes, facturación de albaranes y regularización
de existencias). Aceptado con 7 bis el 13/11/2026.
