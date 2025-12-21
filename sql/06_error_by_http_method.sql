-- ============================================================================
-- 06_error_by_http_method.sql
-- Propósito: Identificar endpoints con más errores segmentados por método HTTP
-- Valor de negocio: Detectar operaciones específicas (GET/POST/PUT/DELETE) que fallan
-- ============================================================================

-- Top 3 endpoints con más errores por método HTTP
-- Estrategia: usar DENSE_RANK con PARTITION BY para rankear dentro de cada grupo de método
-- 
-- ¿Por qué DENSE_RANK en lugar de RANK?
--   DENSE_RANK: empates reciben mismo ranking, siguiente es consecutivo (1,1,2,3)
--   RANK: empates reciben mismo ranking, siguiente salta (1,1,3,4)
--   Usamos DENSE_RANK para asegurar siempre obtener top 3 incluso con empates
--
-- Filtro: error_5xx_count > 3 elimina ruido de errores de baja frecuencia
WITH errors_by_method AS (
    SELECT 
        method,
        endpoint,
        COUNT(*) AS error_5xx_count,
        ROUND(AVG(response_time_ms), 2) AS avg_response_time_ms
    FROM logs
    WHERE status_code >= 500
    GROUP BY method, endpoint
    ORDER BY error_5xx_count DESC
), 
ranked_errors AS (
    SELECT 
        method, 
        endpoint, 
        error_5xx_count,
        avg_response_time_ms,
        DENSE_RANK() OVER (PARTITION BY method ORDER BY error_5xx_count DESC) AS error_rank
    FROM errors_by_method
)
SELECT * FROM ranked_errors 
WHERE error_rank <= 3 AND error_5xx_count > 3;