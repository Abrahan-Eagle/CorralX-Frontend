# 🔧 Solución Definitiva: OAuth no funciona en AAB de Play Store

## 🎯 PROBLEMA IDENTIFICADO

Cuando subes un **AAB a Play Store**, Google Play **re-firma** tu aplicación con su propia **App Signing Key (ASK)**. El SHA-1/SHA-256 que necesitas registrar en Google Cloud Console es el de la **ASK de Google Play**, NO el de tu keystore de carga.

**Esto explica por qué:**
- ✅ El APK local funciona (usa tu keystore)
- ❌ El AAB en Play Store no funciona (usa la ASK de Google Play)

---

## 📋 FASE 1: Obtener la Huella Digital desde Google Play Console

### Paso 1.1: Acceder a Google Play Console

1. Ve a: **https://play.google.com/console/**
2. Inicia sesión con tu cuenta de desarrollador
3. Selecciona tu app **CorralX**

### Paso 1.2: Navegar a Integridad de la App

1. En el menú lateral izquierdo, busca y haz clic en:
   ```
   Lanzamiento (Release) → Configuración (Setup) → Integridad de la app (App Integrity)
   ```

2. O ve directamente a la URL (reemplaza `TU_PACKAGE_NAME`):
   ```
   https://play.google.com/console/u/0/developers/YOUR_DEVELOPER_ID/app/YOUR_APP_ID/app-integrity
   ```

### Paso 1.3: Localizar la Clave de Firma de la Aplicación (ASK)

En la página de "App Integrity", busca la sección:
- **"Clave de firma de la aplicación"** (App Signing Key)
- O **"App signing key certificate"**

**Importante:** Esta es la clave que Google Play usa para firmar la app que los usuarios descargan, NO tu keystore de carga.

### Paso 1.4: Copiar las Huellas Digitales

1. **Busca el certificado SHA-1:**
   - Debe aparecer como: **"Huella digital del certificado SHA-1"**
   - O **"SHA-1 certificate fingerprint"**
   - Copia el valor completo (formato: `DA:39:A3:EE:5E:6B:4B:0D:32:55:BF:EF:95:60:18:90:AF:D8:07:09`)

2. **Busca también el certificado SHA-256:**
   - Debe aparecer como: **"SHA-256 certificate fingerprint"**
   - Copia también este valor (es más largo que SHA-1)

3. **Guarda ambos valores** (los necesitarás en las siguientes fases)

**💡 NOTA:** Si no has subido ningún AAB aún, Google Play mostrará que aún no hay una clave de firma de aplicación. En ese caso:
- Sube tu primer AAB a Play Console (puede ser a "Internal testing")
- Después de subirlo, Google generará la ASK
- Espera unos minutos y vuelve a esta página para ver el SHA-1/SHA-256

---

## 📋 FASE 2: Registrar el Certificado en Google Cloud Console

### Paso 2.1: Acceder a Google Cloud Console

1. Ve a: **https://console.cloud.google.com/**
2. Selecciona el proyecto: **corralx-777-aipp** (o tu proyecto de CorralX)

### Paso 2.2: Ir a Credenciales OAuth

1. En el menú lateral, ve a:
   ```
   APIs & Services → Credentials
   ```
   O directamente: **https://console.cloud.google.com/apis/credentials**

### Paso 2.3: Editar el OAuth Client ID de Android

1. Busca el OAuth Client ID:
   ```
   332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com
   ```
   (Tipo: Android)

2. **Haz clic en el nombre** para editarlo

### Paso 2.4: Agregar el SHA-1 de Play Store

1. En el campo **"Huella digital del certificado SHA-1"**:
   - **NO elimines** el SHA-1 existente de tu keystore de carga
   - Busca un botón **"+"** o **"ADD"** o **"Agregar"** para agregar múltiples fingerprints
   - Haz clic en ese botón
   - Pega el **SHA-1 que copiaste de Play Console** (el de la ASK)

