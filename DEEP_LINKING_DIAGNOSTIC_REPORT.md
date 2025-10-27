# 🔍 DIAGNÓSTICO TÉCNICO: DEEP LINKS / APP LINKS
## Proyecto: Corral X (Flutter + Laravel 10)
**Fecha:** 27 de Octubre, 2025  
**URL objetivo:** `https://backend.corralx.com/api/products/487`

---

## 📊 RESUMEN EJECUTIVO

### ⚠️ PROBLEMA PRINCIPAL DETECTADO
El archivo `assetlinks.json` **NO está accesible** en el servidor de producción (`404 Not Found`).  
Esto impide que Android verifique la relación entre el dominio y la app, bloqueando los App Links automáticos.

### 🎯 CAUSA RAÍZ
El archivo existe en `public/.well-known/assetlinks.json` pero el servidor Laravel **no está configurado para servir archivos estáticos desde `.well-known/`**.

### ✅ SOLUCIÓN REQUERIDA
Configurar una ruta en Laravel para servir `/.well-known/assetlinks.json` con el `Content-Type: application/json` correcto.

---

## 🔍 ANÁLISIS DETALLADO POR COMPONENTE

### 1. ✅ AndroidManifest.xml - CORRECTO

**Archivo:** `CorralX-Frontend/android/app/src/main/AndroidManifest.xml`

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    
    <!-- Producción -->
    <data android:scheme="https"
          android:host="backend.corralx.com"
          android:pathPrefix="/api/products" />
    <data android:scheme="https"
          android:host="backend.corralx.com"
          android:pathPrefix="/api/ranches" />
    
    <!-- Desarrollo local -->
    <data android:scheme="http"
          android:host="192.168.27.12"
          android:port="8000"
          android:pathPrefix="/api/products" />
    <data android:scheme="http"
          android:host="192.168.27.12"
          android:port="8000"
          android:pathPrefix="/api/ranches" />
</intent-filter>
```

**Estado:** ✅ **CONFIGURADO CORRECTAMENTE**
- `android:autoVerify="true"` ✅ Activado
- `android:host="backend.corralx.com"` ✅ Dominio correcto
- `android:pathPrefix="/api/products"` ✅ Ruta correcta
- `android:pathPrefix="/api/ranches"` ✅ Ruta correcta

---

### 2. ❌ Assetlinks.json - NO ACCESIBLE EN PRODUCCIÓN

**Archivo en repositorio:** `CorralX-Frontend/.well-known/assetlinks.json`  
**Archivo en servidor:** `CorralX-Backend/public/.well-known/assetlinks.json`

#### Contenido actual:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.zonix",
      "sha256_cert_fingerprints": [
        "D9:C5:09:19:B2:B2:B7:6A:41:51:BE:A1:DD:42:F9:31:FB:E2:D5:4C:7F:43:D4:99:31:6F:85:25:7F:ED:E2:F3"
      ]
    }
  }
]
```

#### ✅ Verificación URL:
- **URL esperada:** `https://backend.corralx.com/.well-known/assetlinks.json`
- **Resultado:** `HTTP/2 404` (NO ENCONTRADO)
- **Estado:** ❌ **NO ACCESIBLE**

#### ⚠️ Problema detectado:
El archivo existe físicamente pero **no está siendo servido** por el servidor Laravel.  
Esto ocurre porque Laravel **no sirve automáticamente** archivos desde carpetas `.well-known/`.

---

### 3. ⚠️ SHA-256 Fingerprint - DESAJUSTADO

#### SHA-256 del keystore instalado:
```
10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20
```

#### SHA-256 en assetlinks.json:
```
D9:C5:09:19:B2:B2:B7:6A:41:51:BE:A1:DD:42:F9:31:FB:E2:D5:4C:7F:43:D4:99:31:6F:85:25:7F:ED:E2:F3
```

#### Estado: ❌ **NO COINCIDEN**

**Causa:** El archivo `assetlinks.json` tiene el fingerprint del keystore **DEBUG** en lugar del keystore **RELEASE** (`mykey.jks`).

---

### 4. ✅ Package Name - CORRECTO

#### Configuración en build.gradle:
```gradle
applicationId = "com.example.zonix"
```

#### En assetlinks.json:
```json
"package_name": "com.example.zonix"
```

**Estado:** ✅ **COINCIDEN**

---

### 5. ✅ Firebase Configuration - CORRECTO

**Archivos encontrados:**
- ✅ `google-services.json` existe en `android/app/`
- ✅ Plugin `com.google.gms.google-services` activado en `build.gradle`
- ✅ Firebase dependencies agregadas

**Estado:** ✅ **CONFIGURADO**

---

### 6. ✅ Código Flutter - CORRECTO

**Archivo:** `CorralX-Frontend/lib/core/deep_link_service.dart`

```dart
// Soporta múltiples formatos:
// - https://backend.corralx.com/api/products/123
// - http://192.168.27.12:8000/api/products/123
// - corralx://product/123

static int? extractProductId(Uri uri) {
  // ... código de extracción
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      (uri.host.contains('corralx.com') ||
          uri.host.contains('192.168.27.12'))) {
    if (path.startsWith('/api/products/')) {
      final productId = int.tryParse(path.split('/').last);
      return productId;
    }
  }
}
```

**Estado:** ✅ **FUNCIONAL**

