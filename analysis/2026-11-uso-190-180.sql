-- Uso de las retenciones por modelo anual (190 y 180) en producción (MySQL de GeneXus), para decidir si la fase 3 de ADR-0051
-- lleva fichero oficial o se queda en pantalla y «Generar». Solo lectura: lo lanza José María en producción y devuelve el resultado
-- (solo recuentos e importes por schema, sin datos de perceptores).
--
-- Paso 1: genera la consulta que recorre todos los schemas mconta#### que tienen movctaslevel2 y tipirpf.
set session group_concat_max_len = 1000000;
select group_concat(concat(
  'select ''', t.table_schema, ''' esquema, m.EjerCod ejercicio, coalesce(nullif(trim(leading ''0'' from ti.TipIrpfModA), ''''), ''?'') modelo_anual, ',
  'm.MovIrpfClas clase, count(*) retenciones, count(distinct m.MovEmpCod) empresas, round(sum(m.MovIRPFCuota), 2) cuota ',
  'from `', t.table_schema, '`.movctaslevel2 m left join `', t.table_schema, '`.tipirpf ti on ti.EmpCod = m.MovEmpCod and ti.TipIrpfCod = m.MovIrpfCod ',
  'where m.EjerCod in (2024, 2025) group by 1, 2, 3, 4')
  separator ' union all ') as consulta
  from information_schema.tables t
 where t.table_schema regexp '^mconta[0-9]{4}$' and t.table_name = 'movctaslevel2'
   and exists (select 1 from information_schema.tables x where x.table_schema = t.table_schema and x.table_name = 'tipirpf');
-- Paso 2: copiar el texto de `consulta`, añadirle «order by esquema, ejercicio, modelo_anual» y lanzarlo.
--
-- Qué se mira:
--   · modelo_anual 190 sin trabajo (clases de profesionales, premios…): empresas que el 190 de la plataforma cubriría entero;
--   · modelo_anual 190 con retenciones de trabajo (nóminas): el 190 lo presenta el programa de nóminas (ADR-0051);
--   · modelo_anual 180: empresas con alquileres retenidos (el 180 necesita los inmuebles del arrendador);
--   · '?' : retenciones sin código o con un código que no está en tipirpf.
