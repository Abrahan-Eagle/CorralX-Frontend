# ✅ Configuración de OAuth Client IDs por Build Type - COMPLETADA

## 🎯 CONFIGURACIÓN IMPLEMENTADA

### ✅ Lo que se configuró:

1. **AndroidManifest.xml:**
   - Configurado para usar un placeholder dinámico: `${googleOauthClientId}`
   - Se reemplaza automáticamente según el build type

2. **build.gradle:**
   - **Debug Build:** Usa Client ID de Upload Key (para APK local)
   - **Release Build:** Usa Client ID de Play Store ASK (para AAB Play Store)

---

## 📋 CONFIGURACIÓN ACTUAL

### Build Debug (APK Local):
- **OAuth Client ID:** `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com`
- **SHA-1:** `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4` (Upload Key)
- **Uso:** APK local (debug y release local)

### Build Release (AAB Play Store):
- **OAuth Client ID:** `332023551639-840baceq4uf1n93d6rc65svha1o0434o.apps.googleusercontent.com`
- **SHA-1:** `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68` (Play Store ASK)
- **Uso:** AAB para Play Store

---

## ✅ PRÓXIMOS PASOS

### 1. Descargar google-services.json Actualizado de Firebase

**Importante:** Necesitas descargar un nuevo `google-services.json` de Firebase que incluya ambos OAuth Client IDs:

1. Ve a Firebase Console: **https://console.firebase.google.com/**
2. Proyecto: **CorralX-777-aipp**
3. Ve a: **Configuración del proyecto** (⚙️) → **General**
4. Selecciona tu app Android: **CorralX-777**
5. En "Configuración del SDK", descarga **google-services.json**
6. Reemplaza el archivo en: `android/app/google-services.json`

**Nota:** Firebase ya tiene los 3 fingerprints configurados ✅, así que el nuevo `google-services.json` debería incluir ambos Client IDs.

---

### 2. Limpiar y Recompilar

```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

**Para probar APK local:**
```bash
flutter build apk --release
```

---

### 3. Verificar que Funciona

#### Probar APK Local (Debug):
1. Compila APK: `flutter build apk --release`
2. Instala en tu dispositivo
3. Prueba Google Sign-In
4. Debe usar el Client ID de Upload Key ✅

#### Probar AAB Play Store (Release):
1. Compila AAB: `flutter build appbundle --release`
2. Sube a Play Console (Internal testing)
3. Descarga desde Play Store
4. Prueba Google Sign-In
5. Debe usar el Client ID de Play Store ASK ✅

---

## ✅ CHECKLIST FINAL

### Google Cloud Console:
- [x] OAuth Client ID 1 configurado con SHA-1 de Upload Key ✅
- [x] OAuth Client ID 2 configurado con SHA-1 de Play Store ASK ✅

### Firebase Console:
- [x] SHA-1 Upload Key agregado ✅
- [x] SHA-1 Play Store ASK agregado ✅
- [x] SHA-256 Play Store ASK agregado ✅
- [ ] Descargar nuevo google-services.json (PENDIENTE)

### Proyecto Local:
- [x] AndroidManifest.xml configurado con placeholder dinámico ✅
- [x] build.gradle configurado con manifestPlaceholders por build type ✅
- [ ] Reemplazar google-services.json con el nuevo de Firebase (PENDIENTE)

### Pruebas:
- [ ] Probar APK local con Google Sign-In
- [ ] Compilar AAB y subir a Play Console
- [ ] Probar app descargada de Play Store con Google Sign-In

---

## 📝 RESUMEN

**Ahora tienes configurado:**
- ✅ APK Local → Usa Client ID de Upload Key (funciona en local)
- ✅ AAB Play Store → Usa Client ID de Play Store ASK (funciona en Play Store)

**Falta solo:**
- ⏳ Descargar nuevo google-services.json de Firebase
- ⏳ Reemplazarlo en el proyecto
- ⏳ Limpiar y recompilar

---

**Última actualización:** 20 de noviembre de 2025  
**Estado:** ✅ Configuración de código completada - Falta actualizar google-services.json


