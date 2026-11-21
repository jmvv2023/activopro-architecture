-- Tamaño de los adjuntos por schema en producción (MySQL de GeneXus), para fijar el espacio incluido (ADR-0057, ampliación del
-- 21/11/2026). Solo lectura: lo lanza José María en producción y devuelve el resultado (sin contenido de los ficheros).
-- Recorre todos los schemas mconta#### que tienen las tres tablas.
select t.table_schema as esquema,
       sum(case when t.table_name = 'adjmovctas' then t.data_length + t.index_length else 0 end) / 1048576 as asientos_mb_aprox,
       sum(case when t.table_name = 'facturasadjuntos' then t.data_length + t.index_length else 0 end) / 1048576 as facturas_mb_aprox,
       sum(case when t.table_name = 'activofijoactdoc' then t.data_length + t.index_length else 0 end) / 1048576 as inmovilizado_mb_aprox
  from information_schema.tables t
 where t.table_schema regexp '^mconta[0-9]{4}$'
   and t.table_name in ('adjmovctas', 'facturasadjuntos', 'activofijoactdoc')
 group by t.table_schema
 order by asientos_mb_aprox + facturas_mb_aprox + inmovilizado_mb_aprox desc;
-- data_length es una aproximación (páginas reservadas, con los longblob fuera de página incluidos en InnoDB). Si hace falta el dato
-- exacto de un schema concreto: select count(*), sum(length(<columna blob>)) / 1048576 from <schema>.adjmovctas;
