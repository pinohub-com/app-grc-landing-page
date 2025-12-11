#!/bin/bash
# Simple Deploy Script - app-pinohub-landing

set -e

STAGE=${1:-dev}
BUCKET_NAME="app-pinohub-landing"
REGION=${AWS_REGION:-us-east-1}

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/../src"

echo "Desplegando app-pinohub-landing..."
echo "Origen: $SOURCE_DIR"
echo "Bucket: $BUCKET_NAME"

# Verificar que el directorio fuente existe
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: No se encuentra el directorio fuente: $SOURCE_DIR"
    exit 1
fi

# Crear bucket si no existe
if ! aws s3 ls "s3://$BUCKET_NAME" >/dev/null 2>&1; then
    echo "Creando bucket: $BUCKET_NAME"
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
else
    echo "Bucket ya existe: $BUCKET_NAME"
fi

# Subir archivos (incluyendo todos los subdirectorios y archivos)
echo "Subiendo archivos desde $SOURCE_DIR..."
aws s3 sync "$SOURCE_DIR/" "s3://$BUCKET_NAME" --delete --exclude "README.md"

# Configurar hosting web
aws s3 website "s3://$BUCKET_NAME" --index-document index.html --error-document index.html 2>/dev/null || true

# Configurar acceso público
aws s3api put-public-access-block --bucket "$BUCKET_NAME" --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false 2>/dev/null || true

# Aplicar política pública
cat > temp-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    },
    {
      "Sid": "PublicReadBucket",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::$BUCKET_NAME"
    }
  ]
}
EOF

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file://temp-policy.json 2>/dev/null || true
rm -f temp-policy.json

# Crear distribución CloudFront
echo "Creando distribución CloudFront (HTTPS)..."
cat > cloudfront-config.json << EOF
{
  "CallerReference": "$BUCKET_NAME-$(date +%s)",
  "Comment": "app-pinohub-landing - $STAGE",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [{
      "Id": "S3Origin",
      "DomainName": "$BUCKET_NAME.s3-website-$REGION.amazonaws.com",
      "CustomOriginConfig": {
        "HTTPPort": 80,
        "HTTPSPort": 443,
        "OriginProtocolPolicy": "http-only"
      }
    }]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3Origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "TrustedSigners": { "Enabled": false, "Quantity": 0 },
    "ForwardedValues": { "QueryString": false, "Cookies": { "Forward": "none" } },
    "MinTTL": 0,
    "Compress": true
  },
  "Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF

CLOUDFRONT_URL=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query "Distribution.DomainName" --output text 2>/dev/null)
rm -f cloudfront-config.json

# Mostrar resultado
WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo ""
echo "LISTO! Tu sitio esta online:"
echo "S3 URL: $WEBSITE_URL"
if [ ! -z "$CLOUDFRONT_URL" ]; then
    echo "HTTPS URL: https://$CLOUDFRONT_URL"
    echo ""
    echo "Usa la URL HTTPS para acceso seguro y rapido!"
else
    echo "CloudFront: Creando... (puede tardar 15 minutos)"
fi
echo ""