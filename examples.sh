# Ejemplos de uso con curl - API de Pedidos
# Sistema completo con autenticación, rate limiting y replicación

# =============================================================================
# 7. MANEJO DE ERRORES
# =============================================================================

# 7.1. Datos inválidos en creación de pedido
curl -X POST ${API_URL}/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "customer_name": "",
    "items": [],
    "total_amount": -10
  }'
# Respuesta esperada: Error de validación

# 7.2. Token inválido
curl -X GET ${API_URL}/orders \
  -H "Authorization: Bearer invalid-token"
# Respuesta esperada: Error de autenticación

# 7.3. Login con credenciales incorrectas
curl -X POST ${API_URL}/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "invalid_user",
    "password": "wrong_password"
  }'
# Respuesta esperada: {"error": "Credenciales inválidas"}

# =============================================================================
# 8. CERRAR SESIÓN
# =============================================================================

# 8.1. Logout (invalida el token)
curl -X POST ${API_URL}/logout \
  -H "Authorization: Bearer ${TOKEN}" | jq .

# 8.2. Intentar usar token después del logout
curl -X GET ${API_URL}/orders \
  -H "Authorization: Bearer ${TOKEN}"
# Respuesta esperada: Error de token revocado

# =============================================================================
# 9. PRUEBAS DE REINTENTOS (CONFIGURACIÓN AUTOMÁTICA)
# =============================================================================

# Los reintentos están configurados automáticamente en:
# - NGINX: proxy_next_upstream para fallos de instancias
# - Flask app: @retry_on_failure decorator en endpoints críticos
# - Docker Compose: restart policies para recuperación automática

# Para simular fallos, puedes parar una instancia:
# docker stop orders-api-1
# Luego hacer requests - NGINX automáticamente reroutea a instancias sanas

# =============================================================================
# 10. MONITOREO CONTINUO
# =============================================================================

# Script para monitoreo continuo de la salud del sistema
echo "Iniciando monitoreo continuo (presiona Ctrl+C para parar):"
while true; do
  HEALTH=$(curl -s ${API_URL}/health | jq -r .status)
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$TIMESTAMP] Sistema: $HEALTH"
  sleep 5
done

# =============================================================================
# NOTAS IMPORTANTES
# =============================================================================

# 1. Rate Limiting:
#    - 200 requests/día, 50/hora por defecto
#    - 5 registros/minuto
#    - 10 logins/minuto
#    - Basado en usuario autenticado o IP

# 2. Autenticación:
#    - Tokens JWT válidos por 1 hora
#    - Logout invalida el token inmediatamente

# 3. Alta Disponibilidad:
#    - 3 instancias de la API
#    - Load balancing con NGINX
#    - Health checks automáticos
#    - Restart automático de contenedores

# 4. Reintentos:
#    - NGINX: 3 reintentos con timeout de 10s
#    - App: @retry_on_failure con backoff exponencial
#    - Docker: restart unless-stopped

# 5. Monitoreo:
#    - http://localhost:8080 - Información del sistema
#    - http://localhost:8080/api/health - Health check
#    - http://localhost:8081 - Dashboard de monitoreo