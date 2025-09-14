# 🛒 API REST de Pedidos en Línea

Sistema completo de gestión de pedidos con alta disponibilidad, autenticación JWT, rate limiting y replicación con Docker Compose.

## Arquitectura del Sistema

### Tácticas de Arquitectura Implementadas:

1. **Replicación**: 3 instancias de la API con balanceador de carga NGINX
2. **eintentos**: Mecanismos automáticos ante fallos con backoff exponencial  
3. **Autenticación**: Sistema JWT con invalidación de tokens
4. **Rate Limiting**: Protección contra abuso por usuario/IP con Redis
5. **Monitoreo**: Health checks y estadisticas

### Stack Tecnológico:
- **Backend**: Python 3.11 + Flask
- **Autenticación**: JWT (Flask-JWT-Extended)
- **Rate Limiting**: Redis + Flask-Limiter
- **Load Balancer**: NGINX
- **Contenedores**: Docker + Docker Compose
- **Persistencia**: Redis (rate limiting) + In-memory (datos)

## 🚀 Inicio Rápido

### Prerequisitos
- Docker y Docker Compose instalados
- curl y jq (opcional, para testing)

### 1. Iniciar el Sistema
```bash
# Clonar y acceder al directorio
git clone <repository_url>
cd ANDISII_TFU_UT2

# Iniciar todos los servicios
./scripts/start.sh
```

### 2. Verificar el Sistema
```bash
# Health check
curl http://localhost:8080/api/health

# Interfaz web informativa  
open http://localhost:8080
```

### 3. Ejecutar Demostración Completa
```bash
# Demo interactiva con todas las funcionalidades
./scripts/demo.sh
```

## 📡 Endpoints de la API

### Autenticación
| Método | Endpoint | Descripción | Rate Limit |
|--------|----------|-------------|------------|
| POST | `/api/register` | Registrar usuario | 5/min |
| POST | `/api/login` | Iniciar sesión | 10/min |
| POST | `/api/logout` | Cerrar sesión | - |

### Gestión de Pedidos (Requiere autenticación)
| Método | Endpoint | Descripción | Rate Limit |
|--------|----------|-------------|------------|
| POST | `/api/orders` | Crear pedido | 30/min |
| GET | `/api/orders` | Listar pedidos | 100/min |
| GET | `/api/orders/{id}` | Consultar pedido | 200/min |
| PUT | `/api/orders/{id}` | Actualizar pedido | 20/min |

### Sistema
| Método | Endpoint | Descripción | Rate Limit |
|--------|----------|-------------|------------|
| GET | `/api/health` | Health check | - |
| GET | `/api/stats` | Estadísticas | 10/min |

## 🔧 Configuración

### Variables de Entorno
```bash
# Aplicación
FLASK_ENV=production
PORT=5000
JWT_SECRET_KEY=super-secret-key-change-in-production

# Redis
REDIS_URL=redis://redis:6379
```

### Puertos
- **8080**: Load Balancer (NGINX)
- **6379**: Redis (interno)

## Ejemplos de Uso

### Autenticación Completa
```bash
# 1. Registrar usuario
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{"username": "usuario1", "password": "password123"}'

# 2. Obtener token
TOKEN=$(curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "usuario1", "password": "password123"}' \
  | jq -r .access_token)

# 3. Usar token para crear pedido
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "customer_name": "María González",
    "items": [
      {"name": "Laptop", "quantity": 1, "price": 899.99}
    ],
    "total_amount": 899.99,
    "delivery_address": "Av. Libertador 1234, CABA"
  }'
```

### CRUD de Pedidos
```bash
# Crear pedido
curl -X POST http://localhost:8080/api/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "Juan Pérez",
    "items": [{"name": "Producto A", "quantity": 2}],
    "total_amount": 29.99
  }'

# Listar pedidos con paginación
curl -X GET "http://localhost:8080/api/orders?page=1&per_page=10" \
  -H "Authorization: Bearer $TOKEN"

# Consultar pedido específico
curl -X GET http://localhost:8080/api/orders/ORD-000001 \
  -H "Authorization: Bearer $TOKEN"

# Actualizar estado
curl -X PUT http://localhost:8080/api/orders/ORD-000001 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "shipped"}'
```

## Replicación y Alta Disponibilidad

### Arquitectura de Replicación
```
Internet → NGINX Load Balancer → [API-1, API-2, API-3] → Redis
```

### Estrategias de Balanceo
- **Algoritmo**: least_conn (menos conexiones)
- **Health Checks**: Cada 30 segundos
- **Reintentos**: 3 intentos con timeout de 10s
- **Failover**: Automático ante fallos de instancia

