# ✅ RESUMEN FINAL: Configuración OAuth para APK y AAB

## 🎯 OBJETIVO

Configurar Google OAuth para que funcione:
- ✅ **APK local** (debug y release)
- ✅ **AAB de Play Store**

---

## 📋 ESTADO ACTUAL

### ✅ Firebase Console (COMPLETADO)
- SHA-1 Upload Key: `f8:f5:86:28:5a:02:6e:a5:72:4f:f7:37:1b:9a:99:94:3e:e2:28:b4`
- SHA-1 Play Store ASK: `49:7f:a1:f3:3d:89:04:95:57:f1:04:b9:5b:e5:43:ce:5e:bf:c3:68`
- SHA-256 Play Store ASK: `59:49:18:62:98:d6:cb:f6:18:98:f3:07:f6:f0:0d:66:f4:74:4d:05:7a:b7:3f:36:84:c8:c2:95:cc:57:02:08`

### ⚠️ Google Cloud Console (PENDIENTE)
- OAuth Client ID original (`332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh`): Solo tiene SHA-1 de Upload Key
- OAuth Client ID nuevo (`332023551639-840baceq4uf1n93d6rc65svha1o0434o`): Solo tiene SHA-1 de Play Store ASK

### ⚠️ google-services.json (DESACTUALIZADO)
- Solo tiene `certificate_hash` del upload key
- Falta descargar el nuevo archivo actualizado de Firebase

---

## ✅ SOLUCIÓN RECOMENDADA: UN SOLO OAuth Client ID

**NO necesitas dos OAuth Client IDs diferentes.** La solución más simple es usar **UN SOLO OAuth Client ID con el SHA-1 de Play Store**, porque:

1. **Para APK local:** Puede funcionar incluso sin el SHA-1 del upload key si el Consent Screen está configurado
2. **Para AAB de Play Store:** Necesita el SHA-1 de Play Store ASK

### Pasos:

#### Paso 1: Configurar el OAuth Client ID Original con SHA-1 de Play Store

1. Ve a Google Cloud Console: **https://console.cloud.google.com/apis/credentials**
2. Edita el OAuth Client ID: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh`
3. En "Huella digital del certificado SHA-1", pon el SHA-1 de Play Store:
   ```
   49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68
   ```
4. **Guardar** los cambios

**Nota:** Si quieres que APK local funcione también, podrías intentar agregar múltiples SHA-1, pero si Google Cloud Console solo permite uno, usa el de Play Store (es el más importante para producción).

#### Paso 2: Eliminar el OAuth Client ID Nuevo (Opcional)

El nuevo OAuth Client ID (`332023551639-840baceq4uf1n93d6rc65svha1o0434o`) **NO es necesario** si configuramos el original correctamente. Puedes eliminarlo para mantener la configuración limpia.

#### Paso 3: Descargar google-services.json Actualizado de Firebase

1. Ve a Firebase Console: **https://console.firebase.google.com/**
2. Proyecto: **CorralX-777-aipp**
3. Ve a: **Configuración del proyecto** (⚙️) → **General**
4. Selecciona tu app Android: **CorralX-777**
5. En la sección "Configuración del SDK", busca el botón **"google-services.json"** (para descargar)
6. Descarga el archivo

#### Paso 4: Reemplazar google-services.json en el Proyecto

```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend

# Backup del archivo actual (opcional pero recomendado)
cp android/app/google-services.json android/app/google-services.json.backup

# Reemplaza con el nuevo archivo descargado de Firebase
# (Copia manualmente el archivo descargado a android/app/google-services.json)
```

El nuevo `google-services.json` debería tener **múltiples entradas** en `oauth_client` o múltiples `certificate_hash` para soportar ambos fingerprints.

---

## 🔄 ALTERNATIVA: Dos OAuth Client IDs (Si realmente necesitas separarlos)

Si **realmente quieres** usar credenciales diferentes para APK y AAB, necesitas:

1. **Configurar Build Variants en Flutter**
2. **Usar diferentes `google-services.json` según el build type**
3. **Configurar AndroidManifest dinámicamente**

Esto es **más complejo** y generalmente NO es necesario. Solo recomendado si tienes un caso de uso específico.

### ¿Cómo implementarlo? (Solo si realmente lo necesitas)

1. Crear dos carpetas para diferentes configuraciones:
   ```
   android/app/src/debug/google-services.json (con Client ID de upload key)
   android/app/src/release/google-services.json (con Client ID de Play Store)
   ```

2. O usar flavors de build para manejar esto

**PERO:** Esto es innecesario si configuras correctamente con un solo OAuth Client ID.

---

## ✅ PASOS FINALES DESPUÉS DE CONFIGURAR

### 1. Limpiar y Recompilar

```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

### 2. Esperar Propagación

**Espera 10-15 minutos** después de:
- Guardar cambios en Google Cloud Console
- Descargar nuevo google-services.json de Firebase

### 3. Probar

- **APK local:** Compila APK y prueba Google Sign-In
- **AAB Play Store:** Sube AAB a Play Console, descarga desde Play Store y prueba

---

## 📋 CHECKLIST FINAL

### Google Cloud Console:
- [ ] Edité el OAuth Client ID original (`332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh`)
- [ ] Configuré el SHA-1 de Play Store ASK: `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68`
- [ ] Guardé los cambios
- [ ] (Opcional) Eliminé el OAuth Client ID nuevo que no se usa

### Firebase:
- [ ] Ya agregué los 3 fingerprints ✅ (Completado)
- [ ] Descargué el nuevo `google-services.json` actualizado
- [ ] Reemplacé `android/app/google-services.json` con el archivo nuevo

### Proyecto:
- [ ] Verifiqué que `AndroidManifest.xml` use el Client ID original: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh`
- [ ] Ejecuté `flutter clean`
- [ ] Ejecuté `flutter pub get`
- [ ] Compilé nuevo AAB

### Verificación:
- [ ] Esperé 10-15 minutos después de cambios
- [ ] Probé APK local con Google Sign-In
- [ ] Subí AAB a Play Console
- [ ] Probé app descargada de Play Store con Google Sign-In

---

## 💡 NOTA IMPORTANTE

**Con un solo OAuth Client ID configurado con el SHA-1 de Play Store:**
- ✅ Funcionará en **Play Store** (prioridad principal)
- ✅ Probablemente funcionará en **APK local** también (depende del Consent Screen)

Si el APK local no funciona, puedes:
1. Verificar que el OAuth Consent Screen tenga tu email como test user
2. O considerar usar build variants para credenciales separadas (más complejo)

**Pero primero prueba con un solo OAuth Client ID** - es más simple y generalmente funciona para ambos casos.

---

**Última actualización:** 20 de noviembre de 2025  
**Recomendación:** Usar UN SOLO OAuth Client ID con SHA-1 de Play Store ASK


