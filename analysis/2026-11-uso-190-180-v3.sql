-- Tercera medida de las retenciones (ADR-0051, fase 3). La segunda (v2, 25/11/2026) dejó claro que la ficha de tipirpf
-- (`TipIrpfClave`, `TipIrpfModT`, `TipIrpfModA`) está vacía en casi todos los schemas: la clave del 190 no se puede sacar de ella.
-- En los exports locales los códigos (`MovIrpfCod`) son los mismos en todas las empresas (PRO, PRN, ARI, ARU, ARM, DIV, MOD, AGR…),
-- probablemente heredados del plan base, y `MovIrpfClas` es P = practicada, S = soportada (IrpfDeclaracion filtra por ella);
-- vacía, sin código ni base, solo cuota, en la línea 1 del asiento: el IRPF de las nóminas.
-- Esta consulta da, para 2025 y todos los schemas, cada código con su descripción y porcentaje, la clase y el título de la cuenta
-- de la línea: con ella se fija en el ETL la traducción por código (sin adivinar). Solo lectura, en producción.
--
-- Se lanza todo el bloque de una vez: la consulta se genera en una variable y se ejecuta con PREPARE, sin copiarla (copiada desde
-- la rejilla salía cortada). PREPARE / EXECUTE de un SELECT no escribe nada.
set session group_concat_max_len = 16777216;
set @q = (select concat('select codigo, descripcion, porcentaje, clase, titulo, count(distinct esquema) esquemas, sum(retenciones) retenciones, ',
  'round(sum(cuota), 2) cuota from (', group_concat(concat(
  'select ''', t.table_schema, ''' esquema, upper(trim(m.MovIrpfCod)) codigo, upper(trim(coalesce(ti.TipIRPFDes, ''''))) descripcion, ',
  'm.MovIRPFPor porcentaje, m.MovIrpfClas clase, ',
  'case when l.MovHCtaTit like ''47%'' then l.MovHCtaTit when l.MovDCtaTit like ''47%'' then l.MovDCtaTit else concat(''?'', coalesce(l.MovHCtaTit, ''''), ''/'', coalesce(l.MovDCtaTit, '''')) end titulo, ',
  'count(*) retenciones, sum(m.MovIRPFCuota) cuota ',
  'from `', t.table_schema, '`.movctaslevel2 m ',
  'left join `', t.table_schema, '`.tipirpf ti on ti.EmpCod = m.MovEmpCod and ti.TipIrpfCod = m.MovIrpfCod ',
  'left join `', t.table_schema, '`.movctas l on l.MovEmpCod = m.MovEmpCod and l.EjerCod = m.EjerCod and l.MovId = m.MovId and l.MovLin = m.MovLin ',
  'where m.EjerCod = 2025 group by 1, 2, 3, 4, 5, 6')
  separator ' union all '), ') x group by 1, 2, 3, 4, 5 order by 1, 4, 3')
  from information_schema.tables t
 where t.table_schema regexp '^mconta[0-9]{4}$' and t.table_schema <> 'mconta9999' and t.table_name = 'movctaslevel2'
   and exists (select 1 from information_schema.tables x where x.table_schema = t.table_schema and x.table_name = 'tipirpf'));
select length(@q) longitud;  -- si sale null, el group_concat no cabe: avisar
prepare consulta from @q;
execute consulta;
deallocate prepare consulta;
-- Son unas decenas de filas: pasar el resultado entero.
--
-- Qué se mira: si un mismo código tiene la misma descripción y porcentaje en todos los schemas (entonces se traduce por código:
-- PRO/PRN profesionales G01, ARI/ARU arrendamiento, DIV capital mobiliario…); los códigos raros, que quedan sin clave y con aviso;
-- y que las vacías caen en la 4751 (nóminas: «Trabajo», informativa) y las S en la 473.