### Verificar Distribución de Carga
```bash
# Ver qué instancia maneja cada request
for i in {1..5}; do
  curl -I http://localhost:8080/api/health | grep -i "x-upstream-server"
done
```

## Mecanismos de Reintentos

### 1. Nivel NGINX (Load Balancer)
```nginx
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
proxy_next_upstream_tries 3;
proxy_next_upstream_timeout 10s;
```

### 2. Nivel Aplicación (Python)
```python
@retry_on_failure(max_retries=3, delay=1)
def create_order():
    # Función con reintentos automáticos y backoff exponencial
```

### 3. Nivel Contenedores (Docker)
```yaml
restart: unless-stopped
healthcheck:
  interval: 30s
  timeout: 10s
  retries: 3
```

## Seguridad y Rate Limiting

### Autenticación JWT
- Tokens válidos por 1 hora
- Invalidación inmediata en logout
- Secret key configurable

### Rate Limiting por Usuario/IP
```
Globales: 200/día, 50/hora
Registro: 5/min
Login: 10/min  
Crear pedidos: 30/min
Consultas: 100-200/min
```

### Probar Rate Limiting
```bash
# Hacer requests rápidas hasta activar límite
for i in {1..15}; do
  curl -X GET http://localhost:8080/api/orders \
    -H "Authorization: Bearer $TOKEN"
  sleep 0.1
done
```

## Monitoreo y Observabilidad

### Health Checks
```bash
# Estado del sistema
curl http://localhost:8080/api/health | jq .

# Estado del balanceador
curl http://localhost:8080/nginx-health

# Estadísticas detalladas
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/stats | jq .
```

## 🐳 Configuración de Docker

### Servicios
1. **nginx**: Load Balancer (puerto 8080)
2. **api-1, api-2, api-3**: Instancias de la API
3. **redis**: Cache y rate limiting

### Comandos Útiles
```bash
# Ver estado de contenedores
docker compose ps

# Ver logs en tiempo real
docker compose logs -f

# Escalar instancias
docker compose up -d --scale api=5

# Parar servicios
docker compose down

# Reiniciar con rebuild
docker compose up -d --build
```

## Testing y Demostración

### Demo Automática
```bash
./scripts/demo.sh
```
La demo ejecuta:
- Verificación de health checks
- Registro y autenticación de usuarios  
- CRUD completo de pedidos
- Activación de rate limiting
- Verificación de replicación
- Pruebas de manejo de errores

### Ejemplos Manuales
```bash
# Ver todos los ejemplos disponibles
./examples.sh
```

### Simulación de Fallos
```bash
# Parar una instancia para probar failover
docker stop orders-api-1

# Hacer requests - NGINX reroutea automáticamente
curl http://localhost:8080/api/health

# Reiniciar instancia
docker start orders-api-1
```

## Estructura del Proyecto

```
ANDISII_TFU_UT2/
├── app.py                 # Aplicación Flask principal
├── requirements.txt       # Dependencias Python
├── Dockerfile            # Imagen de la aplicación  
├── docker-compose.yml    # Orquestación de servicios
├── nginx.conf            # Configuración del load balancer
├── examples.sh           # Ejemplos de curl completos
├── scripts/
│   ├── start.sh          # Script de inicio del sistema
│   └── demo.sh           # Demostración interactiva
└── README.md            # Esta documentación
```

## 🔧 Troubleshooting

### Problemas Comunes

#### Puerto ocupado
```bash
# Verificar procesos usando el puerto
lsof -i :8080
sudo netstat -tulpn | grep :8080

# Cambiar puerto en docker-compose.yml si es necesario
```

#### Contenedores no inician
```bash
# Ver logs detallados
docker-compose logs

# Reconstruir imágenes
docker-compose build --no-cache

# Verificar recursos del sistema
docker system df
```

#### Redis no conecta
```bash
# Verificar estado de Redis
docker-compose exec redis redis-cli ping

# Reiniciar servicio Redis
docker-compose restart redis
```

#### Rate limiting no funciona
```bash
# Verificar conexión Redis
curl http://localhost:8080/api/health | jq .services.redis

# Ver logs de la aplicación
docker-compose logs api-1
```

### Logs y Debugging
```bash
# Logs de todos los servicios
docker-compose logs -f

# Logs de un servicio específico
docker-compose logs -f nginx
docker-compose logs -f api-1

# Ejecutar comandos dentro de contenedores
docker-compose exec api-1 bash
docker-compose exec redis redis-cli
```
