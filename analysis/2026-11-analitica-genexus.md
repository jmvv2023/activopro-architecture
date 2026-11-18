# Contabilidad analítica en el programa anterior (18/11/2026)

Lectura del código de la KB (procedimientos, pantallas y menú) y de la estructura de `mconta0037`, para ADR-0050. Es una foto del
funcionamiento, no un diseño.

## 1. Activación y estructura

**Marcas por empresa** (`empresas`)
- `EmpCenSN`: lleva centros. Activa el menú **Analítica** y todo lo de abajo.
- `EmpSucSN`: lleva divisiones (`DevEmpDivSN` lee esta columna; el nombre engaña).

**Centros:** `empcen` (código, nombre, dirección y contacto, moneda, estado).

**Divisiones**
- `empdiv` es un **catálogo de la empresa**, no de cada centro.
- `empcenlevel1` dice qué divisiones tiene cada centro.
- La misma división (p. ej. «Taller») puede estar en varios centros.

**La división es una segunda dimensión que cruza los centros.** `GenBalCentros` informa:
- por centro con sus divisiones agrupadas;
- o **por división con los centros agrupados** (el total de «Taller» en todas las tiendas).

**Códigos especiales**

| Código | Significado |
|---|---|
| Centro 9999 | «PDTE. DISTRIBUIR» (existe en toda empresa, también sin analítica: en TORRO, uno por empresa) |
| División 999 | pendiente dentro del centro |
| División 0 | «general», para quien no lleva divisiones (`PCentDivDef` crea la 0 y la 999 en todo centro nuevo) |
| Centro 9876 | «(TODOS)» en la cabecera de un documento, que manda a 9999 |

## 2. Qué se imputa

**Cuentas analíticas** (`CtaAnalitca`): las que empiezan por el dígito de los parámetros `CTAGAS` y `CTAVEN` (`pdefecto`). En la
práctica, 6 y 7.

**Hay excepciones:**
- `Contafacvencen` (emitidas) imputa las líneas de 7 al haber y de 6 al debe sin mirar los parámetros.
- La amortización (`AmortConta`) imputa la dotación por el centro y la división de la ficha (`activofijo.CentCod` / `DvsCod`).

**Se guarda en `tasiimpcen`**
- Clave: empresa, ejercicio, asiento, **línea**, centro y división.
- Datos: importe, lado D/H, cuenta, fecha y nombres copiados.
- Marcas: `AsiImpTemp` (temporal del reparto) y `AsiImpRedist`.
- `PAltaImpCen` da de alta o cambia y mantiene los saldos en el mismo paso. Un importe a 0 borra la fila.

## 3. Cuándo se imputa

**Programas de entrada**
- Facturas recibidas (`IngFRI`, `IngFRIM`…), varios (`IngVarios`), nóminas (`IngNominas1`, `IngNomFet`), banco, caja, caja diaria y
  farmacia (`IngBanco`, `IngCaja`, `IngCajaDiaria`, `IngCajaFar`), amortización, remesas (`Remesardcon`) y el asiento genérico.
- Cómo funcionan:
  - Llevan un **combo de centro en la cabecera**, por defecto **(TODOS)**, que acaba en 9999.
  - Al grabar, si alguna cuenta es analítica, se abre la ventana **Analítica** (`AsiImpCen`):
    - propone toda la línea al centro de la cabecera (división 999 si hay divisiones, 0 si no);
    - deja partirla entre centros y divisiones por importe;
    - lo que no se reparte queda en el centro de la cabecera o en 9999.
  - Si el centro de la cabecera es concreto y no hay divisiones, imputa sin preguntar.
- En facturas recibidas solo se imputa la **contrapartida** (una línea: base + IRPF + no deducible), no cada línea de gasto.

**Facturas emitidas:** llevan `CentCod` / `DvsCod` en la factura (`facturas`). `ContaFacVen` → `Contafacvencen` imputa todas las líneas
de 6/7 del asiento a ese centro y división. Con divisiones y división 999, queda pendiente.

**Asientos generados sin pantalla** (`PAltaMov2` con la marca `ANALITICAF`): el centro y la división del apunte. Si no tiene, 9999/999.

**Sin imputación:**
- las importaciones de diarios (`ImportDiario*`), que no la crean;
- los asientos que no pasan por estos caminos.

**Hay más tablas con centro:** `prestamos.CentCod`, `lotearticulo.CentCod`, `activofijo.CentCod`, y `movctas.SucCod` (el centro como
sucursal del apunte).

**Parámetros de centro como sucursal** (`tempcenparcentros`): cuentas de caja, efectivo, crédito, cambio de moneda, diferencias,
contrapartida de venta y acreedor genérico **por centro**. La caja diaria las usa para generar el asiento de cada local.

## 4. Pendiente de distribuir

Menú **Importes Pdtes. Distribuir en Centros** (`NoAsiImpCen`):
- lista lo que está en 9999 (por defecto, el último mes);
- desde la lista se abre la misma ventana **Analítica** para repartir la línea.

## 5. Redistribución de gastos/ingresos

**Plantilla** (`tplaredcen`, menú Redistribución → Plantilla)
- Cada fila: **una subcuenta concreta** (título + código) de un centro y división de origen, un % y un centro y división de destino.
- La fecha de la plantilla se pone a hoy al cambiarla.

**Redistribución por mes** (`RedCentro` → `prediscentro`, `INS`)
- Para cada fila de la plantilla, recorre las imputaciones del origen en el periodo y crea las de destino por el %, ajustando el
  redondeo en la última.
