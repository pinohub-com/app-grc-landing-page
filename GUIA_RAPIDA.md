# ⚡ Guía Rápida de Edición - PinoHub

Referencia rápida para las tareas más comunes de edición.

---

## 📝 Ediciones Frecuentes

### 🏷️ Cambiar el nombre de la empresa
**Archivos a editar:**
- `secciones/navbar.html` - Logo en navegación (línea 5-6)
- `secciones/footer.html` - Logo en footer (línea 5-6)
- `index.html` - Título de la página (línea 7)

Buscar y reemplazar: `PinoHub` → `Tu Nombre`

---

### 📧 Cambiar email de contacto
**Archivos a editar:**
1. `secciones/contacto.html` - Email visible (línea ~10)
   ```html
   <p>contacto@pinohub.com</p>
   ```

2. `js/script.js` - Email destino real (línea ~188)
   ```javascript
   to_email: 'cefernal.dev@gmail.com'
   ```

---

### 🎨 Cambiar colores de la página
**Archivo:** `css/styles.css` (líneas 5-12)

```css
:root {
    --color-primary: #1a1f1a;      /* Verde oscuro (navbar, textos) */
    --color-secondary: #4a5a3f;    /* Verde militar (subtítulos) */
    --color-accent: #9db56c;       /* Verde claro (botones, acentos) */
    --color-light: #e8e4d0;        /* Beige (fondo) */
    --color-muted: #a8b5a0;        /* Verde grisáceo (textos secundarios) */
}
```

---

### 📱 Cambiar teléfono
**Archivo:** `secciones/contacto.html` (línea ~16)
```html
<p>+1 (555) 123-4567</p>
```

---

### 🌐 Cambiar redes sociales
**Archivo:** `secciones/contacto.html` (líneas ~27-30)
```html
<a href="https://linkedin.com/in/tuperfil" class="social-link">
    <i class="fab fa-linkedin"></i>
</a>
```

Reemplaza `#` con tus URLs reales de redes sociales.

---

### 🖼️ Cambiar texto del Hero (portada)
**Archivo:** `secciones/hero.html`

**Título principal** (línea 6):
```html
<h1 class="hero-title">Transformamos Ideas en <span class="highlight">Soluciones Inteligentes</span></h1>
```

**Subtítulo** (línea 7):
```html
<p class="hero-subtitle">Desarrollo de software potenciado por Inteligencia Artificial...</p>
```

**Botones** (líneas 9-10):
```html
<a href="#contacto" class="btn btn-primary">Comenzar Proyecto</a>
<a href="#servicios" class="btn btn-secondary">Conocer Más</a>
```

---

### 🛠️ Agregar/Modificar Servicios
**Archivo:** `secciones/servicios.html`

Cada servicio tiene esta estructura:

```html
<div class="service-card">
    <div class="service-icon">
        <i class="fas fa-brain"></i>  <!-- Ícono (buscar más en fontawesome.com) -->
    </div>
    <h3>Desarrollo con IA</h3>  <!-- Título del servicio -->
    <p>Descripción del servicio...</p>  <!-- Descripción -->
    <ul class="service-features">
        <li><i class="fas fa-check"></i> Característica 1</li>
        <li><i class="fas fa-check"></i> Característica 2</li>
        <li><i class="fas fa-check"></i> Característica 3</li>
    </ul>
</div>
```

Para agregar un servicio, copia todo el bloque y modifica el contenido.

---

### 💻 Cambiar Tecnologías
**Archivo:** `secciones/tecnologias.html`

```html
<span class="tech-tag">TensorFlow</span>
<span class="tech-tag">Tu Tecnología</span>
```

Puedes agregar, eliminar o modificar las etiquetas.

---

### 📊 Cambiar Estadísticas
**Archivo:** `secciones/estadisticas.html`

```html
<div class="stat-card">
    <i class="fas fa-project-diagram"></i>  <!-- Ícono -->
    <h3 class="stat-number" data-target="50">0</h3>  <!-- Número final -->
    <p>Proyectos Completados</p>  <!-- Descripción -->
</div>
```

**Nota:** `data-target="50"` es el número que se animará desde 0 hasta 50.

---

### 🎯 Modificar Proyectos
**Archivo:** `secciones/proyectos.html`

```html
<div class="project-card">
    <div class="project-image">
        <div class="project-overlay">
            <i class="fas fa-comments"></i>  <!-- Ícono -->
        </div>
    </div>
    <div class="project-content">
        <h3>ChatBot Inteligente</h3>  <!-- Título -->
        <p>Descripción del proyecto...</p>  <!-- Descripción -->
        <div class="project-tags">
            <span>OpenAI</span>  <!-- Tecnologías usadas -->
            <span>Python</span>
            <span>React</span>
        </div>
    </div>
</div>
```

---

## 🎨 Iconos

Los iconos vienen de **Font Awesome**. Para cambiar un ícono:

