# 📧 Configuración de EmailJS para el Formulario de Contacto

Esta guía te ayudará a configurar EmailJS para que tu formulario envíe correos automáticamente a **cefernal.dev@gmail.com**

## 🎯 ¿Qué es EmailJS?

EmailJS es un servicio gratuito que permite enviar emails desde JavaScript sin necesidad de un servidor backend. Perfecto para páginas estáticas en S3.

**Plan Gratuito**: 200 emails/mes (más que suficiente para comenzar)

---

## 📝 Pasos para Configurar EmailJS

### Paso 1: Crear Cuenta en EmailJS

1. Ve a: **https://www.emailjs.com/**
2. Clic en **"Sign Up"** (Registrarse)
3. Puedes registrarte con:
   - Email y contraseña
   - Google Account (recomendado, usa cefernal.dev@gmail.com)
   - GitHub
4. Confirma tu email si es necesario

---

### Paso 2: Conectar tu Email (Gmail)

1. Una vez dentro, ve a **"Email Services"** en el menú lateral
2. Clic en **"Add New Service"**
3. Selecciona **"Gmail"**
4. Aparecerá un formulario:
   - **Service ID**: Se genera automáticamente (ejemplo: `service_abc123`)
   - Clic en **"Connect Account"**
   - Selecciona tu cuenta de Gmail: **cefernal.dev@gmail.com**
   - Autoriza los permisos que solicita EmailJS
5. Clic en **"Create Service"**

**⚠️ IMPORTANTE**: Copia y guarda el **Service ID** que aparece (lo necesitarás en el Paso 4)

Ejemplo de Service ID: `service_xyz1234`

---

### Paso 3: Crear una Plantilla de Email

1. Ve a **"Email Templates"** en el menú lateral
2. Clic en **"Create New Template"**
3. Verás un editor. Configura así:

#### Configuración de la Plantilla:

**Template Name**: `pinohub_contact_form`

**Subject (Asunto del email)**:
```
Nuevo mensaje de contacto - {{subject}}
```

**Content (Contenido del email)**:
```
Nuevo mensaje desde el formulario de contacto de PinoHub:

Nombre: {{from_name}}
Email: {{from_email}}
Asunto: {{subject}}

Mensaje:
{{message}}

---
Este email fue enviado automáticamente desde pinohub.com
```

**To Email**: `cefernal.dev@gmail.com`

**From Name**: `PinoHub Website`

**From Email**: `{{from_email}}` (o deja el predeterminado)

**Reply To**: `{{from_email}}`

4. Clic en **"Save"** (Guardar)

**⚠️ IMPORTANTE**: Copia y guarda el **Template ID** que aparece (ejemplo: `template_xyz1234`)

---

### Paso 4: Obtener tu Public Key

1. Ve a **"Account"** (ícono de usuario en la esquina superior derecha)
2. Selecciona **"General"** o **"API Keys"**
3. Verás tu **Public Key** (también llamado User ID)
4. Cópialo (ejemplo: `AbCd123EfGh456`)

---

### Paso 5: Actualizar el Código

Ahora abre el archivo **`js/script.js`** y reemplaza estas líneas (están al inicio del archivo, después de las animaciones):

```javascript
const EMAILJS_CONFIG = {
    serviceID: 'TU_SERVICE_ID',      // Reemplazar con tu Service ID
    templateID: 'TU_TEMPLATE_ID',    // Reemplazar con tu Template ID
    publicKey: 'TU_PUBLIC_KEY'       // Reemplazar con tu Public Key
};
```

**Reemplaza con tus valores reales**, ejemplo:

```javascript
const EMAILJS_CONFIG = {
    serviceID: 'service_xyz1234',      // Tu Service ID de Gmail
    templateID: 'template_abc5678',    // Tu Template ID
    publicKey: 'AbCd123EfGh456'        // Tu Public Key
};
```

---

### Paso 6: Probar el Formulario

1. Abre tu página web (localmente o en S3)
2. Ve a la sección de **Contacto**
3. Llena el formulario con datos de prueba:
   - Nombre: Test Usuario
   - Email: test@example.com
   - Asunto: Prueba de formulario
   - Mensaje: Este es un mensaje de prueba
