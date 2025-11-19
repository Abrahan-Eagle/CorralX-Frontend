# 📋 Checklist: Qué Falta para Subir a Play Store

**Fecha:** $(date)  
**Estado Actual:** ✅ Técnicamente lista, faltan pasos administrativos

---

## ✅ LO QUE YA ESTÁ LISTO (No necesitas hacer nada)

1. ✅ **Keystore configurado** - `mykey.jks` existe y está configurado
2. ✅ **SHA-1 único** - Configurado para debug y release
3. ✅ **Seguridad** - `usesCleartextTraffic` removido
4. ✅ **SDK Versions** - minSdkVersion 21, targetSdk 36
5. ✅ **Versiones** - Sincronizadas (3.0.16+36)
6. ✅ **ProGuard** - Configurado
7. ✅ **Firebase** - google-services.json presente
8. ✅ **Permisos** - Todos declarados correctamente
9. ✅ **Iconos y Splash** - Configurados

---

## 🔴 CRÍTICO - Debes hacer esto ANTES de subir

### 1. ⚠️ **Verificar SHA-1 en Google Cloud Console** (5 minutos)

**Acción:**
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona el proyecto: **corralx-777-aipp**
3. Ve a **APIs & Services** → **Credentials**
4. Busca y abre el OAuth Client ID: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com`
5. Verifica que solo tenga este SHA-1:
   ```
   F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4
   ```
6. Si hay otro SHA-1 (el de debug: `F6:89:C6:99:4D:EA:C0:0B:7C:E3:CA:F1:B1:07:6E:B9:F6:08:89:2C`), **ELIMÍNALO**

**Por qué es crítico:** Si hay SHA-1 incorrectos, Google Sign-In no funcionará en la app publicada.

---

## 🟡 IMPORTANTE - Requerido por Play Store

### 2. ⚠️ **Política de Privacidad** (30-60 minutos)

**Acción:**
1. Crear una política de privacidad que mencione:
   - Qué datos recopilas (nombre, email, ubicación, fotos, etc.)
   - Cómo usas los datos
   - Con quién compartes los datos
   - Cómo los usuarios pueden eliminar sus datos
2. Publicarla en una URL accesible (puede ser en tu sitio web o usar un servicio como [Privacy Policy Generator](https://www.privacypolicygenerator.info/))
3. Agregar la URL en Play Console cuando subas la app

**Por qué es requerido:** Play Store exige política de privacidad para apps que recopilan datos personales (tu app recopila: nombre, email, ubicación, fotos).

---

### 3. ⚠️ **Contenido de la Tienda** (1-2 horas)

**Acción:**
1. **Screenshots** (mínimo 2, recomendado 4-8):
   - Teléfono: 2-8 screenshots (1080x1920px o mayor)
   - Tablet (opcional): 2-8 screenshots (1200x1920px o mayor)
   - Captura las pantallas principales: Marketplace, Detalle de producto, Chat, Perfil

2. **Descripción de la app** (mínimo 80 caracteres):
   - Descripción completa de qué hace la app
   - Características principales
   - Beneficios para el usuario

3. **Descripción corta** (máximo 80 caracteres):
   - Resumen breve de la app

4. **Categoría:**
   - Seleccionar categoría apropiada (probablemente "Negocios" o "Productividad")

5. **Clasificación de contenido:**
   - Completar cuestionario de clasificación de contenido

**Por qué es requerido:** Play Store necesita esta información para mostrar tu app en la tienda.

---

## 🟢 RECOMENDADO - Antes de publicar

### 4. ⚠️ **Probar Build de Release** (30 minutos)

**Acción:**
1. Compilar build de release:
   ```bash
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```
2. Probar en dispositivo físico:
   - Instalar el AAB generado
   - Probar funcionalidades principales:
     - Login con Google
     - Navegación
     - Marketplace
     - Chat
     - Perfil
   - Verificar que no haya crashes

**Por qué es recomendado:** Asegura que la app funcione correctamente en producción.

---

### 5. ⚠️ **App Bundle (AAB) en lugar de APK** (Ya configurado)

**Acción:**
- Usar: `flutter build appbundle --release`
- El archivo estará en: `build/app/outputs/bundle/release/app-release.aab`

**Por qué es recomendado:** AAB es el formato preferido por Play Store, reduce el tamaño de descarga.

---

## 📝 RESUMEN: Qué hacer AHORA

### Prioridad 1 (Hacer HOY):
1. ✅ Verificar SHA-1 en Google Cloud Console (5 min)
2. ⚠️ Crear política de privacidad (30-60 min)

### Prioridad 2 (Hacer antes de subir):
3. ⚠️ Preparar screenshots (30-60 min)
4. ⚠️ Escribir descripciones (15-30 min)
5. ⚠️ Probar build de release (30 min)

### Prioridad 3 (Opcional):
6. ⚠️ Completar clasificación de contenido (10 min)
7. ⚠️ Agregar gráficos promocionales (opcional)

---

## 🚀 PASOS PARA SUBIR A PLAY STORE

Una vez completado lo anterior:

1. **Crear cuenta de desarrollador** (si no la tienes):
   - Ir a [Google Play Console](https://play.google.com/console)
   - Pagar tarifa única de $25 USD

2. **Crear nueva app:**
   - Nombre: CorralX
   - Idioma predeterminado: Español
   - Tipo de app: Aplicación
   - Gratis o de pago: Gratis

3. **Completar información de la tienda:**
   - Agregar screenshots
   - Agregar descripciones
   - Agregar política de privacidad
   - Seleccionar categoría
   - Completar clasificación de contenido

4. **Subir AAB:**
   - Ir a "Producción" → "Crear nueva versión"
   - Subir `app-release.aab`
   - Agregar notas de la versión

5. **Revisar y publicar:**
   - Revisar toda la información
   - Enviar para revisión

---

## ⏱️ TIEMPO ESTIMADO TOTAL

- **Mínimo necesario:** 1-2 horas
- **Recomendado completo:** 2-3 horas

---

## ✅ CHECKLIST FINAL

Antes de hacer clic en "Publicar":

- [ ] SHA-1 verificado en Google Cloud Console
- [ ] Política de privacidad creada y publicada
- [ ] Screenshots preparados (mínimo 2)
- [ ] Descripción de la app escrita
- [ ] Descripción corta escrita
- [ ] Categoría seleccionada
- [ ] Clasificación de contenido completada
- [ ] Build de release probado en dispositivo físico
- [ ] AAB generado (`app-release.aab`)
- [ ] Cuenta de desarrollador creada ($25 USD pagados)

---

**Última actualización:** $(date)

