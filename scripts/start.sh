#!/bin/bash
#
# Script de inicio para el sistema de pedidos con Docker Compose
# Implementa replicación, reintentos y alta disponibilidad
#

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Verificar si Docker está instalado
check_docker() {
    log "Verificando instalación de Docker..."
    if ! command -v docker &> /dev/null; then
        error "Docker no está instalado. Por favor instala Docker primero."
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        error "Docker Compose no está instalado. Por favor instala Docker Compose primero."
        exit 1
    fi
    
    log "Docker y Docker Compose están disponibles ✓"
}

# Verificar recursos del sistema
check_system_resources() {
    log "Verificando recursos del sistema..."

    # Detectar sistema operativo
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     os=Linux;;
        Darwin*)    os=Mac;;
        *)          os="UNKNOWN";;
    esac

    # Verificar memoria disponible (mínimo 1GB)
    if [ "$os" = "Mac" ]; then
        # macOS: memoria libre = (memoria libre + memoria inactiva) en GB
        mem_free=$(vm_stat | awk '/Pages free/ {free=$3} /Pages inactive/ {inactive=$3} END {print (free+inactive)*4096/1024/1024/1024}')
        available_mem=$(printf "%.1f" "$mem_free")
    else
        # Linux
        available_mem=$(free -m | awk 'NR==2{printf "%.1f", $7/1024}')
    fi
    if (( $(echo "$available_mem < 1.0" | bc -l) )); then
        warn "Memoria disponible baja: ${available_mem}GB. Se recomienda al menos 1GB."
    fi

    # Verificar espacio en disco (mínimo 2GB)
    if [ "$os" = "Mac" ]; then
        available_disk=$(df -g . | awk 'NR==2 {print $4}')
    else
        available_disk=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    fi
    if [[ $available_disk -lt 2 ]]; then
        warn "Espacio en disco bajo: ${available_disk}GB. Se recomienda al menos 2GB."
    fi

    log "Recursos del sistema verificados ✓"
}

# Limpiar contenedores anteriores
cleanup() {
    log "Limpiando contenedores anteriores..."
    docker compose down --volumes --remove-orphans 2>/dev/null || true
    
    # Remover imágenes no utilizadas
    docker system prune -f &>/dev/null || true
    
    log "Limpieza completada ✓"
}

# Construir las imágenes
build_images() {
    log "Construyendo imágenes Docker..."
    docker compose build --no-cache
    log "Imágenes construidas exitosamente ✓"
}

# Iniciar los servicios
start_services() {
    log "Iniciando servicios con Docker Compose..."
    docker compose up -d
    
    log "Esperando que los servicios estén listos..."
    sleep 1
    
    # Verificar que los servicios estén ejecutándose
    if ! docker compose ps | grep -q "Up"; then
        error "Algunos servicios no se iniciaron correctamente"
        docker compose logs
        exit 1
    fi
    
    log "Servicios iniciados exitosamente ✓"
}

# Verificar health checks
verify_health() {
    log "Verificando salud de los servicios..."
    
    max_retries=30
    retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        # Verificar NGINX
        if curl -s http://localhost:8080/nginx-health > /dev/null; then
            # Verificar API através del load balancer
            if curl -s http://localhost:8080/api/health > /dev/null; then
                log "Todos los servicios están saludables ✓"
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        echo -n "."
        sleep 2
    done
    
    error "Los servicios no pasaron las verificaciones de salud"
    docker-compose logs
    exit 1
}

# Mostrar información del sistema
show_system_info() {
    log "Sistema iniciado exitosamente! 🎉"
    echo
    echo -e "${BLUE}=== INFORMACIÓN DEL SISTEMA ===${NC}"
    echo -e "📊 Load Balancer:    http://localhost:8080"
    echo -e "🔍 Health Check:     http://localhost:8080/api/health"
    echo
    echo -e "${BLUE}=== SERVICIOS ACTIVOS ===${NC}"
    docker compose ps
    echo
    echo -e "${BLUE}=== ENDPOINTS DISPONIBLES ===${NC}"
    echo -e "POST /api/register    - Registrar usuario"
    echo -e "POST /api/login       - Iniciar sesión"
    echo -e "POST /api/orders      - Crear pedido"
    echo -e "GET  /api/orders      - Listar pedidos"
    echo -e "GET  /api/orders/{id} - Consultar pedido"
    echo -e "PUT  /api/orders/{id} - Actualizar pedido"
    echo -e "GET  /api/stats       - Estadísticas del sistema"
    echo
    echo -e "${GREEN}El sistema está listo para usar! 🚀${NC}"
}

# Función principal
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║          🛒 ORDERS API STARTUP               ║"
    echo "║      Sistema de Pedidos con Alta             ║"
    echo "║      Disponibilidad y Replicación            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_docker
    check_system_resources
    cleanup
    build_images
    start_services
    verify_health
    show_system_info
}

# Manejo de señales para limpieza
trap cleanup INT TERM

# Ejecutar función principal
main "$@"