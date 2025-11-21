# 🔧 Solución: OAuth no funciona en AAB (Sin necesidad de SHA-256)

## ✅ Lo que YA tienes configurado correctamente:
- ✅ **SHA-1:** `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
- ✅ **Package Name:** `com.corralx.app`
- ✅ **OAuth Client ID:** `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com`

## ❓ Si no aparece SHA-256:
**Puede ser normal** - Google Cloud Console puede estar manejando SHA-256 automáticamente basándose en tu SHA-1, o puede que tu versión de la consola solo muestre SHA-1.

---

## 🔍 EL PROBLEMA MÁS PROBABLE: OAuth Consent Screen

Cuando el OAuth funciona en **APK** pero **NO en AAB**, el problema **99% de las veces** es el **OAuth Consent Screen** en modo "Testing".

### ¿Por qué pasa esto?
- **APK local/debug:** Puede funcionar aunque esté en "Testing"
- **AAB para Play Store:** Requiere que el Consent Screen esté **PUBLICADO** o que el usuario esté agregado como **test user**

---

## ✅ SOLUCIÓN: Verificar OAuth Consent Screen

### Paso 1: Ir a OAuth Consent Screen

1. En Google Cloud Console, ve a:
   ```
   APIs & Services → OAuth consent screen
   ```
   O directamente: https://console.cloud.google.com/apis/credentials/consent

2. **Verás el estado actual** de tu Consent Screen

---

### Paso 2: Verificar el Modo

Verás uno de estos estados:

#### 🟡 Opción A: Está en modo "Testing"

**Síntomas:**
- Dice: **"Publishing status: Testing"**
- Hay un mensaje como: "This app is in testing mode. Only test users can sign in."

**Solución INMEDIATA (Para probar rápido):**
1. En la misma página, busca la sección **"Test users"**
2. Haz clic en **"+ ADD USERS"** o **"Agregar usuarios"**
3. Agrega **tu email** (el que usas para probar Google Sign-In)
4. Haz clic en **"ADD"** o **"Guardar"**
5. **Espera 5-10 minutos**
6. Prueba el AAB nuevamente

**Solución DEFINITIVA (Para Play Store):**
1. En la página de OAuth Consent Screen, desplázate hacia abajo
2. Busca el botón **"PUBLISH APP"** o **"Publicar app"**
3. Antes de publicar, verifica que tengas configurado:
   - ✅ **App name:** CorralX
   - ✅ **User support email:** Tu email
   - ✅ **Developer contact information:** Tu email
   - ✅ **Privacy Policy URL:** (OBLIGATORIO para publicar)
   - ✅ **Scopes:** `openid`, `profile`, `email`

4. Si falta algo, complétalo primero
5. Luego haz clic en **"PUBLISH APP"**
6. Google puede tardar **1-7 días** en aprobar, pero a veces se publica inmediatamente

---

#### 🟢 Opción B: Ya está publicado

Si dice **"Publishing status: In production"** o **"En producción"**:
- El Consent Screen está bien
- El problema puede ser otro (ver sección de diagnóstico adicional)

---

## 🧪 CÓMO PROBAR DESPUÉS DE CONFIGURAR

### 1. Espera la propagación
- Si agregaste test users: **Espera 5-10 minutos**
- Si publicaste la app: **Puede tardar hasta 1 día** (pero generalmente es rápido)

### 2. Compila un nuevo AAB
```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

### 3. Prueba el AAB
- Sube el AAB a Play Store (internal testing)
- O convierte AAB a APK e instálalo localmente
- Prueba Google Sign-In

---

## 🔍 DIAGNÓSTICO ADICIONAL (Si sigue sin funcionar)

### 1. Verificar que el AAB esté firmado correctamente

```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

**Si hay errores**, puede ser que el keystore no se esté usando correctamente.

---

### 2. Verificar logs cuando falla

Cuando pruebes Google Sign-In en el AAB y falle:

```bash
adb logcat | grep -i "oauth\|google\|sign\|error"
```

**Busca mensajes como:**
- `10: signin error: 12500` → Problema con OAuth Client ID
- `10: signin error: 12501` → Usuario canceló (no es error)
- `10: DEVELOPER_ERROR` → Problema con SHA-1/SHA-256 o Consent Screen
- `API key not valid` → Problema con configuración

---

### 3. Verificar APIs habilitadas

En Google Cloud Console:
1. Ve a **APIs & Services** → **Enabled APIs**
2. Verifica que estas APIs estén habilitadas:
   - ✅ **Google Sign-In API** (si existe como API separada)
   - ✅ **Google People API** (muy importante)
   - ✅ **Identity Toolkit API** (opcional pero recomendado)

---

### 4. Verificar que el Client ID esté correcto en AndroidManifest.xml

El AndroidManifest.xml debe tener:
```xml
<meta-data
    android:name="com.google.android.gms.auth.api.credentials.ClientId"
    android:value="332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com"/>
```

✅ Ya lo tienes configurado correctamente.

---

## 📝 RESUMEN: Orden de Prioridad

1. **PRIMERO:** Verifica y corrige el **OAuth Consent Screen** (90% de probabilidad de ser esto)
   - Si está en "Testing", agrega test users o publícalo

2. **SEGUNDO:** Espera 10-15 minutos después de hacer cambios

3. **TERCERO:** Compila un nuevo AAB y prueba

4. **CUARTO:** Si sigue fallando, revisa los logs con `adb logcat`

---

## ✅ Checklist Final

- [ ] SHA-1 configurado en Google Cloud Console
- [ ] Package Name correcto (`com.corralx.app`)
- [ ] OAuth Consent Screen verificado:
  - [ ] Si está en "Testing": Agregaste tu email como test user
  - [ ] O está publicado para producción
- [ ] Privacy Policy URL configurada (si está publicado)
- [ ] Esperaste 10-15 minutos después de cambios
- [ ] Compilaste un nuevo AAB después de los cambios
- [ ] Probaste Google Sign-In en el AAB

---

**¿Qué estado muestra tu OAuth Consent Screen?**
- ¿"Testing" o "En producción"?
- ¿Hay un botón "PUBLISH APP" visible?
- ¿Hay una sección de "Test users"?

Comparte esa información y te guío exactamente qué hacer.

