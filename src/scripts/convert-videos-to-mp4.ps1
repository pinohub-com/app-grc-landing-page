# Script para convertir videos .MOV a .MP4
# Requiere ffmpeg instalado
# Uso: .\scripts\convert-videos-to-mp4.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Conversor de Videos .MOV a .MP4" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si ffmpeg esta instalado
$ffmpegPath = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegPath) {
    Write-Host "ERROR: ffmpeg no esta instalado o no esta en el PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para instalar ffmpeg:" -ForegroundColor Yellow
    Write-Host "1. Descarga desde: https://ffmpeg.org/download.html" -ForegroundColor Yellow
    Write-Host "2. O usa chocolatey: choco install ffmpeg" -ForegroundColor Yellow
    Write-Host "3. O usa winget: winget install ffmpeg" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] ffmpeg encontrado" -ForegroundColor Green
Write-Host ""

# Directorios
$sourceDir = "artifacts\moda"
$outputDir = "videos"

# Crear directorio de salida si no existe
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "[OK] Directorio '$outputDir' creado" -ForegroundColor Green
}

# Buscar archivos .MOV
$movFiles = Get-ChildItem -Path $sourceDir -Filter "*.MOV" -ErrorAction SilentlyContinue

if ($movFiles.Count -eq 0) {
    Write-Host "No se encontraron archivos .MOV en '$sourceDir'" -ForegroundColor Yellow
    exit 0
}

Write-Host "Encontrados $($movFiles.Count) archivo(s) .MOV" -ForegroundColor Cyan
Write-Host ""

# Convertir cada archivo
$converted = 0
$skipped = 0

foreach ($file in $movFiles) {
    $inputFile = $file.FullName
    $outputFile = Join-Path $outputDir "$($file.BaseName).mp4"
    
    # Verificar si el archivo MP4 ya existe
    if (Test-Path $outputFile) {
        Write-Host "[SKIP] $($file.Name) -> ya existe $($file.BaseName).mp4" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    Write-Host "[CONVIRTIENDO] $($file.Name) -> $($file.BaseName).mp4" -ForegroundColor Cyan
    
    # Comando ffmpeg para convertir a MP4 (H.264, compatible con navegadores)
    $ffmpegArgs = @(
        "-i", "`"$inputFile`"",
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "23",
        "-c:a", "aac",
        "-b:a", "128k",
        "-movflags", "+faststart",
        "-y",
        "`"$outputFile`""
    )
    
    try {
        $process = Start-Process -FilePath "ffmpeg" -ArgumentList $ffmpegArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput "nul" -RedirectStandardError "nul"
        
        if ($process.ExitCode -eq 0) {
            Write-Host "  [OK] Convertido exitosamente" -ForegroundColor Green
            $converted++
        } else {
            Write-Host "  [ERROR] Error en la conversion (codigo: $($process.ExitCode))" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [ERROR] Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Resumen:" -ForegroundColor Cyan
Write-Host "  Convertidos: $converted" -ForegroundColor Green
Write-Host "  Omitidos: $skipped" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
