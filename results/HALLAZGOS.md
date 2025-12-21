# Plan de Acción: Optimización del Servidor Web

**Período analizado:** 2024-01-03 al 2025-12-16  
**Total de requests:** 1,000 | **Usuarios únicos:** 670 | **Endpoints:** 11

---

## 1. Análisis de Errores (Crítico)

### Resumen
El servidor presenta una **tasa de errores 5xx del 23.2%** (232 de 1,000 requests), lo cual está significativamente por encima del umbral aceptable (<1%). Los errores se distribuyen entre 503 (83), 502 (75) y 500 (74), indicando problemas tanto de disponibilidad como de lógica de aplicación.

**Concentración crítica:** Los endpoints `/api/cart` (12.5%), `/api/products` (12.07%) y `/api/users` (11.21%) concentran el **35.78% de todos los errores 5xx**. Estos tres endpoints son críticos para el negocio ya que representan el core de la experiencia de compra: gestión del carrito, catálogo de productos y datos de usuario. Fallos en estos servicios impactan directamente en conversión y retención.

### Acciones recomendadas
- [ ] **Priorizar `/api/cart` como crítico:** Con 29 errores (12.5% del total), es el endpoint más problemático y afecta directamente el checkout. Revisar queries a base de datos y manejo de sesiones.
- [ ] **Auditar `/api/products` y `/api/users`:** Juntos suman 54 errores. Evaluar si comparten dependencias (DB, cache) que puedan estar saturadas.
- [ ] **Implementar circuit breakers:** Los 75 errores 502 (Bad Gateway) indican fallos en comunicación con servicios upstream. Agregar fallbacks para evitar cascadas de errores.

---

## 2. Análisis de Tráfico y Patrones Temporales

### Resumen
El tráfico está relativamente balanceado entre endpoints, con `/api/products` (106), `/api/auth/login` (105) y `/api/search` (104) liderando. Las **horas pico** se concentran a las **17:00** (58 requests) con actividad secundaria entre 1:00-5:00 AM. El crecimiento diario promedio es de **+24%**, lo que indica una tendencia alcista que requiere planificación de capacidad.

### Acciones recomendadas
- [ ] **Escalar recursos antes de las 17:00:** Configurar auto-scaling predictivo para anticipar el pico de tráfico vespertino y evitar degradación de servicio.
- [ ] **Investigar tráfico nocturno (1-5 AM):** 192 requests en horario no laboral podría indicar bots, scrapers o jobs batch. Validar si es tráfico legítimo o implementar rate limiting.
- [ ] **Proyectar capacidad a 30 días:** Con +24% de crecimiento diario, modelar necesidades de infraestructura para evitar saturación en el corto plazo.

---

## 3. Análisis de Performance por Endpoint

### Resumen
**Situación alarmante:** 9 de 11 endpoints tienen una tasa de error superior al 20%. Los peores casos son:
- `/api/cart`: **29.59%** de error rate con latencia promedio de **4,762ms**
- `/api/users`: **28.26%** de error rate con latencia promedio de **4,161ms**  
- `/api/products`: **26.42%** de error rate con latencia promedio de **4,765ms**

Incluso endpoints de autenticación como `/api/auth/login` (20%) y `/api/auth/logout` (23.47%) presentan tasas inaceptables. Los tiempos de respuesta promedio superan los **3 segundos** en todos los endpoints, muy por encima del umbral recomendado de 200ms.

### Acciones recomendadas
- [ ] **Optimizar `/api/cart` urgentemente:** Con el peor error rate (29.59%) y latencia de ~5s, es el cuello de botella principal. Investigar queries N+1, conexiones a DB y manejo de inventario.
- [ ] **Implementar caché en `/api/products`:** Alto tráfico (106 requests) + alta latencia (4,765ms) = candidato ideal para Redis/Memcached en lecturas.
- [ ] **Establecer SLO de 500ms máximo:** Ningún endpoint cumple un tiempo de respuesta aceptable. Definir alertas cuando p95 > 500ms.

---

## 4. Análisis de Errores por Método HTTP

### Resumen
Al segmentar los errores por método HTTP, se evidencia que **GET es el método más problemático**, con los rankings más altos de errores por endpoint:
- `GET /api/users`: **15 errores** (rank #1)
- `GET /api/cart`: **13 errores** (rank #2)
- `GET /api/search`: **13 errores** (rank #2)
- `GET /api/auth/logout`: **12 errores** (rank #3)

Todos los métodos GET en el top tienen **más de 10 errores**, lo que sugiere problemas sistemáticos en operaciones de lectura: queries ineficientes, falta de índices, o timeouts en consultas complejas.

Los métodos de escritura (PUT, POST, PATCH, DELETE) muestran menores cantidades pero con latencias extremas (ej: `PUT /api/products` con **22,521ms** promedio).

### Acciones recomendadas
- [ ] **Auditar queries de lectura en endpoints GET:** La concentración de errores sugiere problemas en la capa de datos. Revisar índices, optimizar JOINs y evaluar read replicas.
- [ ] **Investigar `GET /api/users` como prioridad:** Con 15 errores es el peor caso. Verificar si hay consultas a tablas sin índices o N+1 queries al cargar relaciones.
- [ ] **Implementar timeout agresivo en GETs:** Configurar timeout de 2s para lecturas y retornar respuesta parcial o cached en caso de fallo, evitando que el usuario espere indefinidamente.

---

## Métricas de Seguimiento (KPIs)

| Métrica | Valor Actual | Objetivo |
|---------|--------------|----------|
| Tasa de errores 5xx | 23.2% | <1% |
| Requests en hora pico | 58/hora | Sin degradación |
| Endpoints con >20% error rate | **9 de 11** | 0 |
| Latencia promedio (p50) | >3,000ms | <500ms |
| Errores en método GET (top endpoint) | 15 | <5 |

---