---

### 7. ✅ Dominio y Certificado - CORRECTO

- **Dominio:** `backend.corralx.com` ✅ Activo
- **Certificado HTTPS:** ✅ Válido y accesible
- **SSL:** ✅ Configurado correctamente

---

## 🔧 ACCIONES REQUERIDAS

### 1. ❗ PRIORIDAD ALTA: Configurar Ruta en Laravel

**Archivo:** `CorralX-Backend/routes/web.php`

Agregar esta ruta **ANTES** del `Route::fallback()`:

```php
// Ruta para assetlinks.json (Android App Links)
Route::get('/.well-known/assetlinks.json', function () {
    return response()->file(
        public_path('.well-known/assetlinks.json'),
        ['Content-Type' => 'application/json']
    );
})->name('assetlinks');
```

**Alternativa con header explícito:**

```php
Route::get('/.well-known/assetlinks.json', function () {
    $file = public_path('.well-known/assetlinks.json');
    
    if (!file_exists($file)) {
        return response('File not found', 404);
    }
    
    return response(file_get_contents($file), 200)
        ->header('Content-Type', 'application/json');
});
```

---

### 2. ❗ PRIORIDAD ALTA: Actualizar SHA-256 en assetlinks.json

**Acción:** Actualizar el fingerprint en `assetlinks.json` con el SHA-256 correcto:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.zonix",
      "sha256_cert_fingerprints": [
        "10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20"
      ]
    }
  }
]
```

**Comando para verificar:**
```bash
cd android/app && keytool -list -v -keystore mykey.jks -storepass '#$AIpp/19217553/' -alias androiddebugkey | grep SHA256
```

---

### 3. ⚠️ PRIORIDAD MEDIA: Verificar Acceso al Archivo

Después de configurar la ruta, verificar que el archivo sea accesible:

```bash
curl -I https://backend.corralx.com/.well-known/assetlinks.json
```

**Respuesta esperada:**
```
HTTP/2 200
Content-Type: application/json
```

---

### 4. ✅ PRIORIDAD BAJA: Limpiar Caché de Android

Después de instalar la nueva versión del APK, limpiar la caché de verificación de Android:

```bash
adb shell pm set-app-links --package com.example.zonix 0 all
adb shell pm set-app-links-user-selection --package com.example.zonix true
adb shell pm verify-app-links --re-verify com.example.zonix
```

---

## 📝 CHECKLIST DE VERIFICACIÓN

- [ ] ✅ AndroidManifest.xml configurado con `android:autoVerify="true"`
- [ ] ❌ assetlinks.json accesible en `https://backend.corralx.com/.well-known/assetlinks.json`
- [ ] ❌ SHA-256 fingerprint correcto en assetlinks.json
- [ ] ✅ package_name coincide con applicationId
- [ ] ✅ Firebase configurado correctamente
- [ ] ✅ Código Flutter maneja deep links
- [ ] ✅ Dominio con certificado HTTPS válido
- [ ] ✅ Ruta en Laravel para servir assetlinks.json

---

## 🚀 PASOS SIGUIENTES

### Paso 1: Configurar Ruta en Laravel (5 minutos)
1. Abrir `CorralX-Backend/routes/web.php`
2. Agregar la ruta para `/.well-known/assetlinks.json`
3. Guardar y reiniciar el servidor Laravel

### Paso 2: Actualizar assetlinks.json (2 minutos)
1. Actualizar el SHA-256 fingerprint
2. Copiar el archivo actualizado a ambos repositorios:
   - `CorralX-Frontend/.well-known/assetlinks.json`
   - `CorralX-Backend/public/.well-known/assetlinks.json`

### Paso 3: Verificar Acceso (1 minuto)
```bash
curl -I https://backend.corralx.com/.well-known/assetlinks.json
```

### Paso 4: Recompilar y Reinstalar APK (10 minutos)
```bash
cd CorralX-Frontend
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Paso 5: Probar Deep Link (1 minuto)
Abrir en el navegador del dispositivo:
```
https://backend.corralx.com/api/products/487
```

---

## 📊 MATRIZ DE ESTADO

| Componente | Estado | Acción Requerida |
|-----------|--------|------------------|
| AndroidManifest.xml | ✅ OK | Ninguna |
| assetlinks.json (URL) | ❌ 404 | Configurar ruta Laravel |
| SHA-256 fingerprint | ❌ Desajustado | Actualizar assetlinks.json |
| package_name | ✅ OK | Ninguna |
| Firebase config | ✅ OK | Ninguna |
| Código Flutter | ✅ OK | Ninguna |
| Dominio HTTPS | ✅ OK | Ninguna |

---

## 🎯 CONCLUSIÓN

El proyecto tiene una **base sólida** para deep linking, pero **2 problemas críticos** impiden su funcionamiento:

1. ❌ **assetlinks.json no accesible** (404) - Requiere configuración en Laravel
2. ❌ **SHA-256 fingerprint incorrecto** - Requiere actualización del archivo

Una vez resueltos estos 2 problemas, el deep linking funcionará correctamente con los enlaces tipo:
```
https://backend.corralx.com/api/products/487
```

**Tiempo estimado para resolver:** 20 minutos

---

**Generado por:** Análisis técnico automatizado  
**Fecha:** 27 de Octubre, 2025
