-- Segunda medida del uso de las retenciones (ADR-0051, fase 3). La primera (2026-11-uso-190-180.sql, 24/11/2026) agrupó por el
-- modelo anual de la ficha (`TipIrpfModA`), que casi ninguna empresa tiene relleno (113 schemas con retenciones en 2025; solo 4 con
-- modelo anual). Esta agrupa por lo que sí decide la clave del 190: la letra de `TipIrpfClave` (A–E y L trabajo; F, G, H, I, K… el
-- resto) y el modelo trimestral (`TipIrpfModT`: 111 o 115), con la clase del movimiento. Solo lectura, en producción, dos pasos.
--
-- Paso 1: genera la consulta.
set session group_concat_max_len = 1000000;
select group_concat(concat(
  'select ''', t.table_schema, ''' esquema, m.EjerCod ejercicio, ',
  'coalesce(nullif(upper(left(trim(ti.TipIrpfClave), 1)), ''''), ''?'') letra, coalesce(ti.TipIrpfModT, 0) modelo_trimestral, ',
  'm.MovIrpfClas clase, count(*) retenciones, count(distinct m.MovEmpCod) empresas, round(sum(m.MovIRPFCuota), 2) cuota ',
  'from `', t.table_schema, '`.movctaslevel2 m left join `', t.table_schema, '`.tipirpf ti on ti.EmpCod = m.MovEmpCod and ti.TipIrpfCod = m.MovIrpfCod ',
  'where m.EjerCod = 2025 group by 1, 2, 3, 4, 5')
  separator ' union all ') as consulta
  from information_schema.tables t
 where t.table_schema regexp '^mconta[0-9]{4}$' and t.table_schema <> 'mconta9999' and t.table_name = 'movctaslevel2'
   and exists (select 1 from information_schema.tables x where x.table_schema = t.table_schema and x.table_name = 'tipirpf');
-- Paso 2: copiar el texto de `consulta`, añadirle «order by esquema, letra» y lanzarlo.
--
-- Qué se mira: por letra, cuántos schemas tienen profesionales (G), premios (K), otras claves sin trabajo, y cuántos además nóminas
-- (A–E): los primeros tendrían el 190 entero en la plataforma; con nóminas, lo presenta el programa de nóminas. «?» son retenciones
-- sin ficha en tipirpf o con la clave vacía (en la plataforma quedarán sin clave y con aviso).
