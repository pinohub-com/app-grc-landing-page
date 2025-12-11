#!/bin/bash

# =============================================================================
# Script de Destrucción
# Elimina todos los recursos AWS creados por el proyecto
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
    
    # Verificar que serverless esté instalado
    if ! command -v serverless &> /dev/null; then
        print_error "Serverless Framework no está instalado."
        print_message "Ejecuta: npm install -g serverless"
        exit 1
    fi
    
    # Verificar credenciales AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "Las credenciales de AWS no están configuradas."
        print_message "Ejecuta: aws configure"
        exit 1
    fi
    
    print_message "Prerequisitos verificados ✓"
}

# Mostrar información de la destrucción
show_destruction_info() {
    print_header "INFORMACIÓN DE LA DESTRUCCIÓN"
    print_message "Stage: $STAGE"
    print_message "Región: $REGION"
    print_message "Cuenta AWS: $(aws sts get-caller-identity --query Account --output text)"
    print_message "Usuario: $(aws sts get-caller-identity --query Arn --output text)"
    echo
}

# Confirmar destrucción
confirm_destruction() {
    print_warning "¡ATENCIÓN! Vas a ELIMINAR todos los recursos del stage '$STAGE'."
    print_warning "Esto incluye:"
    print_warning "- Bucket S3 y todo su contenido"
    print_warning "- Distribución de CloudFront"
    print_warning "- Todas las configuraciones relacionadas"
    echo
    
    if [ "$STAGE" = "prod" ]; then
        print_error "¡CUIDADO! Estás a punto de eliminar PRODUCCIÓN."
        read -p "Escribe 'DELETE PRODUCTION' para continuar: " -r
        if [ "$REPLY" != "DELETE PRODUCTION" ]; then
            print_message "Destrucción cancelada."
            exit 0
        fi
    else
        read -p "¿Estás seguro? Escribe 'yes' para continuar: " -r
        if [ "$REPLY" != "yes" ]; then
            print_message "Destrucción cancelada."
            exit 0
        fi
    fi
}

# Vaciar bucket S3 antes de eliminar
empty_s3_bucket() {
    print_message "Obteniendo información del bucket..."
    
    # Intentar obtener el nombre del bucket
    BUCKET_NAME=$(serverless info --stage $STAGE --region $REGION 2>/dev/null | grep "BucketName" | cut -d' ' -f2 || echo "")
    
    if [ -n "$BUCKET_NAME" ]; then
        print_message "Vaciando bucket S3: $BUCKET_NAME"
        
        # Verificar si el bucket existe
        if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
            # Eliminar todos los objetos del bucket
            aws s3 rm "s3://$BUCKET_NAME" --recursive
            print_message "Bucket vaciado exitosamente"
        else
            print_warning "El bucket $BUCKET_NAME no existe o no es accesible"
        fi
    else
        print_warning "No se pudo obtener el nombre del bucket"
    fi
}

# Función principal de destrucción
destroy() {
    print_header "INICIANDO DESTRUCCIÓN"
    
    # Vaciar bucket S3 primero
    empty_s3_bucket
    
    # Eliminar stack de CloudFormation
    print_message "Eliminando recursos de AWS..."
    serverless remove --stage $STAGE --region $REGION --verbose
    
    print_header "DESTRUCCIÓN COMPLETADA"
}

# Verificar que la destrucción fue exitosa
verify_destruction() {
    print_message "Verificando que los recursos fueron eliminados..."
    
    # Intentar obtener información del stack
    if serverless info --stage $STAGE --region $REGION &> /dev/null; then
        print_warning "Algunos recursos pueden no haberse eliminado completamente."
        print_message "Esto es normal para CloudFront, que puede tardar hasta 15 minutos en eliminarse."
    else
        print_message "Todos los recursos fueron eliminados exitosamente ✓"
    fi
}

# Función de cleanup en caso de error
cleanup_on_error() {
    print_error "Error durante la destrucción."
    print_message "Puedes intentar:"
    print_message "1. Verificar las credenciales AWS"
    print_message "2. Eliminar manualmente el bucket S3 si existe"
    print_message "3. Verificar la consola de AWS CloudFormation"
    print_message "4. Ejecutar nuevamente el script"
}

# Trap para manejar errores
trap cleanup_on_error ERR

# Función principal
main() {
    print_header "DESTRUCCIÓN DE MEDTECH LANDING PAGE"
    
    # Cargar configuración
    load_env
    
    # Verificaciones
    check_prerequisites
    show_destruction_info
    confirm_destruction
    
    # Destrucción
    destroy
    
    # Verificar destrucción
    verify_destruction
    
    print_message "¡Recursos eliminados exitosamente! 🗑️"
    print_message "Tu cuenta AWS ya no tiene los recursos de este proyecto."
}

# Ayuda
show_help() {
    echo "Uso: $0 [STAGE]"
    echo
    echo "STAGE: dev (por defecto), staging, prod"
    echo
    echo "Ejemplos:"
    echo "  $0          # Elimina recursos de dev"
    echo "  $0 dev      # Elimina recursos de dev"
    echo "  $0 staging  # Elimina recursos de staging"
    echo "  $0 prod     # Elimina recursos de producción"
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

