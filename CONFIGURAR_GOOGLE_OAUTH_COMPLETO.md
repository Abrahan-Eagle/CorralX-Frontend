# 🔧 Configuración Completa de Google OAuth - SHA-1 y SHA-256

Esta guía te mostrará cómo configurar **AMBOS** SHA-1 y SHA-256 en Google Cloud Console para que Google Sign-In funcione en:
- ✅ **APK Debug**
- ✅ **APK Release** 
- ✅ **AAB Release**
- ✅ **Play Store**

---

## 📋 Información del Keystore (Ya verificado)

### Keystore de Producción: `android/app/mykey.jks`
- **Alias:** `androiddebugkey`
- **Package Name:** `com.corralx.app`

### Fingerprints (Del mismo keystore):
```
SHA-1:   F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4
SHA-256: 10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20
```

### OAuth Client ID (Android) que necesitas editar:
```
332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com
```

---

## 🚀 PASOS PARA CONFIGURAR EN GOOGLE CLOUD CONSOLE

### Paso 1: Acceder a Google Cloud Console

1. Ve a: **https://console.cloud.google.com/**
2. **Asegúrate de estar en el proyecto correcto:**
   - Si no estás seguro, busca en la parte superior donde dice el nombre del proyecto
   - Proyecto esperado: **corralx-777-aipp** (o tu proyecto de CorralX)
3. Si necesitas cambiar de proyecto, haz clic en el selector de proyecto en la parte superior

---

### Paso 2: Ir a Credenciales OAuth

1. En el menú lateral izquierdo, busca y haz clic en:
   ```
   APIs & Services → Credentials
   ```
   O ve directamente a:
   **https://console.cloud.google.com/apis/credentials**

2. Verás una lista de credenciales. Busca una que diga:
   - **Application type:** Android
   - **Client ID:** `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com`
   - **Name:** Puede ser "CorralX Android App" o similar

---

### Paso 3: Editar el OAuth Client ID

1. **Haz clic en el nombre** del OAuth Client ID (el que dice Android)

2. Se abrirá una página de edición con varios campos:
   - **Name** (nombre del cliente)
   - **Package name**
   - **SHA certificate fingerprints**

---

### Paso 4: Verificar y Agregar Package Name

1. En el campo **"Package name"**, verifica que diga exactamente:
   ```
   com.corralx.app
   ```
   - Todo en **minúsculas**
   - Sin espacios
   - Sin caracteres especiales adicionales

2. Si está diferente, **corrígelo** y debe ser exactamente como arriba.

---

### Paso 5: Agregar SHA-1 Fingerprint

1. Busca la sección **"SHA certificate fingerprints"**

2. Verás una lista (puede estar vacía o tener valores previos)

3. **Para agregar SHA-1:**
   - Si ya existe, verifica que sea: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
   - Si NO existe o es diferente, haz clic en **"ADD FINGERPRINT"** o el botón **"+"** o **"ADD"**
   - Pega este SHA-1:
     ```
     F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4
     ```
   - **Formato:** Debe incluir los dos puntos (:) entre cada par de caracteres
   - **Sin espacios** antes o después

---

### Paso 6: Agregar SHA-256 Fingerprint

1. En la misma sección **"SHA certificate fingerprints"**

2. **Haz clic nuevamente en "ADD FINGERPRINT"** (o "+" o "ADD")

3. Pega este SHA-256:
   ```
   10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20
   ```
   - **Formato:** Debe incluir los dos puntos (:) entre cada par de caracteres
   - **Sin espacios** antes o después

4. Ahora deberías ver **AMBOS** fingerprints en la lista:
   - ✅ SHA-1: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
   - ✅ SHA-256: `10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20`

---

### Paso 7: Guardar los Cambios

1. **Haz clic en el botón "SAVE"** (o "GUARDAR") en la parte inferior de la página

2. Verás un mensaje de confirmación como:
   ```
   ✅ Credentials saved successfully
   ```
   o en español:
   ```
   ✅ Credenciales guardadas exitosamente
   ```

---

### Paso 8: Esperar la Propagación

1. **Es importante:** Los cambios en Google Cloud Console pueden tardar **5-15 minutos** en propagarse completamente.

2. **NO pruebes inmediatamente** después de guardar.

3. Espera al menos **10 minutos** antes de:
   - Compilar un nuevo AAB
   - Probar Google Sign-In
   - Subir a Play Store

---

## ✅ VERIFICACIÓN FINAL

Después de configurar, deberías ver en la página del OAuth Client ID:

```
Name: CorralX Android App (o el nombre que tengas)
Application type: Android
Package name: com.corralx.app
SHA certificate fingerprints:
  • F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4
  • 10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20
```

---

## 🧪 CÓMO PROBAR QUE FUNCIONA

### 1. Compilar un nuevo AAB (Opcional)
```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

### 2. Probar Google Sign-In en la app

1. **Espera 10-15 minutos** después de guardar en Google Cloud Console
2. Abre la app en tu dispositivo
3. Haz clic en **"Continuar con Google"**
4. Deberías ver el selector de cuentas de Google
5. Selecciona una cuenta
6. Deberías poder iniciar sesión sin problemas

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### Si sigue sin funcionar después de 15 minutos:

1. **Verifica que ambos fingerprints estén configurados:**
   - Vuelve a Google Cloud Console
   - Edita el OAuth Client ID
   - Verifica que veas AMBOS SHA-1 y SHA-256

2. **Verifica el formato:**
   - Los fingerprints deben tener **dos puntos (:) entre cada par de caracteres**
   - Ejemplo correcto: `F8:F5:86:28:...`
   - Ejemplo incorrecto: `F8 F5 86 28...` o `F8F58628...`

3. **Verifica el Package Name:**
   - Debe ser exactamente: `com.corralx.app`
   - Todo en minúsculas
   - Sin espacios

4. **Verifica el OAuth Consent Screen:**
   - Ve a: **APIs & Services** → **OAuth consent screen**
   - Si está en modo **"Testing"**, agrega tu email como test user
   - O publícalo para producción

5. **Revisa los logs:**
   ```bash
   adb logcat | grep -i "oauth\|google\|sign"
   ```
   Busca errores relacionados con OAuth

---

## 📝 NOTAS IMPORTANTES

### ✅ ¿Por qué ambos?
- **SHA-1:** Compatibilidad con versiones antiguas y herramientas que aún lo usan
- **SHA-256:** Requerido por Play Store y apps modernas

### ✅ ¿Funciona para todo?
Sí, con ambos configurados funcionará para:
- ✅ APK Debug (local)
- ✅ APK Release (local)
- ✅ AAB Release (Play Store)
- ✅ Play Store interno testing
- ✅ Play Store producción

### ✅ Un solo keystore para todo
Como tu `build.gradle` está configurado para usar el mismo keystore (`mykey.jks`) para debug y release, solo necesitas configurar estos dos fingerprints UNA VEZ y funcionará para todo.

---

**Última actualización:** 20 de noviembre de 2025  
**Estado:** ✅ Verificado con keystore de producción