2. **Ahora deberías tener DOS SHA-1:**
   - ✅ SHA-1 de tu keystore de carga: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
   - ✅ SHA-1 de Play Store ASK: `[El que copiaste de Play Console]`

### Paso 2.5: Agregar SHA-256 (Si está disponible)

1. Si Google Cloud Console permite agregar SHA-256:
   - Agrega también el SHA-256 que copiaste de Play Console

2. **Guarda los cambios** (botón "SAVE" o "Guardar")

### Paso 2.6: Verificar Package Name

Asegúrate de que el **Package name** siga siendo exactamente:
```
com.corralx.app
```

---

## 📋 FASE 3: Registrar en Firebase Console (Si usas Firebase)

**Nota:** Si NO usas Firebase para autenticación, puedes saltarte esta fase.

### Paso 3.1: Acceder a Firebase Console

1. Ve a: **https://console.firebase.google.com/**
2. Selecciona tu proyecto: **corralx-777-aipp** (o el nombre de tu proyecto)

### Paso 3.2: Ir a Configuración del Proyecto

1. Haz clic en el **ícono de engranaje** (⚙️) en la parte superior
2. Selecciona: **"Configuración del proyecto"** (Project Settings)

### Paso 3.3: Seleccionar la App Android

1. En la pestaña **"General"** (General)
2. Busca la sección **"Tus apps"** (Your apps)
3. Busca tu app Android identificada por: **`com.corralx.app`**
4. Haz clic en ella o desplázate hasta ver su configuración

### Paso 3.4: Agregar Huella Digital SHA-1 de Play Store

1. Busca la sección **"Huellas digitales de certificado SHA"** (SHA certificate fingerprints)

2. Verás las huellas digitales actuales (probablemente solo la de tu keystore)

3. **Agrega el SHA-1 de Play Store:**
   - Haz clic en **"Agregar huella digital"** (Add fingerprint)
   - Pega el **SHA-1 que copiaste de Play Console**
   - Haz clic en **"Agregar"** o **"Save"**

4. **Agrega también SHA-256 si está disponible:**
   - Si copiaste SHA-256 de Play Console, agrégalo también

### Paso 3.5: Descargar google-services.json Actualizado

**⚠️ ESTE PASO ES CRÍTICO**

1. En la misma página de configuración de la app Android
2. Busca el botón **"Descargar google-services.json"** (Download google-services.json)
3. Haz clic para descargar el archivo actualizado

### Paso 3.6: Reemplazar google-services.json en el Proyecto

1. **Ubicación actual del archivo:**
   ```
   CorralX-Frontend/android/app/google-services.json
   ```

2. **Backup del archivo antiguo (opcional pero recomendado):**
   ```bash
   cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
   cp android/app/google-services.json android/app/google-services.json.backup
   ```

3. **Reemplazar con el nuevo archivo:**
   - Copia el archivo `google-services.json` descargado
   - Pégalo en: `CorralX-Frontend/android/app/google-services.json`
   - **Reemplaza** el archivo existente

---

## 📋 FASE 4: Recompilación y Despliegue

### Paso 4.1: Limpiar el Proyecto

```bash
cd /var/www/html/proyectos/AIPP-RENNY/DESARROLLO/CorralX/CorralX-Frontend
flutter clean
```

**Por qué:** Esto elimina builds anteriores y fuerza a Flutter a usar el nuevo `google-services.json`.

### Paso 4.2: Obtener Dependencias

```bash
flutter pub get
```

### Paso 4.3: Compilar el Nuevo AAB

```bash
flutter build appbundle --release
```

**Ubicación del AAB generado:**
```
build/app/outputs/bundle/release/app-release.aab
```

### Paso 4.4: Esperar Propagación

**Espera 10-15 minutos** después de:
- Guardar cambios en Google Cloud Console
- Guardar cambios en Firebase Console

Los cambios pueden tardar en propagarse.

### Paso 4.5: Subir a Google Play Console

