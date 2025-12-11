@echo off
REM =============================================================================
REM Script de Inicio Rápido para Windows
REM Configuración y despliegue automático de la landing page
REM =============================================================================

echo ================================
echo   MEDTECH LANDING PAGE SETUP   
echo ================================
echo.

REM Verificar si Node.js está instalado
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js no está instalado.
    echo Por favor instala Node.js desde: https://nodejs.org/
    pause
    exit /b 1
)

echo [INFO] Node.js detectado: 
node --version

REM Verificar si AWS CLI está instalado
aws --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] AWS CLI no está instalado.
    echo Por favor instala AWS CLI desde: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

echo [INFO] AWS CLI detectado:
aws --version

REM Verificar credenciales AWS
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Credenciales AWS no configuradas.
    echo Ejecuta: aws configure
    pause
    exit /b 1
)

echo [INFO] Credenciales AWS configuradas correctamente.

REM Instalar dependencias
echo.
echo [INFO] Instalando dependencias...
call npm install

REM Instalar Serverless Framework globalmente si no existe
serverless --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Instalando Serverless Framework...
    call npm install -g serverless
)

REM Crear archivo .env si no existe
if not exist ".env" (
    echo [INFO] Creando archivo de configuración .env...
    copy env.example .env
    echo [INFO] Archivo .env creado. Puedes editarlo según tus necesidades.
)

echo.
echo ================================
echo   CONFIGURACIÓN COMPLETADA     
echo ================================
echo.
echo El proyecto está listo para ser desplegado!
echo.
echo Próximos pasos:
echo 1. Revisa el archivo .env si necesitas cambiar la configuración
echo 2. Ejecuta: npm run deploy-dev (para desarrollo)
echo 3. Ejecuta: npm run deploy-prod (para producción)
echo.
echo Para más información, consulta docs/DEPLOYMENT.md
echo.

REM Preguntar si desea desplegar ahora
set /p deploy="¿Deseas desplegar en desarrollo ahora? (y/n): "
if /i "%deploy%"=="y" (
    echo.
    echo [INFO] Desplegando en desarrollo...
    call npm run deploy-dev
    echo.
    echo ¡Despliegue completado!
) else (
    echo.
    echo Puedes desplegar más tarde con: npm run deploy-dev
)

echo.
echo ¡Gracias por usar MedTech Landing Page! 🚀
pause



