@echo off
REM Script para convertir videos .MOV a .MP4
REM Requiere ffmpeg instalado
REM Uso: scripts\convert-videos-to-mp4.bat

echo ========================================
echo Conversor de Videos .MOV a .MP4
echo ========================================
echo.

REM Verificar si ffmpeg está instalado
where ffmpeg >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ffmpeg no esta instalado o no esta en el PATH
    echo.
    echo Para instalar ffmpeg:
    echo 1. Descarga desde: https://ffmpeg.org/download.html
    echo 2. O usa chocolatey: choco install ffmpeg
    echo 3. O usa winget: winget install ffmpeg
    exit /b 1
)

echo [OK] ffmpeg encontrado
echo.

REM Directorios
set "sourceDir=artifacts\moda"
set "outputDir=videos"

REM Crear directorio de salida si no existe
if not exist "%outputDir%" mkdir "%outputDir%"

REM Convertir cada archivo .MOV
set converted=0
set skipped=0

for %%F in ("%sourceDir%\*.MOV") do (
    set "inputFile=%%F"
    set "outputFile=%outputDir%\%%~nF.mp4"
    
    REM Verificar si el archivo MP4 ya existe
    if exist "!outputFile!" (
        echo [SKIP] %%~nxF -^> ya existe %%~nF.mp4
        set /a skipped+=1
        goto :next
    )
    
    echo [CONVIRTIENDO] %%~nxF -^> %%~nF.mp4
    
    REM Comando ffmpeg para convertir a MP4
    ffmpeg -i "!inputFile!" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k -movflags +faststart -y "!outputFile!" >nul 2>&1
    
    if %ERRORLEVEL% EQU 0 (
        echo   [OK] Convertido exitosamente
        set /a converted+=1
    ) else (
        echo   [ERROR] Error en la conversion
    )
    echo.
    
    :next
)

echo ========================================
echo Resumen:
echo   Convertidos: %converted%
echo   Omitidos: %skipped%
echo ========================================
pause



