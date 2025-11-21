# 🔧 Configurar SHA-1 Diferente por Tipo de Compilación

## 🎯 OBJETIVO

Configurar para que:
- **APK Local** → Use SHA-1 de Upload Key (`F8:F5:86:28:...`)
- **AAB Play Store** → Use SHA-1 de Play Store ASK (`49:7F:A1:F3:...`)

---

## ✅ SOLUCIÓN 1: Múltiples SHA-1 en el Mismo OAuth Client ID (MÁS SIMPLE)

**Esta es la mejor opción si Google Cloud Console lo permite.**

### Cómo hacerlo:

1. **Google Cloud Console:**
   - Ve a OAuth Client ID: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh`
   - En "Huella digital del certificado SHA-1", agrega **AMBOS**:
     - `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4` (Upload Key - para APK local)
     - `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68` (Play Store ASK - para AAB)

2. **Firebase:**
   - Ya tienes ambos configurados ✅

3. **Resultado:**
   - ✅ APK Local: Funciona (con SHA-1 de Upload Key)
   - ✅ AAB Play Store: Funciona (con SHA-1 de Play Store ASK)
   - ✅ Un solo OAuth Client ID para todo

**Problema:** Google Cloud Console puede no permitir múltiples SHA-1 en un solo campo.

---

## ✅ SOLUCIÓN 2: Dos OAuth Client IDs con Build Variants (MÁS COMPLEJO PERO FUNCIONAL)

Si Google Cloud Console NO permite múltiples SHA-1, usa esta solución:

### Paso 1: Configurar Dos OAuth Client IDs en Google Cloud Console

**OAuth Client ID 1 (Para APK Local):**
- Nombre: "CorralX Android App - Local"
- Package Name: `com.corralx.app`
- SHA-1: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
- Client ID: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh` (tu original)

**OAuth Client ID 2 (Para AAB Play Store):**
- Nombre: "CorralX Android App - Play Store"
- Package Name: `com.corralx.app`
- SHA-1: `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68`
- Client ID: `332023551639-840baceq4uf1n93d6rc65svha1o0434o` (el nuevo que creaste)

---

### Paso 2: Crear Dos google-services.json

Necesitas dos archivos `google-services.json`:

**google-services.json.local** (para APK local):
- Con el Client ID: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh`

**google-services.json.release** (para AAB Play Store):
- Con el Client ID: `332023551639-840baceq4uf1n93d6rc65svha1o0434o`

---

### Paso 3: Configurar build.gradle para Usar Diferentes Archivos

Modifica `android/app/build.gradle`:

```gradle
android {
    // ... configuración existente ...

    buildTypes {
        debug {
            // Para APK local (debug y release local)
            signingConfig = signingConfigs.debug
            // Copiar google-services.json local
            copy {
                from 'src/debug/google-services.json'
                into '.'
                rename { 'google-services.json' }
            }
        }
        
        release {
            // Para AAB Play Store
            signingConfig = signingConfigs.release
            // Copiar google-services.json de Play Store
            copy {
                from 'src/release/google-services.json'
                into '.'
                rename { 'google-services.json' }
            }
        }
    }
}
```

---

### Paso 4: Organizar Archivos

Crea la estructura de carpetas:

```
android/app/
├── src/
│   ├── debug/
│   │   └── google-services.json (con Client ID de Upload Key)
│   └── release/
│       └── google-services.json (con Client ID de Play Store ASK)
└── google-services.json (este se sobrescribe según build type)
```

---

### Paso 5: Configurar AndroidManifest Dinámicamente

**Opción A: Usar BuildConfig**

En `android/app/src/main/AndroidManifest.xml`, usa un placeholder que se reemplace en build time:

```xml
<meta-data
    android:name="com.google.android.gms.auth.api.credentials.ClientId"
    android:value="${GOOGLE_OAUTH_CLIENT_ID}"/>
