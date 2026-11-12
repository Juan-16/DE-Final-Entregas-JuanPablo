-- Porcentaje de entregas exitosas por fecha y ciudad:
-- 100 * entregas exitosas / total de intentos (el denominador incluye todos los estados).
-- CAST a DOUBLE evita la división entera; DECIMAL(5,2) conserva siempre dos decimales.
SELECT
    fecha,
    ciudad,
    CAST(
        ROUND(100.0E0 * CAST(SUM(CASE WHEN estado = 'entregado' THEN 1 ELSE 0 END) AS DOUBLE) / COUNT(*), 2)
        AS DECIMAL(5, 2)
    ) AS porcentaje_exito
FROM entregas_db.entregas
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
