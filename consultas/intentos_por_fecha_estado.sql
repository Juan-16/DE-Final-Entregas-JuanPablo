-- Cantidad de intentos por fecha y estado (todos los intentos).
-- Sin filtro de fecha: cubre todo el rango proyectado (2026-10-01 a 2026-10-03),
-- por eso la misma consulta sirve para la etapa inicial y la final.
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM entregas_db.entregas
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;
