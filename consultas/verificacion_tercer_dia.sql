-- Verificación de la incorporación del 2026-10-03 sin registrar particiones.
-- Athena ejecuta una sentencia por ejecución: cada consulta se ejecuta por separado
-- (scripts/ejecutar_consulta.sh <etapa> <archivo_sql> <resultado> <número de sentencia>).

-- 1) Los seis registros del tercer día -> resultados/final/verificacion_tercer_dia.csv
SELECT
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos,
    fecha
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- 2) Conteos por estado del tercer día -> resultados/final/verificacion_conteo_estados_tercer_dia.csv
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado ASC;

-- 3) Total de registros de la tabla y del tercer día -> resultados/final/verificacion_total_registros.csv
SELECT
    COUNT(*) AS total_registros,
    COUNT_IF(fecha = '2026-10-03') AS registros_tercer_dia,
    COUNT(DISTINCT fecha) AS fechas_con_datos
FROM entregas_db.entregas;
