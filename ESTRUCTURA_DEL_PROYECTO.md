# 📁 Estructura del Proyecto PinoHub

Este documento explica la organización modular del código para facilitar el mantenimiento y desarrollo.

## 📂 Estructura de Carpetas

```
pinohub/
│
├── index.html                    # Archivo principal (solo contenedores)
│
├── css/                          # Estilos CSS
│   └── styles.css               # Estilos CSS completos
│
├── js/                           # Scripts JavaScript
│   ├── loader.js                # Sistema de carga de secciones
│   └── script.js                # Lógica JavaScript principal
│
├── secciones/                    # Componentes HTML modulares
│   ├── navbar.html              # Barra de navegación
│   ├── hero.html                # Sección hero/principal
│   ├── servicios.html           # Servicios ofrecidos
│   ├── tecnologias.html         # Stack tecnológico
│   ├── proyectos.html           # Portafolio de proyectos
│   ├── estadisticas.html        # Métricas y estadísticas
│   ├── contacto.html            # Formulario de contacto
│   └── footer.html              # Pie de página
│
├── README.md                     # Documentación general y AWS S3
├── CONFIGURAR_EMAIL.md          # Guía de configuración EmailJS
├── GUIA_RAPIDA.md               # Referencia rápida de edición
└── ESTRUCTURA_DEL_PROYECTO.md   # Este archivo
```

---

## 🎯 Ventajas de esta Estructura

### ✅ Modularidad
- Cada sección está en su propio archivo
- Fácil de encontrar y editar código específico
- Sin necesidad de buscar en archivos enormes

### ✅ Mantenibilidad
- Cambios en una sección no afectan a las demás
- Código más limpio y organizado
- Fácil para trabajar en equipo

### ✅ Reutilización
- Las secciones pueden reutilizarse en otras páginas
- Puedes duplicar y modificar secciones fácilmente

### ✅ Escalabilidad
- Agregar nuevas secciones es simple
- Solo crear el archivo HTML y registrarlo en el loader

---

## 🔧 Cómo Funciona

### 1. index.html (Contenedores)
El archivo principal solo contiene "contenedores" vacíos:

```html
<div id="navbar-container"></div>
<div id="hero-container"></div>
<div id="servicios-container"></div>
<!-- ... más contenedores -->
```

### 2. js/loader.js (Cargador)
El loader carga dinámicamente cada sección:

```javascript
// Configuración de secciones
sections: [
    { id: 'navbar-container', file: 'navbar.html' },
    { id: 'hero-container', file: 'hero.html' },
    // ...
]
```

### 3. secciones/*.html (Componentes)
Cada archivo contiene el HTML de una sección específica.

### 4. js/script.js (Funcionalidad)
Espera a que todas las secciones se carguen y luego inicializa la funcionalidad.

---

## 📝 Cómo Editar una Sección

### Ejemplo: Cambiar el título del Hero

1. Abre el archivo: `secciones/hero.html`
2. Busca la línea con el título:
   ```html
   <h1 class="hero-title">Transformamos Ideas en <span class="highlight">Soluciones Inteligentes</span></h1>
   ```
3. Modifica el texto como desees
4. Guarda el archivo
5. Recarga la página en el navegador

**¡Eso es todo!** No necesitas tocar ningún otro archivo.

---

## ➕ Cómo Agregar una Nueva Sección

### Paso 1: Crear el archivo HTML
Crea un nuevo archivo en la carpeta `secciones/`, por ejemplo:
```
secciones/testimonios.html
```

### Paso 2: Agregar contenido HTML
```html
<section class="testimonials" id="testimonios">
    <div class="container">
        <h2>Testimonios</h2>
        <!-- Tu contenido aquí -->
    </div>
</section>
```

### Paso 3: Agregar un contenedor en index.html
```html
<div id="testimonios-container"></div>
```

### Paso 4: Registrar en el loader
Edita `js/loader.js` y agrega tu sección:
```javascript
sections: [
    // ... secciones existentes
    { id: 'testimonios-container', file: 'testimonios.html' }
]
```

### Paso 5: Agregar estilos (opcional)
Edita `css/styles.css` y agrega estilos para `.testimonials`

**¡Listo!** Tu nueva sección se cargará automáticamente.

---

## 🗑️ Cómo Eliminar una Sección

### Paso 1: Eliminar el contenedor
En `index.html`, elimina:
```html
<div id="nombre-seccion-container"></div>
```

### Paso 2: Eliminar del loader
En `js/loader.js`, elimina la línea correspondiente:
```javascript
{ id: 'nombre-seccion-container', file: 'nombre-seccion.html' }
```