```

En `build.gradle`:

```gradle
android {
    buildTypes {
        debug {
            resValue "string", "google_oauth_client_id", "332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh"
        }
        release {
            resValue "string", "google_oauth_client_id", "332023551639-840baceq4uf1n93d6rc65svha1o0434o"
        }
    }
}
```

**Opción B: Usar Build Flavors**

Crear flavors específicos:

```gradle
android {
    flavorDimensions "environment"
    
    productFlavors {
        local {
            dimension "environment"
            applicationIdSuffix ".local"
            resValue "string", "google_oauth_client_id", "332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh"
        }
        playstore {
            dimension "environment"
            resValue "string", "google_oauth_client_id", "332023551639-840baceq4uf1n93d6rc65svha1o0434o"
        }
    }
}
```

---

## ✅ SOLUCIÓN 3: Usar BuildConfig en Flutter (RECOMENDADO PARA FLUTTER)

### Paso 1: Configurar build.gradle para Definir Constantes

Modifica `android/app/build.gradle`:

```gradle
android {
    // ... configuración existente ...

    buildTypes {
        debug {
            signingConfig = signingConfigs.debug
            buildConfigField "String", "GOOGLE_OAUTH_CLIENT_ID", '"332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh"'
        }
        
        release {
            signingConfig = signingConfigs.release
            buildConfigField "String", "GOOGLE_OAUTH_CLIENT_ID", '"332023551639-840baceq4uf1n93d6rc65svha1o0434o"'
        }
    }
}
```

### Paso 2: Usar MethodChannel para Obtener el Client ID en Flutter

**Crear un MethodChannel en Android:**

`android/app/src/main/kotlin/com/corralx/app/MainActivity.kt` (o MainActivity.java):

```kotlin
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.corralx.app/config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getGoogleOAuthClientId") {
                val clientId = BuildConfig.GOOGLE_OAUTH_CLIENT_ID
                result.success(clientId)
            } else {
                result.notImplemented()
            }
        }
    }
}
```

**En Flutter, obtener el Client ID:**

```dart
import 'package:flutter/services.dart';

class GoogleOAuthConfig {
  static const MethodChannel _channel = MethodChannel('com.corralx.app/config');
  
  static Future<String> getClientId() async {
    try {
      final String clientId = await _channel.invokeMethod('getGoogleOAuthClientId');
      return clientId;
    } catch (e) {
      // Fallback al Client ID por defecto
      return '332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh';
    }
  }
}
```

**Usar en google_sign_in_service.dart:**

```dart
final String clientId = await GoogleOAuthConfig.getClientId();

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['openid', 'profile', 'email'],
  serverClientId: '332023551639-2hpmjjs8j2jn70g7ppdhsfujeosfha7b.apps.googleusercontent.com',
  // El client ID se obtiene dinámicamente desde Android
);
```

---

## ✅ SOLUCIÓN 4: Usar Variables de Entorno (MÁS SIMPLE EN FLUTTER)

### Paso 1: Crear Archivos de Configuración

**lib/config/app_config.dart:**

```dart
class AppConfig {
  static String get googleOAuthClientId {
    // En modo debug: usar Client ID de Upload Key
    // En modo release: usar Client ID de Play Store ASK
    if (kDebugMode) {
      return '332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh'; // Upload Key
    } else {
      return '332023551639-840baceq4uf1n93d6rc65svha1o0434o'; // Play Store ASK
    }
  }
}
```

**Problema:** El `google-services.json` y `AndroidManifest.xml` aún necesitan actualización.

---

## 🎯 RECOMENDACIÓN FINAL

### Para Flutter, la Solución MÁS SIMPLE:

1. **Intenta primero: Múltiples SHA-1 en Google Cloud Console**
   - Si Google Cloud Console permite agregar múltiples SHA-1 al mismo OAuth Client ID
   - Configura AMBOS SHA-1
   - Un solo `google-services.json` y un solo `AndroidManifest.xml`
   - ✅ Funciona para todo sin complicaciones

2. **Si no permite múltiples SHA-1:**
   - Usa **SOLO el SHA-1 de Play Store** (producción es prioridad)
   - Para desarrollo local, usa métodos alternativos o configuraciones adicionales

3. **Si realmente necesitas separarlos:**
   - Usa **Build Flavors** o **Build Variants** (Solución 2 o 3)
   - Es más complejo pero funcional
   - Requiere mantener dos `google-services.json` y configuraciones separadas

---

## 📊 COMPARACIÓN DE SOLUCIONES

| Solución | Complejidad | Funciona APK Local | Funciona AAB Play Store | Mantenimiento |
|----------|-------------|-------------------|------------------------|---------------|
| **Múltiples SHA-1** | ✅ Simple | ✅ Sí | ✅ Sí | ✅ Fácil |
| **Solo Play Store ASK** | ✅ Muy Simple | ⚠️ Puede funcionar | ✅ Sí | ✅ Muy Fácil |
| **Build Variants** | ❌ Complejo | ✅ Sí | ✅ Sí | ⚠️ Medio |
| **MethodChannel** | ⚠️ Medio | ✅ Sí | ✅ Sí | ⚠️ Medio |

---

## 💡 MI RECOMENDACIÓN

**Para empezar rápido:**
1. Prueba si Google Cloud Console permite **múltiples SHA-1** en un solo OAuth Client ID
2. Si SÍ, configura ambos ✅
3. Si NO, usa solo el SHA-1 de Play Store y acepta que desarrollo local puede requerir configuraciones adicionales

**Si realmente necesitas que ambos funcionen perfectamente:**
- Usa **Build Variants** o **Build Flavors**
- Requiere más configuración pero es funcional

---

**¿Quieres que te ayude a implementar alguna de estas soluciones?**


