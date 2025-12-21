-- ============================================================================
-- 04_performance_analysis.sql
-- Propósito: Correlacionar errores con tiempos de respuesta por endpoint
-- Valor de negocio: Identificar endpoints problemáticos para optimización
-- ============================================================================

-- Tabla que indica salud por endpoint: tasa de error + tiempo de respuesta
-- Usa 3 CTEs para construir una vista completa por endpoint:
--   1. error_5xx: cantidad de errores del servidor por endpoint
--   2. total_requests: tráfico total por endpoint (denominador para tasa de error)
--   3. avg_time_response_ms: métrica de latencia por endpoint
-- Resultado: endpoints ordenados por error_percentage (mayor = más crítico)
WITH error_5xx AS (
    SELECT 
        endpoint,
        COUNT(*) as error_count
    FROM logs
    WHERE status_code >= 500
    GROUP BY endpoint
),
total_requests AS (
    SELECT 
        endpoint,
        COUNT(*) as total_count
    FROM logs
    GROUP BY endpoint
),
avg_time_response_ms AS (
    SELECT
        endpoint,
        ROUND(AVG(response_time_ms), 2) as avg_response_time_ms
    FROM logs
    GROUP BY endpoint
)
SELECT 
    error_5xx.endpoint,
    ROUND(error_5xx.error_count * 100.0 / total_requests.total_count, 2) AS error_percentage,
    error_5xx.error_count,
    total_requests.total_count,
    avg_time_response_ms.avg_response_time_ms
FROM error_5xx
JOIN total_requests USING (endpoint)
JOIN avg_time_response_ms USING (endpoint)
ORDER BY error_percentage DESC;


-- Análisis de concentración de errores: ¿qué endpoints contribuyen más al total?
-- Diferente al anterior: aquí vemos la PARTICIPACIÓN de cada endpoint en el total de 5xx
-- Caso de uso: si /api/payments tiene 40% de todos los 5xx, es prioridad de corrección
-- Se usa CROSS JOIN porque total_5xx_count es un escalar (una sola fila)
WITH total_5xx_errors AS (
    SELECT 
        COUNT(*) AS total_5xx_count
    FROM logs
    WHERE status_code >= 500
),
error_5xx AS (
    SELECT 
        endpoint,
        COUNT(*) AS error_count
    FROM logs
    WHERE status_code >= 500
    GROUP BY endpoint
)
SELECT 
    error_5xx.endpoint,
    error_5xx.error_count,
    total_5xx_errors.total_5xx_count,
    ROUND(error_5xx.error_count * 100.0 / total_5xx_errors.total_5xx_count, 2) AS error_share_percentage
FROM error_5xx
CROSS JOIN total_5xx_errors
ORDER BY error_share_percentage DESC;