1. Ve a Google Play Console
2. Navega a: **Lanzamiento (Release) → Producción** (o **Internal testing** para probar primero)
3. Sube el nuevo **app-release.aab**
4. Completa el formulario de release
5. Haz clic en **"Revisar release"** y luego **"Iniciar roll-out a producción"**

---

## ✅ CHECKLIST FINAL

### Google Play Console:
- [ ] Accedí a "Integridad de la app"
- [ ] Copié el SHA-1 de la App Signing Key
- [ ] Copié el SHA-256 de la App Signing Key (si está disponible)

### Google Cloud Console:
- [ ] Edité el OAuth Client ID de Android
- [ ] Agregué el SHA-1 de Play Store ASK (sin eliminar el de carga)
- [ ] Agregué el SHA-256 de Play Store ASK (si está disponible)
- [ ] Verifiqué que Package Name sea `com.corralx.app`
- [ ] Guardé los cambios

### Firebase Console (Si aplica):
- [ ] Agregué SHA-1 de Play Store en la app Android
- [ ] Agregué SHA-256 de Play Store (si está disponible)
- [ ] Descargué el nuevo `google-services.json`
- [ ] Reemplacé el archivo en `android/app/google-services.json`

### Flutter:
- [ ] Ejecuté `flutter clean`
- [ ] Ejecuté `flutter pub get`
- [ ] Compilé nuevo AAB con `flutter build appbundle --release`
- [ ] Esperé 10-15 minutos después de cambios en consolas
- [ ] Subí el nuevo AAB a Play Console

---

## 🧪 CÓMO PROBAR

### Después de subir el nuevo AAB:

1. **Espera a que Google Play procese el AAB** (puede tardar unos minutos)

2. **Descarga la app desde Play Store** (usa internal testing primero):
   - Crea un track de "Internal testing" si no lo tienes
   - Agrega tu email como tester
   - Descarga la app desde Play Store (no instales el APK local)

3. **Prueba Google Sign-In:**
   - Abre la app descargada de Play Store
   - Haz clic en "Continuar con Google"
   - Debería funcionar correctamente

---

## 🔍 SOLUCIÓN DE PROBLEMAS

### Si no encuentras "App Integrity" en Play Console:

**Posibles razones:**
1. Aún no has subido ningún AAB a Play Console
   - **Solución:** Sube tu primer AAB (aunque sea a internal testing)
   - Después de subirlo, espera unos minutos
   - La sección "App Integrity" aparecerá

2. Estás en una cuenta que no tiene acceso
   - **Solución:** Verifica que tengas permisos de administrador

### Si Play Console muestra "Keystore de carga" pero no "App Signing Key":

- Si es tu primer AAB, Google Play puede tardar unos minutos en generar la ASK
- Espera 5-10 minutos y refresca la página
- Si después de 30 minutos no aparece, puede que necesites configurar App Signing manualmente

### Si después de todo sigue sin funcionar:

1. **Verifica logs:**
   ```bash
   adb logcat | grep -i "oauth\|google\|sign\|error"
   ```

2. **Verifica OAuth Consent Screen:**
   - Debe estar publicado o tu email debe estar como test user

3. **Verifica que ambos SHA-1 estén en Google Cloud Console:**
   - SHA-1 de tu keystore de carga
   - SHA-1 de Play Store ASK

---

## 📝 NOTAS IMPORTANTES

### ¿Por qué necesitas ambos SHA-1?

- **SHA-1 de tu keystore:** Para desarrollo local, APKs locales, y verificación durante el proceso de subida
- **SHA-1 de Play Store ASK:** Para la app que los usuarios finales descargan de Play Store

**Con ambos configurados:**
- ✅ APK local funciona
- ✅ AAB en Play Store funciona
- ✅ App descargada de Play Store funciona

### Sincronización

- Los cambios en Google Cloud Console y Firebase pueden tardar **5-15 minutos** en propagarse
- Es recomendable esperar antes de probar
- Si falla, espera más tiempo y prueba de nuevo

---

**Última actualización:** 20 de noviembre de 2025  
**Estado:** ✅ Guía completa para sincronización de firmas con Play Store


