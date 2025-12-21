-- ============================================================================
-- 03_error_analysis.sql
-- Propósito: Analizar distribución de códigos HTTP y errores del servidor
-- Valor de negocio: Identificar problemas de confiabilidad y priorizar correcciones
-- ============================================================================

-- Distribución de códigos de estado en todas las requests
-- Insight clave: proporción de exitosos (2xx) vs errores cliente (4xx) vs servidor (5xx)
SELECT 
    status_code,
    COUNT(*) AS status_count
FROM logs
GROUP BY status_code
ORDER BY status_count DESC;

-- Total de errores del lado del servidor (5xx)
-- Métrica crítica: los errores 5xx indican problemas en nuestra infraestructura/código
SELECT 
    COUNT(*) AS status_5xx_count
FROM logs
WHERE status_code >= 500;