- Marca las de destino `AsiImpRedist = 'S'` y **borra las de origen**.
- Después regenera los saldos del periodo (`GenSdoCentros`).

**Deshacer** (`DEL`): devuelve al origen **todo lo marcado como redistribuido de esa subcuenta** en el periodo, venga de la plantilla
que venga.

**Problemas** (algunos anotados en el propio código: «¿qué pasa si hay una redist. hecha…?»):
- Si se cambia o borra la plantilla después de redistribuir, deshacer no sabe qué se hizo.
- El «antes» se pierde.
- Repetir el reparto no hace nada, porque el origen ya está a 0.

## 6. Saldos e informes

**Saldos:** `sdocentros` por centro, división, título, cuenta y mes.
- Guarda también las filas de los títulos de 4 y de 3 cifras.
- Hay procesos para regenerarlos (`GenSdoCentros`, `ArreglaSldoAnalitica`) y para arreglar duplicados (`ArreglaTasiImpCen`).

**Informes** (menú Analítica)
- **Movimientos Centros/Divisiones** (`MovimCen`): los movimientos de una cuenta en un centro, con el asiento.
- **Informes Analítica** (`GenBalCentros`, `Bal_por_centros`, `Bal_por2_Centros`):
  - los informes personalizados (`definfcon*`) calculados sobre `sdocentros`;
  - por centro, por división o agrupados;
  - con % y dos periodos.
- **Imprimir errores de cuadre de centros** (`Imprasiimpcen`): líneas cuya imputación no suma lo del apunte.

## 7. Qué cambia para el diseño (ADR-0050)

1. **La división cruza los centros.** El árbol que se decidió (las divisiones como hijos de su centro) no da el total de una división
   en todos los centros, que hoy sí sale. Hay que elegir entre:
   - dos dimensiones, centro y división (con las combinaciones permitidas);
   - el árbol más una agrupación transversal.
   Antes, conviene medir cuántas empresas usan divisiones y si comparten la misma división entre centros (consulta abajo).
2. En recibidas, hoy se imputa la contrapartida, no cada línea. En la plataforma la propuesta por línea de factura es mejor y no rompe
   nada.
3. Hoy, lo importado de otros programas no se imputa. La plataforma lo enseñará como «sin imputar», como cualquier otra cosa.
4. El reparto actual borra el origen y no guarda qué hizo. Los movimientos de reparto aparte (decidido) resuelven deshacer, repetir y
   el «antes».
5. El centro como sucursal (cuentas de caja por centro) ya está cubierto por las cuentas de tesorería y el cierre de caja. Del centro
   solo queda el centro por defecto de esa caja.

## Consulta para medir el uso (solo lectura, por schema)

```sql
-- Lanzar en cada schema mconta####; solo lee.
select database() as esquema, e.EmpCod, e.EmpCenSN, e.EmpSucSN,
  (select count(*) from empcen c where c.EmpCod = e.EmpCod and c.CentCod not in (9999, 9876)) as centros,
  (select count(*) from empdiv d where d.EmpCod = e.EmpCod and d.DvsCod not in (0, 999)) as divisiones,
  (select count(*) from empcenlevel1 l where l.EmpCod = e.EmpCod and l.DvsCod not in (0, 999)) as centro_division,
  (select count(*) from (select l.DvsCod from empcenlevel1 l where l.EmpCod = e.EmpCod and l.DvsCod not in (0, 999)
                          group by l.DvsCod having count(*) > 1) x) as divisiones_compartidas,
  (select count(*) from tasiimpcen t where t.EmpCod = e.EmpCod) as imputaciones,
  (select max(t.AsiImpFecha) from tasiimpcen t where t.EmpCod = e.EmpCod) as ultima_imputacion,
  (select count(*) from tasiimpcen t where t.EmpCod = e.EmpCod and t.AsiImpDiv not in (0, 999)) as con_division,
  (select coalesce(sum(t.AsiImpImp), 0) from tasiimpcen t where t.EmpCod = e.EmpCod and t.AsiImpCen = 9999) as pendiente_9999,
  (select count(*) from tasiimpcen t where t.EmpCod = e.EmpCod and t.AsiImpRedist = 'S') as redistribuidas,
  (select count(*) from tplaredcen p where p.EmpCod = e.EmpCod) as filas_plantilla,
  (select count(*) from tasiimpcen t where t.EmpCod = e.EmpCod and left(t.AsiImpTit, 1) not in ('6', '7')) as fuera_6_7,
  (select count(*) from activofijo a where a.EmpCod = e.EmpCod and a.CentCod not in (9999)) as activos_con_centro
from empresas e
where e.EmpCenSN = 'S';
```

## Resultado (18/11/2026)

Dos empresas tienen `EmpCenSN = 'S'`; solo **mconta0050, empresa 1**, la usa. Las dos consultas, por partes por el límite de MySQL Workbench:

| Dato | Valor |
|---|---|
| Centros | 27 |
| Divisiones | 0 (sin `EmpSucSN`) |
| Imputaciones | 45.941 (02/01/2008 – 09/11/2026), ninguna fuera de 6 y 7 |
| Redistribuidas | 378 |
| Filas de plantilla de reparto | 42 |
| Pendiente en 9999 | −1.707,05 |
| Fichas de inmovilizado con centro | 26 |

**mconta0109, empresa 1**: `EmpSucSN = 'S'`, pero sin centros ni divisiones (solo los códigos especiales). Tiene 8.115 imputaciones
(02/01/2017 – 09/11/2026), todas en 9999, por 4.736.541,07: activada y nunca usada.
