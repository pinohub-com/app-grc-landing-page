#!/bin/bash

# =============================================================================
# Script de Invalidación de Caché
# Invalida el caché de CloudFront para forzar actualización
# =============================================================================

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables por defecto
STAGE=${1:-dev}
REGION=${AWS_REGION:-us-east-1}

# Función para imprimir mensajes con colores
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Cargar variables de entorno si existe el archivo .env
load_env() {
    if [ -f ".env" ]; then
        print_message "Cargando variables de entorno desde .env"
        export $(cat .env | grep -v '#' | xargs)
        STAGE=${STAGE:-$STAGE}
        REGION=${AWS_REGION:-$REGION}
    fi
}

# Verificar prerequisitos
check_prerequisites() {
    print_message "Verificando prerequisitos..."
    
    # Verificar credenciales AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "Las credenciales de AWS no están configuradas."
        print_message "Ejecuta: aws configure"
        exit 1
    fi
    
    print_message "Prerequisitos verificados ✓"
}

# Invalidar caché de CloudFront
invalidate_cache() {
    print_header "INVALIDACIÓN DE CACHÉ DE CLOUDFRONT"
    
    # Obtener el ID de la distribución
    print_message "Obteniendo ID de la distribución de CloudFront..."
    
    DISTRIBUTION_ID=$(serverless info --stage $STAGE --region $REGION 2>/dev/null | grep "DistributionId" | cut -d' ' -f2 || echo "")
    
    if [ -z "$DISTRIBUTION_ID" ]; then
        print_error "No se pudo obtener el ID de la distribución de CloudFront"
        print_message "Asegúrate de que el stack esté desplegado correctamente"
        exit 1
    fi
    
    print_message "ID de distribución: $DISTRIBUTION_ID"
    
    # Crear invalidación
    print_message "Creando invalidación para todos los archivos..."
    
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    print_message "Invalidación creada con ID: $INVALIDATION_ID"
    
    # Esperar a que complete (opcional)
    if [ "$2" = "--wait" ]; then
        print_message "Esperando a que complete la invalidación..."
        aws cloudfront wait invalidation-completed \
            --distribution-id $DISTRIBUTION_ID \
            --id $INVALIDATION_ID
        print_message "Invalidación completada ✓"
    else
        print_message "La invalidación está en progreso. Puede tardar 5-15 minutos."
        print_message "Para esperar a que complete, usa: $0 $STAGE --wait"
    fi
}

# Mostrar estado de la invalidación
show_invalidation_status() {
    if [ -n "$DISTRIBUTION_ID" ] && [ -n "$INVALIDATION_ID" ]; then
        print_header "ESTADO DE LA INVALIDACIÓN"
        
        STATUS=$(aws cloudfront get-invalidation \
            --distribution-id $DISTRIBUTION_ID \
            --id $INVALIDATION_ID \
            --query 'Invalidation.Status' \
            --output text)
        
        print_message "Estado: $STATUS"
        
        if [ "$STATUS" = "Completed" ]; then
            print_message "✅ La invalidación ha completado"
            print_message "🌐 Los cambios ya están disponibles globalmente"
        else
            print_message "⏳ La invalidación está en progreso"
            print_message "🕒 Tiempo estimado: 5-15 minutos"
        fi
    fi
}

# Función principal
main() {
    print_header "INVALIDACIÓN DE CACHÉ - GRC LANDING PAGE"
    
    # Cargar configuración
    load_env
    
    # Verificaciones
    check_prerequisites
    
    # Mostrar información
    print_message "Stage: $STAGE"
    print_message "Región: $REGION"
    echo
    
    # Invalidar caché
    invalidate_cache
    
    # Mostrar estado
    show_invalidation_status
    
    print_message "¡Invalidación de caché iniciada exitosamente! 🚀"
}

# Ayuda
show_help() {
    echo "Uso: $0 [STAGE] [--wait]"
    echo
    echo "STAGE: dev (por defecto), staging, prod"
    echo "--wait: Esperar a que complete la invalidación"
    echo
    echo "Ejemplos:"
    echo "  $0              # Invalida caché de dev"
    echo "  $0 prod         # Invalida caché de prod"
    echo "  $0 dev --wait   # Invalida y espera a completar"
    echo
    echo "Variables de entorno:"
    echo "  AWS_REGION: Región de AWS (default: us-east-1)"
    echo "  AWS_PROFILE: Perfil de AWS a usar"
}

# Verificar argumentos
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Ejecutar función principal
main "$@"

