#!/bin/bash

# =============================================================================
# Script de Configuración Inicial
# Configura el entorno para el despliegue de la landing page
# =============================================================================

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Verificar si Node.js está instalado
check_nodejs() {
    if ! command -v node &> /dev/null; then
        print_error "Node.js no está instalado. Por favor instala Node.js 16+ desde https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2)
    print_message "Node.js versión: $NODE_VERSION"
}

# Verificar si AWS CLI está instalado
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI no está instalado."
        print_message "Instala AWS CLI desde: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    AWS_VERSION=$(aws --version)
    print_message "AWS CLI: $AWS_VERSION"
}

# Verificar credenciales de AWS
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "Las credenciales de AWS no están configuradas correctamente."
        print_message "Ejecuta: aws configure"
        print_message "O configura las variables de entorno AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    print_message "Cuenta AWS: $ACCOUNT_ID"
    print_message "Usuario: $USER_ARN"
}

# Instalar dependencias de Node.js
install_dependencies() {
    print_message "Instalando dependencias de Node.js..."
    npm install
    
    # Instalar Serverless Framework globalmente si no está instalado
    if ! command -v serverless &> /dev/null; then
        print_message "Instalando Serverless Framework globalmente..."
        npm install -g serverless
    fi
    
    SERVERLESS_VERSION=$(serverless -v)
    print_message "Serverless Framework: $SERVERLESS_VERSION"
}

# Crear archivo de configuración local
create_config() {
    if [ ! -f ".env" ]; then
        print_message "Creando archivo de configuración .env..."
        cat > .env << EOF
# Configuración del proyecto
PROJECT_NAME=medtech-landing-page
AWS_REGION=us-east-1
STAGE=dev

# Configuración opcional
# AWS_PROFILE=default
# CUSTOM_DOMAIN=tu-dominio.com
EOF
        print_message "Archivo .env creado. Puedes editarlo según tus necesidades."
    else
        print_message "El archivo .env ya existe."
    fi
}

# Verificar estructura de carpetas
check_structure() {
    print_message "Verificando estructura de carpetas..."
    
    if [ ! -d "src" ]; then
        print_error "La carpeta 'src' no existe. Asegúrate de que los archivos de la landing page estén en src/"
        exit 1
    fi
    
    if [ ! -f "src/index.html" ]; then
        print_error "El archivo src/index.html no existe."
        exit 1
    fi
    
    print_message "Estructura de carpetas verificada ✓"
}

# Función principal
main() {
    print_header "CONFIGURACIÓN INICIAL DEL PROYECTO"
    
    print_message "Iniciando configuración del proyecto MedTech Landing Page..."
    
    # Verificaciones
    check_nodejs
    check_aws_cli
    check_aws_credentials
    check_structure
    
    # Instalación y configuración
    install_dependencies
    create_config
    
    print_header "CONFIGURACIÓN COMPLETADA"
    print_message "El proyecto está listo para ser desplegado!"
    print_message ""
    print_message "Próximos pasos:"
    print_message "1. Revisa el archivo .env si necesitas cambiar la configuración"
    print_message "2. Ejecuta: npm run deploy-dev (para desarrollo)"
    print_message "3. Ejecuta: npm run deploy-prod (para producción)"
    print_message ""
    print_message "Para más información, consulta docs/DEPLOYMENT.md"
}

# Ejecutar función principal
main "$@"

