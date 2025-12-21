-- ============================================================================
-- 05_temporal_analysis.sql
-- Propósito: Analizar patrones de tráfico en el tiempo (tendencias diarias, horas pico)
-- Valor de negocio: Planificación de capacidad, decisiones de escalado, detección de anomalías
-- ============================================================================

-- Comparación día a día usando la función ventana LAG
-- LAG() accede al valor de la fila anterior para calcular el cambio diario
-- Útil para: detectar picos de tráfico, tendencias de crecimiento o caídas repentinas
WITH daily_stats AS (
    SELECT 
        DATE(timestamp) as date,
        COUNT(*) as requests,
        ROUND(AVG(response_time_ms), 2) as avg_response_time
    FROM logs
    GROUP BY DATE(timestamp)
)
SELECT 
    date,
    requests,
    LAG(requests) OVER (ORDER BY date) as previous_day_requests,
    requests - LAG(requests) OVER (ORDER BY date) as difference,
    ROUND(
        (requests - LAG(requests) OVER (ORDER BY date)) * 100.0 / 
        LAG(requests) OVER (ORDER BY date), 
        2
    ) as percent_change
FROM daily_stats
ORDER BY date;


-- Tasa de crecimiento diario promedio
-- Métrica única que resume la dirección general de la tendencia de tráfico
-- Positivo = tráfico creciente, Negativo = tráfico decreciente
WITH daily_stats AS (
    SELECT 
        DATE(timestamp) as date,
        COUNT(*) as requests,
        ROUND(AVG(response_time_ms), 2) as avg_response_time
    FROM logs
    GROUP BY DATE(timestamp)
), 
daily_percent_change AS (
    SELECT 
        date,
        requests,
        requests - LAG(requests) OVER (ORDER BY date) as difference,
        ROUND(
            (requests - LAG(requests) OVER (ORDER BY date)) * 100.0 / 
            LAG(requests) OVER (ORDER BY date), 
            2
        ) as percent_change
    FROM daily_stats
)
SELECT AVG(percent_change) AS avg_daily_percent_change FROM daily_percent_change;


-- Identificación de horas pico: horas con tráfico superior al promedio
-- HAVING filtra grupos donde el conteo excede el promedio por hora
-- Caso de uso: programar mantenimientos fuera de horas pico, escalar durante picos
WITH requests_per_hour AS (
    SELECT 
        EXTRACT(HOUR FROM timestamp) AS hour,
        COUNT(*) AS request_count
    FROM logs
    GROUP BY EXTRACT(HOUR FROM timestamp)
    ORDER BY request_count DESC   
)
SELECT 
    EXTRACT(HOUR FROM timestamp) AS peak_hour,
    COUNT(*) AS request_count
FROM logs
GROUP BY EXTRACT(HOUR FROM timestamp)
HAVING COUNT(*) > (SELECT AVG(request_count) FROM requests_per_hour)
ORDER BY request_count DESC;