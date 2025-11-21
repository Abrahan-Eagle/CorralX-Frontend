# 🎯 Paso a Paso: Agregar Fingerprints de Play Store

## ✅ RESUMEN DE LO QUE VAMOS A HACER

1. **Firebase Console:** Agregar SHA-1 y SHA-256 de Play Store ASK
2. **Google Cloud Console:** Agregar SHA-1 de Play Store ASK
3. **Actualizar proyecto:** Reemplazar `google-services.json` con el nuevo archivo

---

## 🔥 FASE 1: Firebase Console (ESTÁS AQUÍ AHORA)

### Valores a Agregar:

**SHA-1 de Play Store ASK:**
```
49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68
```

**SHA-256 de Play Store ASK:**
```
59:49:18:62:98:D6:CB:F6:18:98:F3:07:F6:F0:0D:66:F4:74:4D:05:7A:B7:3F:36:84:C8:C2:95:CC:57:02:08
```

### Pasos en Firebase:

1. ✅ Haz clic en **"Agregar huella digital"** (botón que ves en la imagen)
2. ✅ Pega el **SHA-1 de Play Store ASK** arriba
3. ✅ Haz clic en **"Agregar"** o **"Save"**
4. ✅ Haz clic nuevamente en **"Agregar huella digital"**
5. ✅ Pega el **SHA-256 de Play Store ASK** arriba
6. ✅ Haz clic en **"Agregar"** o **"Save"**

### Después de Agregar:

7. ✅ **Descarga el nuevo `google-services.json`**
   - Busca el botón **"Descargar google-services.json"** en la misma página
   - O ve al final de la sección "SDK configuration" donde debe estar el enlace
   - Descarga el archivo

8. ✅ **Guarda el archivo descargado** (lo reemplazaremos después)

---

## ☁️ FASE 2: Google Cloud Console

### Paso 1: Acceder

1. Ve a: **https://console.cloud.google.com/apis/credentials**
2. Asegúrate de estar en el proyecto: **corralx-777-aipp**

### Paso 2: Editar OAuth Client ID

1. Busca el OAuth Client ID de Android:
   ```
   332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com
   ```

2. Haz clic en el **nombre** para editarlo

### Paso 3: Agregar SHA-1 de Play Store

1. En el campo **"Huella digital del certificado SHA-1"**:
   - **NO elimines** el SHA-1 existente: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
   - Busca un botón **"+"**, **"ADD"**, **"Agregar"** o similar para agregar más fingerprints
   - Haz clic en ese botón
   - Pega este SHA-1:
     ```
     49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68
     ```

2. **Ahora deberías tener DOS SHA-1:**
   - Tu Upload Key: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
   - Play Store ASK: `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68`

### Paso 4: Agregar SHA-256 (Si está disponible)

1. Si Google Cloud Console permite agregar SHA-256:
   - Agrega también: `59:49:18:62:98:D6:CB:F6:18:98:F3:07:F6:F0:0D:66:F4:74:4D:05:7A:B7:3F:36:84:C8:C2:95:CC:57:02:08`

### Paso 5: Guardar

1. Haz clic en **"SAVE"** o **"Guardar"** al final de la página

---

## 📁 FASE 3: Actualizar Proyecto Local

### Paso 1: Hacer Backup del Archivo Actual (Opcional pero Recomendado)

```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
cp android/app/google-services.json android/app/google-services.json.backup
```

### Paso 2: Reemplazar google-services.json

1. **Ubicación del archivo actual:**
   ```
   CorralX-Frontend/android/app/google-services.json
   ```

2. **Reemplaza el archivo:**
   - Toma el `google-services.json` que descargaste de Firebase
   - Copia y reemplaza el archivo en: `android/app/google-services.json`
   - **Asegúrate de reemplazar completamente el archivo anterior**

### Paso 3: Verificar el Nuevo Archivo

El nuevo `google-services.json` debería tener:
- Múltiples `certificate_hash` en el array (uno para cada fingerprint agregado)
- O múltiples entradas en la sección `oauth_client` para Android

---

## ✅ FASE 4: Verificación y Pruebas

### Paso 1: Limpiar y Recompilar

```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

### Paso 2: Esperar Propagación

**Espera 10-15 minutos** después de:
- Guardar cambios en Firebase Console
- Guardar cambios en Google Cloud Console

Los cambios tardan en propagarse.

### Paso 3: Probar

1. Sube el nuevo AAB a Play Console
2. Descarga la app desde Play Store (no instales APK local)
3. Prueba Google Sign-In

---

## 📋 CHECKLIST FINAL

### Firebase Console:
- [ ] Agregué SHA-1 de Play Store ASK: `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68`
- [ ] Agregué SHA-256 de Play Store ASK: `59:49:18:62:98:D6:CB:F6:18:98:F3:07:F6:F0:0D:66:F4:74:4D:05:7A:B7:3F:36:84:C8:C2:95:CC:57:02:08`
- [ ] Descargué el nuevo `google-services.json`

### Google Cloud Console:
- [ ] Agregué SHA-1 de Play Store ASK al OAuth Client ID (sin eliminar el existente)
- [ ] Verifiqué que Package Name sigue siendo `com.corralx.app`
- [ ] Guardé los cambios

### Proyecto Local:
- [ ] Reemplacé `android/app/google-services.json` con el archivo nuevo de Firebase
- [ ] Ejecuté `flutter clean`
- [ ] Ejecuté `flutter pub get`
- [ ] Compilé nuevo AAB

### Verificación:
- [ ] Esperé 10-15 minutos después de cambios
- [ ] Subí nuevo AAB a Play Console
- [ ] Probé Google Sign-In en app descargada de Play Store

---

## 🆘 Si Algo Sale Mal

### Si no encuentras dónde agregar múltiples SHA-1 en Google Cloud Console:
- Algunas versiones solo permiten uno
- **Solución:** El SHA-1 de Play Store es el más importante, puedes reemplazar temporalmente solo con ese, pero es mejor tener ambos

### Si el nuevo google-services.json no tiene los cambios:
- Verifica que hayas guardado en Firebase antes de descargar
- Espera unos minutos y descarga nuevamente

### Si después de todo sigue sin funcionar:
- Verifica que hayas esperado 15 minutos después de los cambios
- Revisa los logs con: `adb logcat | grep -i "oauth\|google\|sign"`

---

**Última actualización:** 20 de noviembre de 2025  
**Estado:** Listo para configurar


