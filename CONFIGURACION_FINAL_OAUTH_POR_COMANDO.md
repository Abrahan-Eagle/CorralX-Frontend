# ✅ Configuración Final: OAuth Client ID por Comando de Compilación

## 🎯 CONFIGURACIÓN COMPLETADA

### ✅ Lo que se configuró:

El sistema detecta automáticamente qué tipo de compilación estás haciendo y usa el OAuth Client ID correcto:

| Comando | Tipo | OAuth Client ID | SHA-1 Configurado | Estado |
|---------|------|-----------------|-------------------|--------|
| `flutter run -d 192.168.27.4:5555` | Debug APK | `332023551639-bbhv...` (Upload Key) | `F8:F5:86:28:...` | ✅ Configurado |
| `flutter run -d 192.168.27.4:5555 --release` | Release APK Local | `332023551639-bbhv...` (Upload Key) | `F8:F5:86:28:...` | ✅ Configurado |
| `flutter build appbundle --release` | AAB Play Store | `332023551639-840b...` (Play Store ASK) | `49:7F:A1:F3:...` | ✅ Configurado |

---

## 🔍 CÓMO FUNCIONA

### Detección Automática en build.gradle:

El `build.gradle` detecta automáticamente si estás compilando:
- **APK** (assembleRelease) → Usa Client ID de Upload Key
- **AAB** (bundleRelease) → Usa Client ID de Play Store ASK

**Código implementado:**
```gradle
release {
    // Detecta si se está compilando AAB (bundle) o APK (assemble)
    def isBuildingBundle = gradle.startParameter.taskNames.any { it.contains('bundle') }
    
    if (isBuildingBundle) {
        // AAB Play Store → Play Store ASK Client ID
    } else {
        // APK Release Local → Upload Key Client ID
    }
}
```

---

## ✅ PRÓXIMOS PASOS

### 1. Descargar google-services.json Actualizado de Firebase

**CRÍTICO:** Necesitas descargar un nuevo `google-services.json` de Firebase:

1. Ve a Firebase Console: **https://console.firebase.google.com/**
2. Proyecto: **CorralX-777-aipp**
3. Ve a: **Configuración del proyecto** (⚙️) → **General**
4. Selecciona tu app Android: **CorralX-777**
5. En "Configuración del SDK", busca el botón **"google-services.json"** (para descargar)
6. Descarga el archivo
7. Reemplaza el archivo en: `android/app/google-services.json`

**Nota:** Firebase ya tiene los 3 fingerprints configurados ✅ (Upload Key SHA-1, Play Store ASK SHA-1 y SHA-256), así que el nuevo `google-services.json` debería incluir ambos OAuth Client IDs.

---

### 2. Limpiar y Probar

```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
flutter clean
flutter pub get
```

**Probar cada comando:**

#### Probar Debug APK:
```bash
flutter run -d 192.168.27.4:5555
```
- Debe usar Client ID: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh`
- Prueba Google Sign-In ✅

#### Probar Release APK Local:
```bash
flutter run -d 192.168.27.4:5555 --release
```
- Debe usar Client ID: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh`
- Prueba Google Sign-In ✅

#### Probar AAB Play Store:
```bash
flutter build appbundle --release
```
- Debe usar Client ID: `332023551639-840baceq4uf1n93d6rc65svha1o0434o`
- Sube a Play Console y prueba desde Play Store ✅

---

## 📋 VERIFICACIÓN

### Para verificar qué Client ID se está usando:

Durante la compilación, puedes ver en los logs de Gradle qué manifestPlaceholders se aplicaron. O puedes agregar un log temporal en `build.gradle`:

```gradle
release {
    def isBuildingBundle = gradle.startParameter.taskNames.any { it.contains('bundle') }
    
    if (isBuildingBundle) {
        println "🔵 Compilando AAB - Usando Client ID de Play Store ASK"
        manifestPlaceholders = [
            googleOauthClientId: "332023551639-840baceq4uf1n93d6rc65svha1o0434o.apps.googleusercontent.com"
        ]
    } else {
        println "🟢 Compilando APK - Usando Client ID de Upload Key"
        manifestPlaceholders = [
            googleOauthClientId: "332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com"
        ]
    }
}
```

---

## ✅ CHECKLIST FINAL

### Google Cloud Console:
- [x] OAuth Client ID 1 (Upload Key): `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh` ✅
- [x] OAuth Client ID 2 (Play Store ASK): `332023551639-840baceq4uf1n93d6rc65svha1o0434o` ✅

### Firebase Console:
- [x] SHA-1 Upload Key agregado ✅
- [x] SHA-1 Play Store ASK agregado ✅
- [x] SHA-256 Play Store ASK agregado ✅
- [ ] Descargar nuevo google-services.json (PENDIENTE)

### Proyecto Local:
- [x] AndroidManifest.xml configurado con placeholder dinámico ✅
- [x] build.gradle configurado con detección automática bundle/APK ✅
- [ ] Reemplazar google-services.json con el nuevo de Firebase (PENDIENTE)

### Pruebas:
- [ ] Probar `flutter run -d 192.168.27.4:5555` (Debug APK)
- [ ] Probar `flutter run -d 192.168.27.4:5555 --release` (Release APK Local)
- [ ] Compilar `flutter build appbundle --release` (AAB Play Store)
- [ ] Subir AAB a Play Console y probar desde Play Store

---

## 📝 RESUMEN

**Configuración automática implementada:**
- ✅ **Debug APK** → Upload Key Client ID
- ✅ **Release APK Local** → Upload Key Client ID
- ✅ **AAB Play Store** → Play Store ASK Client ID

**El sistema detecta automáticamente** qué tipo de compilación estás haciendo y usa el Client ID correcto.

**Falta solo:**
- ⏳ Descargar nuevo `google-services.json` de Firebase
- ⏳ Reemplazarlo en el proyecto
- ⏳ Probar los 3 comandos

---

**Última actualización:** 20 de noviembre de 2025  
**Estado:** ✅ Configuración completada - Falta actualizar google-services.json y probar


