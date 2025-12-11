# PinoHub - Página Web Estática

Página web estática profesional para emprendimiento de desarrollo de software con IA, usando la paleta de colores natural de verdes y beige.

## 🎨 Características

- **Diseño Moderno y Profesional**: UI/UX optimizada con animaciones suaves
- **Completamente Responsive**: Adaptada para móviles, tablets y desktop
- **Paleta de Colores Personalizada**: Verdes naturales y beige según imagen proporcionada
- **Secciones Incluidas**:
  - Hero section con llamada a la acción
  - Servicios de desarrollo con IA
  - Tecnologías y stack tecnológico
  - Portafolio de proyectos
  - Estadísticas animadas
  - Formulario de contacto
  - Footer completo con newsletter
- **Interactividad JavaScript**: Navegación suave, animaciones, validación de formularios
- **Optimizada para SEO**: Meta tags y estructura semántica HTML5
- **Performance**: Código limpio y optimizado

## 📁 Estructura de Archivos

```
pinohub/
├── index.html          # Estructura principal HTML
├── styles.css          # Estilos CSS con paleta personalizada
├── script.js           # Interactividad JavaScript
└── README.md           # Este archivo
```

## 🚀 Despliegue en AWS S3

### Opción 1: Consola de AWS (Interfaz Gráfica)

1. **Crear un Bucket S3**:
   - Ve a la consola de AWS S3
   - Clic en "Create bucket"
   - Nombre del bucket: `pinohub-website` (debe ser único globalmente)
   - Región: Selecciona la más cercana a tus usuarios
   - **Desactiva** "Block all public access" (necesario para hosting web)
   - Confirma que entiendes que el bucket será público
   - Clic en "Create bucket"

2. **Configurar Hosting Web Estático**:
   - Selecciona tu bucket
   - Ve a la pestaña "Properties"
   - Scroll hasta "Static website hosting"
   - Clic en "Edit"
   - Selecciona "Enable"
   - Index document: `index.html`
   - Error document: `index.html`
   - Guarda los cambios
   - **Anota la URL del endpoint** (algo como: `http://pinohub-website.s3-website-us-east-1.amazonaws.com`)

3. **Configurar Permisos (Bucket Policy)**:
   - Ve a la pestaña "Permissions"
   - En "Bucket policy", clic en "Edit"
   - Pega la siguiente política (reemplaza `pinohub-website` con tu nombre de bucket):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::pinohub-website/*"
        }
    ]
}
```

4. **Subir Archivos**:
   - Ve a la pestaña "Objects"
   - Clic en "Upload"
   - Arrastra o selecciona los archivos: `index.html`, `styles.css`, `script.js`
   - Clic en "Upload"

5. **Acceder a tu Sitio**:
   - Usa la URL del endpoint que anotaste en el paso 2
   - Tu sitio estará disponible públicamente

### Opción 2: AWS CLI (Línea de Comandos)

```bash
# 1. Instalar AWS CLI (si no lo tienes)
# Windows: descargar desde https://aws.amazon.com/cli/
# Mac: brew install awscli
# Linux: sudo apt-get install awscli

# 2. Configurar credenciales AWS
aws configure
# Ingresa tu AWS Access Key ID
# Ingresa tu AWS Secret Access Key
# Región por defecto: us-east-1 (o la que prefieras)
# Output format: json

# 3. Crear bucket
aws s3 mb s3://pinohub-website --region us-east-1

# 4. Habilitar hosting web
aws s3 website s3://pinohub-website --index-document index.html --error-document index.html

# 5. Aplicar bucket policy para acceso público
# Primero crea un archivo bucket-policy.json con el contenido:
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::pinohub-website/*"
        }
    ]
}

# Luego aplica la política:
aws s3api put-bucket-policy --bucket pinohub-website --policy file://bucket-policy.json

# 6. Desactivar Block Public Access
aws s3api put-public-access-block --bucket pinohub-website --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# 7. Subir archivos al bucket
aws s3 sync . s3://pinohub-website --exclude ".git/*" --exclude "README.md"

# 8. Obtener la URL del sitio
echo "http://pinohub-website.s3-website-us-east-1.amazonaws.com"
```

### Opción 3: Con CloudFront (CDN) - Recomendado para Producción

CloudFront proporciona:
- HTTPS gratuito con certificado AWS
- Mejor rendimiento global (CDN)
- Dominio personalizado
- Caché para mejor velocidad

```bash
# 1. Crear distribución de CloudFront (desde consola AWS):
# - Origin Domain: selecciona tu bucket S3
# - Origin Access: Public
# - Viewer Protocol Policy: Redirect HTTP to HTTPS
# - Default Root Object: index.html
# - Create Distribution

# 2. Espera 10-15 minutos para que se active
# 3. Usa el dominio CloudFront proporcionado (algo como d111111abcdef8.cloudfront.net)
```

## 🔧 Personalización

### Cambiar Colores
Edita las variables CSS en `styles.css`:

```css
:root {
    --color-primary: #1a1f1a;      /* Verde oscuro */
    --color-secondary: #4a5a3f;    /* Verde militar */
    --color-accent: #9db56c;       /* Verde claro */
    --color-light: #e8e4d0;        /* Beige */
    --color-muted: #a8b5a0;        /* Verde grisáceo */
}
```

### Modificar Contenido
- **Textos**: Edita directamente en `index.html`
- **Logo**: Reemplaza el ícono de Font Awesome en la clase `.logo`
- **Servicios**: Modifica la sección `.services-grid`
- **Proyectos**: Actualiza la sección `.projects-grid`
- **Contacto**: Cambia email, teléfono y redes sociales en la sección `.contact`

### Agregar Imágenes
1. Sube imágenes a una carpeta `/images` en tu bucket S3
2. Actualiza las referencias en HTML:
```html
<img src="images/tu-imagen.jpg" alt="Descripción">
```

## 📱 Compatibilidad

- ✅ Chrome, Firefox, Safari, Edge (últimas versiones)
- ✅ Responsive: Mobile, Tablet, Desktop
- ✅ Optimizado para rendimiento
- ✅ Accesibilidad WCAG 2.1

## 🔒 Seguridad

- No incluye datos sensibles en el código
- Formulario de contacto solo frontend (conectar con backend/servicio)
- Para formularios funcionales, considera integrar:
  - AWS Lambda + API Gateway
  - FormSpree
  - Netlify Forms
  - EmailJS

## 📊 Analytics (Opcional)

Para agregar Google Analytics, añade antes del `</head>` en `index.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=TU-ID-AQUI"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'TU-ID-AQUI');
</script>
```

## 💰 Costos Estimados AWS

- **S3**: ~$0.023 por GB/mes + $0.005 por 1,000 requests
- **CloudFront**: ~$0.085 por GB transferido (primeros 10 TB)
- **Dominio personalizado (Route 53)**: ~$12/año

Para un sitio pequeño con poco tráfico: **< $1-2/mes**

## 🆘 Soporte

Para dudas o personalizaciones:
- Email: contacto@pinohub.com
- Documentación AWS S3: https://docs.aws.amazon.com/s3/
- Documentación CloudFront: https://docs.aws.amazon.com/cloudfront/

## 📝 Licencia

Este proyecto es de uso privado para PinoHub.

---

**Desarrollado con ❤️ usando HTML, CSS y JavaScript puro**

