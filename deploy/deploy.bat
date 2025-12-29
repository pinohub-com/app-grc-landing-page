@echo off
REM Simple Deploy Script - GRC Landing Page

set STAGE=%1
if "%STAGE%"=="" set STAGE=dev
set BUCKET_NAME=grc-landing-%STAGE%
set REGION=us-east-1

echo Desplegando GRC Landing Page...

REM Verificar credenciales básicas
if "%AWS_ACCESS_KEY_ID%"=="" (
    echo ERROR: Configura AWS_ACCESS_KEY_ID primero
    exit /b 1
)
if "%AWS_SECRET_ACCESS_KEY%"=="" (
    echo ERROR: Configura AWS_SECRET_ACCESS_KEY primero
    exit /b 1
)

REM Crear bucket si no existe
aws s3 ls s3://%BUCKET_NAME% >nul 2>&1
if errorlevel 1 (
    echo Creando bucket: %BUCKET_NAME%
    aws s3 mb s3://%BUCKET_NAME% --region %REGION%
    if errorlevel 1 (
        echo ERROR: No se pudo crear el bucket
        exit /b 1
    )
) else (
    echo Bucket ya existe: %BUCKET_NAME%
)

REM Subir archivos
echo Subiendo archivos...
aws s3 sync src\ s3://%BUCKET_NAME% --delete
if errorlevel 1 (
    echo ERROR: No se pudieron subir los archivos
    exit /b 1
)

REM Configurar hosting web
aws s3 website s3://%BUCKET_NAME% --index-document index.html --error-document index.html >nul 2>&1

REM Configurar acceso público
aws s3api put-public-access-block --bucket %BUCKET_NAME% --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false >nul 2>&1

REM Aplicar política pública
echo { > temp-policy.json
echo   "Version": "2012-10-17", >> temp-policy.json
echo   "Statement": [ >> temp-policy.json
echo     { >> temp-policy.json
echo       "Sid": "PublicReadGetObject", >> temp-policy.json
echo       "Effect": "Allow", >> temp-policy.json
echo       "Principal": "*", >> temp-policy.json
echo       "Action": "s3:GetObject", >> temp-policy.json
echo       "Resource": "arn:aws:s3:::%BUCKET_NAME%/*" >> temp-policy.json
echo     }, >> temp-policy.json
echo     { >> temp-policy.json
echo       "Sid": "PublicReadBucket", >> temp-policy.json
echo       "Effect": "Allow", >> temp-policy.json
echo       "Principal": "*", >> temp-policy.json
echo       "Action": "s3:ListBucket", >> temp-policy.json
echo       "Resource": "arn:aws:s3:::%BUCKET_NAME%" >> temp-policy.json
echo     } >> temp-policy.json
echo   ] >> temp-policy.json
echo } >> temp-policy.json

aws s3api put-bucket-policy --bucket %BUCKET_NAME% --policy file://temp-policy.json >nul 2>&1
del temp-policy.json >nul 2>&1

REM Crear distribución CloudFront
echo Creando distribucion CloudFront (HTTPS)...
echo { > cloudfront-config.json
echo   "CallerReference": "%BUCKET_NAME%-%RANDOM%", >> cloudfront-config.json
echo   "Comment": "GRC Landing Page - %STAGE%", >> cloudfront-config.json
echo   "DefaultRootObject": "index.html", >> cloudfront-config.json
echo   "Origins": { >> cloudfront-config.json
echo     "Quantity": 1, >> cloudfront-config.json
echo     "Items": [{ >> cloudfront-config.json
echo       "Id": "S3Origin", >> cloudfront-config.json
echo       "DomainName": "%BUCKET_NAME%.s3-website-%REGION%.amazonaws.com", >> cloudfront-config.json
echo       "CustomOriginConfig": { >> cloudfront-config.json
echo         "HTTPPort": 80, >> cloudfront-config.json
echo         "HTTPSPort": 443, >> cloudfront-config.json
echo         "OriginProtocolPolicy": "http-only" >> cloudfront-config.json
echo       } >> cloudfront-config.json
echo     }] >> cloudfront-config.json
echo   }, >> cloudfront-config.json
echo   "DefaultCacheBehavior": { >> cloudfront-config.json
echo     "TargetOriginId": "S3Origin", >> cloudfront-config.json
echo     "ViewerProtocolPolicy": "redirect-to-https", >> cloudfront-config.json
echo     "TrustedSigners": { "Enabled": false, "Quantity": 0 }, >> cloudfront-config.json
echo     "ForwardedValues": { "QueryString": false, "Cookies": { "Forward": "none" } }, >> cloudfront-config.json
echo     "MinTTL": 0, >> cloudfront-config.json
echo     "Compress": true >> cloudfront-config.json
echo   }, >> cloudfront-config.json
echo   "Enabled": true, >> cloudfront-config.json
echo   "PriceClass": "PriceClass_100" >> cloudfront-config.json
echo } >> cloudfront-config.json

for /f "tokens=*" %%i in ('aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query "Distribution.DomainName" --output text 2^>nul') do set CLOUDFRONT_URL=%%i
del cloudfront-config.json >nul 2>&1

REM Mostrar resultado
set WEBSITE_URL=http://%BUCKET_NAME%.s3-website-%REGION%.amazonaws.com
echo.
echo LISTO! Tu sitio esta online:
echo S3 URL: %WEBSITE_URL%
if not "%CLOUDFRONT_URL%"=="" (
    echo HTTPS URL: https://%CLOUDFRONT_URL%
    echo.
    echo Usa la URL HTTPS para acceso seguro y rapido!
) else (
    echo CloudFront: Creando... ^(puede tardar 15 minutos^)
)
echo.
