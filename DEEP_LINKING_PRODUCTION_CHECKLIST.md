# Deep Linking - Checklist de Producción

## ✅ COMPLETADO (Desarrollo)

1. ✅ `AndroidManifest.xml` configurado con intent filters
2. ✅ `DeepLinkService` implementado
3. ✅ SHA-256 fingerprint agregado al `assetlinks.json`
4. ✅ Archivo `assetlinks.json` copiado al backend
5. ✅ Archivo accesible desde `http://192.168.27.12:8000/.well-known/assetlinks.json`

## ⚠️ PENDIENTE PARA PRODUCCIÓN

### 1. Keystore de Producción ⚠️ **CRÍTICO**

El SHA-256 actual es del keystore de **DEBUG**. Necesitas obtener el SHA-256 del keystore de **PRODUCCIÓN**.

**Pasos:**
```bash
# 1. Obtener SHA-256 del keystore de producción
keytool -list -v -keystore android/app/key.jks -alias <tu-alias>

# 2. Buscar la línea que dice "SHA256:" y copiar el valor

# 3. Actualizar .well-known/assetlinks.json con el SHA-256 de producción
# Debe incluir AMBOS (debug y producción):
```

**Ejemplo de assetlinks.json con ambos fingerprints:**
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.zonix",
      "sha256_cert_fingerprints": [
        "D9:C5:09:19:B2:B2:B7:6A:41:51:BE:A1:DD:42:F9:31:FB:E2:D5:4C:7F:43:D4:99:31:6F:85:25:7F:ED:E2:F3",
        "TU_SHA256_DE_PRODUCCION_AQUI"
      ]
    }
  }
]
```

---

### 2. Subir assetlinks.json al Servidor de Producción ⚠️ **CRÍTICO**

El archivo debe estar accesible en:
```
https://backend.corralx.com/.well-known/assetlinks.json
```

**Pasos:**
```bash
# 1. Subir el archivo al servidor
scp .well-known/assetlinks.json usuario@backend.corralx.com:/ruta/del/backend/public/.well-known/

# O usar FTP, rsync, etc.
```

**Verificar:**
```bash
curl https://backend.corralx.com/.well-known/assetlinks.json
```

**Importante:** El archivo debe ser servido con:
- Content-Type: `application/json`
- HTTPS (no HTTP)
- Sin redirecciones

---

### 3. Configuración del Servidor ⚠️ **IMPORTANTE**

#### A. Nginx/Apache debe servir archivos `.well-known/`

**Nginx:**
```nginx
location /.well-known/ {
    allow all;
    try_files $uri $uri/ =404;
}
```

**Apache:**
```apache
<Directory "/path/to/public/.well-known">
    Options -Indexes
    AllowOverride None
    Require all granted
</Directory>
```

#### B. Headers correctos
```nginx
location /.well-known/assetlinks.json {
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
}
```

---

### 4. Verificar que el DNS apunte correctamente ⚠️

```bash
# Verificar que backend.corralx.com apunta al servidor correcto
dig backend.corralx.com

# Debe devolver la IP de tu servidor
```

---

### 5. Compilar APP con Keystore de Producción ⚠️ **CRÍTICO**

```bash
# En tu proyecto Flutter
flutter build apk --release

# Asegúrate de que el keystore está configurado en:
# android/app/build.gradle

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

### 6. Verificación de App Links ⚠️

**Herramienta de Google:**
```
https://developers.google.com/digital-asset-links/tools/generator
```

**Comando ADB (desde Android Debug Bridge):**
```bash
adb shell pm get-app-links --user cur com.example.zonix

# Debe mostrar "domain verified" para backend.corralx.com
```

---

## 📋 RESUMEN DE TAREAS

### Para hacer ANTES de publicar en Play Store:

1. ⚠️ **Crear/obtener keystore de producción**
2. ⚠️ **Obtener SHA-256 del keystore de producción**
3. ⚠️ **Actualizar assetlinks.json con SHA-256 de producción**
4. ⚠️ **Subir assetlinks.json a https://backend.corralx.com/.well-known/**
5. ⚠️ **Verificar que el archivo es accesible públicamente**
6. ⚠️ **Configurar el servidor para servir archivos .well-known/**
7. ⚠️ **Compilar la app con keystore de producción**
8. ⚠️ **Verificar App Links con la herramienta de Google**
9. ⚠️ **Probar el deep linking en un dispositivo real**

---

## 🔗 URLs Importantes

- **Developers Console:** https://developers.google.com/digital-asset-links/tools/generator
- **Verificador:** https://developers.google.com/digital-asset-links/tools/generator
- **Documentación:** https://developer.android.com/training/app-links

---

## ⚡ NOTA IMPORTANTE

El SHA-256 de **DEBUG** funciona para **DESARROLLO** pero **NO** para **PRODUCCIÓN**.

Cuando subas la app a Google Play Store, **DEBES** usar el keystore de producción y actualizar el `assetlinks.json` con el SHA-256 correcto.