1. Ve a: https://fontawesome.com/icons
2. Busca el ícono que quieres
3. Copia la clase (ejemplo: `fas fa-rocket`)
4. Reemplaza en el HTML:
   ```html
   <i class="fas fa-rocket"></i>
   ```

**Ejemplos de íconos comunes:**
- `fas fa-brain` - Cerebro (IA)
- `fas fa-code` - Código
- `fas fa-mobile-alt` - Móvil
- `fas fa-cloud` - Nube
- `fas fa-database` - Base de datos
- `fas fa-shield-alt` - Escudo
- `fas fa-rocket` - Cohete
- `fas fa-chart-line` - Gráfico

---

## 🔧 Configuraciones Importantes

### EmailJS (Envío de correos)
**Ver:** `CONFIGURAR_EMAIL.md` para guía completa.

**Archivo:** `script.js` (líneas 140-144)
```javascript
const EMAILJS_CONFIG = {
    serviceID: 'TU_SERVICE_ID',
    templateID: 'TU_TEMPLATE_ID',
    publicKey: 'TU_PUBLIC_KEY'
};
```

---

## 📦 Archivos por Función

### 🎨 Diseño Visual
- `css/styles.css` - Todos los estilos

### 📄 Contenido
- `secciones/navbar.html` - Menú de navegación
- `secciones/hero.html` - Portada/Hero
- `secciones/servicios.html` - Servicios
- `secciones/tecnologias.html` - Stack tecnológico
- `secciones/proyectos.html` - Portafolio
- `secciones/estadisticas.html` - Números/Métricas
- `secciones/contacto.html` - Formulario de contacto
- `secciones/footer.html` - Pie de página

### ⚙️ Funcionalidad
- `js/script.js` - Toda la lógica JavaScript
- `js/loader.js` - Sistema de carga de secciones

### 📘 Documentación
- `README.md` - Documentación general y AWS S3
- `CONFIGURAR_EMAIL.md` - Configurar EmailJS
- `ESTRUCTURA_DEL_PROYECTO.md` - Arquitectura del código
- `GUIA_RAPIDA.md` - Este archivo

---

## 🚀 Workflow de Desarrollo

### 1. Desarrollo Local
```bash
# Opción 1: Doble clic en index.html
# Opción 2: Usar Live Server en tu editor
```

### 2. Hacer Cambios
- Edita los archivos correspondientes
- Guarda cambios
- Recarga el navegador (Ctrl + R o Cmd + R)

### 3. Probar
- Verifica que todo funcione correctamente
- Prueba en diferentes tamaños de pantalla
- Prueba el formulario de contacto

### 4. Subir a AWS S3
```bash
# Ver README.md para instrucciones completas
aws s3 sync . s3://pinohub-website --exclude ".git/*"
```

---

## 🐛 Problemas Comunes

### ❌ Cambié algo y no se ve
**Solución:** Limpia la caché del navegador
- Windows/Linux: `Ctrl + Shift + R`
- Mac: `Cmd + Shift + R`

### ❌ Una sección no aparece
**Solución:** 
1. Abre la consola (F12)
2. Busca errores en rojo
3. Verifica el nombre del archivo en `js/loader.js`

### ❌ El formulario no envía emails
**Solución:** Ver `CONFIGURAR_EMAIL.md` y verificar:
- Service ID
- Template ID
- Public Key

### ❌ Los colores no cambian
**Solución:**
- Verifica que estás editando las variables CSS en `css/styles.css`
- Limpia la caché del navegador
- Usa el inspector (F12) para ver qué estilos se están aplicando

---

## 💡 Tips Pro

### ✨ Backup antes de cambios grandes
Haz una copia de la carpeta completa antes de hacer cambios importantes.

### ✨ Edita un archivo a la vez
Para saber exactamente qué cambio causó qué efecto.

### ✨ Usa comentarios HTML
Marca secciones que modificaste:
```html
<!-- MODIFICADO: Cambié el título aquí -->
<h1>Nuevo Título</h1>
```

### ✨ Prueba en múltiples navegadores
Chrome, Firefox, Safari, Edge.

### ✨ Prueba en móvil
Abre la página en tu teléfono para verificar que se vea bien.

---

## 🎓 Recursos Útiles

- **Font Awesome Icons**: https://fontawesome.com/icons
- **Paletas de Colores**: https://coolors.co
- **HTML Validator**: https://validator.w3.org
- **CSS Validator**: https://jigsaw.w3.org/css-validator/
- **Can I Use** (compatibilidad): https://caniuse.com

---

## ✅ Checklist Pre-Deploy

Antes de subir cambios a AWS S3:

- [ ] Todos los cambios probados localmente
- [ ] Links funcionan correctamente
- [ ] Formulario de contacto funciona
- [ ] Se ve bien en móvil
- [ ] Se ve bien en desktop
- [ ] No hay errores en la consola (F12)
- [ ] Información de contacto actualizada
- [ ] Textos revisados (sin errores de ortografía)

---

¿Necesitas más ayuda? Revisa los otros archivos `.md` en la carpeta del proyecto! 🚀

