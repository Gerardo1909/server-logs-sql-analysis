-- ============================================================================
-- 01_initial_exploration.sql
-- Propósito: Exploración inicial de datos y comprensión del esquema
-- ============================================================================

-- Inspección del esquema: nombres de columnas y tipos de datos (similar a .info() en pandas)
DESCRIBE logs;

-- Resumen estadístico de columnas numéricas (similar a .describe() en pandas)
-- Útil para detectar outliers y entender la distribución de los datos
SUMMARIZE logs;

-- Vista general del dataset: métricas clave para entender alcance y rango temporal
-- Nos da el "panorama general" antes de profundizar en análisis específicos
SELECT 
    COUNT(*) as total_requests,
    MIN(timestamp) as first_request,
    MAX(timestamp) as last_request,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT endpoint) as unique_endpoints
FROM logs;