### Paso 3: Eliminar el archivo (opcional)
Puedes eliminar el archivo `secciones/nombre-seccion.html` si no lo necesitas.

---

## 🎨 Cómo Personalizar Estilos

### Estilos Globales (Colores, Fuentes)
Edita `css/styles.css` en las variables CSS al inicio:

```css
:root {
    --color-primary: #1a1f1a;
    --color-secondary: #4a5a3f;
    --color-accent: #9db56c;
    /* ... */
}
```

### Estilos de una Sección Específica
Busca en `css/styles.css` la sección correspondiente:

```css
/* =================================
   Services Section
   ================================= */
.services {
    padding: 6rem 0;
    /* ... tus cambios aquí ... */
}
```

---

## 🔄 Flujo de Carga

```
1. index.html se carga
   ↓
2. loader.js se ejecuta
   ↓
3. loader.js carga todas las secciones desde secciones/*.html
   ↓
4. Cuando todas las secciones están cargadas, dispara evento 'sectionsLoaded'
   ↓
5. script.js escucha ese evento e inicializa toda la funcionalidad
   ↓
6. La página está completamente funcional
```

---

## ⚙️ Funciones Principales en js/script.js

Todas las funciones están organizadas y se inicializan desde `initializeApp()`:

```javascript
function initializeApp() {
    initNavigation();          // Menú hamburguesa
    initScrollEffects();       // Efectos de scroll
    initAnimations();          // Animaciones y contadores
    initContactForm();         // Formulario de contacto
    initNewsletterForm();      // Newsletter
    initScrollToTop();         // Botón scroll-to-top
    initActiveNavigation();    // Link activo en nav
    initParallax();            // Efecto parallax
    initServiceCards();        // Hover en tarjetas
    updateFooterYear();        // Año dinámico
    logWelcomeMessage();       // Mensaje de consola
}
```

### Para modificar una funcionalidad específica:
Busca la función correspondiente y edítala. Ejemplo:

```javascript
// ¿Quieres cambiar la velocidad del parallax?
function initParallax() {
    window.addEventListener('scroll', () => {
        const scrolled = window.scrollY;
        const hero = document.querySelector('.hero-content');
        if (hero) {
            hero.style.transform = `translateY(${scrolled * 0.5}px)`; // Cambia 0.3 a 0.5
        }
    });
}
```

---

## 🚀 Mejores Prácticas

### ✅ DO (Hacer)
- Mantén cada sección en su propio archivo
- Usa nombres descriptivos para archivos y IDs
- Comenta cambios importantes en el código
- Prueba cambios localmente antes de subir a S3

### ❌ DON'T (No hacer)
- No mezcles contenido de diferentes secciones en un archivo
- No elimines contenedores sin actualizar el loader
- No olvides actualizar el loader al agregar nuevas secciones
- No modifiques el loader.js a menos que sepas lo que haces

---

## 🐛 Solución de Problemas

### Problema: Una sección no se carga
**Solución**:
1. Abre la consola del navegador (F12)
2. Busca errores en rojo
3. Verifica que el nombre del archivo y el ID del contenedor coincidan en loader.js
4. Verifica que el archivo exista en la carpeta `secciones/`

### Problema: JavaScript no funciona después de editar
**Solución**:
1. Verifica que no hayas roto la estructura HTML (etiquetas sin cerrar)
2. Limpia la caché del navegador (Ctrl + Shift + R)
3. Revisa la consola por errores

### Problema: Los estilos no se aplican
**Solución**:
1. Verifica que las clases CSS existan en css/styles.css
2. Limpia la caché del navegador
3. Verifica que no haya errores de sintaxis en el CSS

---

## 📞 Soporte

Para más información sobre:
- **Despliegue en AWS S3**: Ver `README.md`
- **Configurar emails**: Ver `CONFIGURAR_EMAIL.md`
- **Esta estructura**: Estás leyendo el archivo correcto 😉

---

## 🎓 Conceptos Importantes

### Carga Asíncrona
Las secciones se cargan en paralelo usando `fetch()` y `Promise.all()`, lo que hace que la página cargue rápido.

### Event Listeners Condicionales
Todas las funciones verifican si el elemento existe antes de agregar event listeners (`if (!element) return`).

### Single Page Application (SPA) Lite
Esta estructura simula un SPA básico sin frameworks pesados como React o Vue.

---

¿Tienes preguntas? ¡Consulta los otros archivos de documentación o revisa el código con los comentarios! 🚀