4. Clic en **"Enviar Mensaje"**

5. Si todo está bien configurado:
   - ✅ Verás un mensaje de éxito
   - ✅ Recibirás un email en **cefernal.dev@gmail.com**
   - ✅ El email contendrá todos los datos del formulario

---

## 🐛 Solución de Problemas

### Error: "Invalid 'service_id'"
- **Problema**: El Service ID no es correcto
- **Solución**: Verifica en EmailJS > Email Services > Tu servicio de Gmail > copia el Service ID exacto

### Error: "Invalid 'template_id'"
- **Problema**: El Template ID no es correcto
- **Solución**: Verifica en EmailJS > Email Templates > Tu plantilla > copia el Template ID exacto

### Error: "Invalid 'public_key'" o "Invalid 'user_id'"
- **Problema**: La Public Key no es correcta
- **Solución**: Ve a Account > General/API Keys > copia tu Public Key

### No llega el email
- Revisa la carpeta de **SPAM** en Gmail
- Verifica que el email destino en la plantilla sea correcto: `cefernal.dev@gmail.com`
- Ve a EmailJS > Email History para ver si el email se envió

### Botón de "Enviando..." se queda cargando
- Abre la consola del navegador (F12)
- Busca errores en rojo
- Verifica que las 3 configuraciones (serviceID, templateID, publicKey) sean correctas

---

## 🔒 Seguridad

**¿Es seguro exponer la Public Key?**

Sí, la Public Key de EmailJS está diseñada para usarse en el frontend (código público). EmailJS protege contra:
- Spam y abusos
- Límites de rate limiting
- Validación de dominio (opcional)

**Recomendación adicional**: En EmailJS, puedes configurar:
1. **Allowed domains**: Solo permitir emails desde tu dominio
2. **Rate limiting**: Limitar cantidad de emails por hora/día
3. **CAPTCHA**: Agregar verificación anti-spam (opcional)

Estas configuraciones están en: Account > Security

---

## 📊 Monitoreo

Para ver los emails enviados:
1. Ve a **"Email History"** en EmailJS
2. Verás un listado de todos los emails:
   - Estado (enviado, fallido)
   - Fecha y hora
   - Destinatario
   - Detalles completos

---

## 💰 Límites del Plan Gratuito

- ✅ 200 emails por mes
- ✅ 1 servicio de email (Gmail en tu caso)
- ✅ 2 plantillas de email
- ✅ Email History básico
- ✅ Soporte comunitario

Si necesitas más, puedes actualizar a un plan pago ($10-15/mes aprox).

---

## 🎨 Personalización Adicional (Opcional)

### Agregar auto-respuesta al usuario

Puedes crear una segunda plantilla para enviar un email de confirmación automático al usuario que llenó el formulario.

1. Crea otra plantilla en EmailJS
2. Configura:
   - **To Email**: `{{from_email}}` (el email del usuario)
   - **Subject**: "Gracias por contactar a PinoHub"
   - **Content**: Mensaje de agradecimiento
3. En `js/script.js`, agrega otro `emailjs.send()` para enviar esta segunda plantilla

---

## 📞 Soporte

- **Documentación EmailJS**: https://www.emailjs.com/docs/
- **FAQ EmailJS**: https://www.emailjs.com/docs/faq/
- **Video Tutorial**: https://www.youtube.com/results?search_query=emailjs+tutorial

---

## ✅ Checklist Final

- [ ] Cuenta creada en EmailJS
- [ ] Servicio de Gmail conectado (Service ID copiado)
- [ ] Plantilla de email creada (Template ID copiado)
- [ ] Public Key obtenida
- [ ] Los 3 valores actualizados en `script.js`
- [ ] Formulario probado localmente
- [ ] Email recibido en cefernal.dev@gmail.com
- [ ] Archivos subidos a S3 (si aplica)

---

**¡Listo!** Tu formulario ahora enviará emails reales a **cefernal.dev@gmail.com** 🎉

