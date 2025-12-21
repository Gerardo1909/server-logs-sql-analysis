-- ============================================================================
-- 02_traffic_analysis.sql
-- Propósito: Entender la distribución del tráfico entre endpoints
-- Valor de negocio: Identificar funcionalidades más usadas y posibles cuellos de botella
-- ============================================================================

-- Volumen de tráfico por endpoint
-- Ayuda a identificar: endpoints de alto tráfico que necesitan optimización/escalado
SELECT 
    endpoint,
    COUNT(*) as request_count
FROM logs
GROUP BY endpoint
ORDER BY request_count DESC;