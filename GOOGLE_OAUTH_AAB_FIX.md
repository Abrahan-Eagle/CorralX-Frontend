# Solución: Google OAuth no funciona en AAB de producción

## 🔍 Diagnóstico del Problema

Cuando compilas un **APK** funciona, pero el **AAB** para Play Store no funciona con Google OAuth. Esto se debe a que:

1. **SHA-256 no está configurado** en Google Cloud Console (crítico para Play Store)
2. **OAuth Consent Screen** puede estar en modo "Testing"
3. Las credenciales de producción requieren configuración adicional

## 📋 Información del Keystore de Producción

### Keystore: `android/app/mykey.jks`
### Alias: `androiddebugkey`
### Package Name: `com.corralx.app`

### Fingerprints del Keystore:
```
SHA-1: F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4
SHA-256: 10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20
```

### OAuth Client ID (Android):
```
332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com
```

---

## ✅ SOLUCIÓN PASO A PASO

### Paso 1: Verificar y Agregar SHA-256 en Google Cloud Console

1. **Accede a Google Cloud Console:**
   - Ve a: https://console.cloud.google.com/
   - Selecciona el proyecto: **corralx-777-aipp**

2. **Ir a Credenciales:**
   - Navega a: **APIs & Services** → **Credentials**
   - Busca el OAuth Client ID: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com`
   - Haz clic en el nombre del OAuth Client ID para editarlo

3. **Verificar SHA-1:**
   - Debe estar configurado: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
   - Si NO está, agrégala

4. **Agregar SHA-256 (CRÍTICO):**
   - Busca el campo **"SHA-256 certificate fingerprint"**
   - Si NO está configurado, haz clic en **"+ Add fingerprint"** o edita el campo
   - Agrega: `10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20`
   - Haz clic en **"SAVE"**

### Paso 2: Verificar OAuth Consent Screen

1. **Ir a OAuth Consent Screen:**
   - Navega a: **APIs & Services** → **OAuth consent screen**

2. **Verificar el modo:**
   - Si está en modo **"Testing"**:
     - Opción A: Agregar tu email como **test user** (si solo quieres probar)
     - Opción B: **Publicar la app** para producción (requerido para Play Store)
   
3. **Para publicar la app (RECOMENDADO para Play Store):**
   - Completa TODOS los campos requeridos:
     - ✅ App name: CorralX
     - ✅ User support email: Tu email
     - ✅ Developer contact information: Tu email
     - ✅ Scopes: `openid`, `profile`, `email`
   - Agrega una **Privacy Policy URL** (requerido para publicación)
   - Agrega **Terms of Service URL** (opcional pero recomendado)
   - Haz clic en **"PUBLISH APP"**
   - Espera la aprobación de Google (puede tomar 1-7 días)

### Paso 3: Verificar Package Name

1. **En OAuth Client ID (Android):**
   - Verifica que el **Package name** sea exactamente: `com.corralx.app`
   - Sin espacios, sin mayúsculas (todo minúsculas)
   - Debe coincidir EXACTAMENTE con el package name del AndroidManifest.xml

2. **Verificar en AndroidManifest.xml:**
   ```xml
   <manifest package="com.corralx.app">
   ```
   - Debe coincidir exactamente

### Paso 4: Verificar que el AAB esté firmado correctamente

1. **Verificar firma del AAB:**
   ```bash
   cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
   jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
   ```

2. **Si hay errores de firma:**
   - Verifica que `key.properties` esté configurado correctamente
   - Verifica que el keystore exista y tenga la contraseña correcta

---

## 🔧 Verificación Rápida

### Checklist antes de subir a Play Store:

- [ ] SHA-1 configurado en Google Cloud Console
- [ ] SHA-256 configurado en Google Cloud Console (CRÍTICO)
- [ ] Package name coincide exactamente (`com.corralx.app`)
- [ ] OAuth Consent Screen publicado (o en Testing con tu email agregado)
- [ ] Privacy Policy URL configurada (requerido para publicación)
- [ ] AAB compilado y firmado correctamente

---

## 🧪 Cómo Probar Localmente el AAB

Si quieres probar el AAB antes de subirlo a Play Store:

1. **Convertir AAB a APK para instalación local:**
   ```bash
   # Instalar bundletool (si no lo tienes)
   # Descargar: https://github.com/google/bundletool/releases
   
   # Generar APK universal desde AAB
   bundletool build-apks \
     --bundle=build/app/outputs/bundle/release/app-release.aab \
     --output=app-release.apks \
     --ks=android/app/mykey.jks \
     --ks-pass=pass:'#$AIpp/19217553/' \
     --ks-key-alias=androiddebugkey \
     --key-pass=pass:'#$AIpp/19217553/'
   
   # Instalar APK
   bundletool install-apks --apks=app-release.apks
   ```

2. **O instalar directamente el APK release:**
   ```bash
   flutter build apk --release
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 📞 Si el Problema Persiste

Si después de seguir estos pasos el problema persiste:

1. **Revisar logs de Google OAuth:**
   - Busca errores en Logcat: `adb logcat | grep -i "oauth\|google\|sign"`
   - Verifica mensajes de error específicos

2. **Verificar en Google Cloud Console:**
   - Ve a **APIs & Services** → **Credentials** → Tu OAuth Client ID
   - Revisa si hay alertas o errores mostrados
   - Verifica que las APIs necesarias estén habilitadas:
     - ✅ Google Sign-In API
     - ✅ Google People API

3. **Contactar soporte:**
   - Si el OAuth Consent Screen está en revisión y pasaron más de 7 días
   - Si hay errores específicos de Google Cloud Console

---

## 📝 Notas Importantes

1. **SHA-256 es MÁS importante que SHA-1 para Play Store:**
   - Google Play requiere SHA-256 para verificar la firma de la app
   - Asegúrate de agregarlo siempre

2. **OAuth Consent Screen en modo Testing:**
   - Solo funciona para usuarios agregados como "test users"
   - Para producción, debe estar publicado

3. **Tiempo de propagación:**
   - Los cambios en Google Cloud Console pueden tardar 5-15 minutos en propagarse
   - Espera unos minutos después de hacer cambios antes de probar

---

**Última actualización:** 20 de noviembre de 2025

