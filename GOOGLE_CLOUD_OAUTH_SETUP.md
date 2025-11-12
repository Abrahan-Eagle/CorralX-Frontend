# Guía: Configurar OAuth Client para Android en Google Cloud Console

## Información del Package Android

- **Package Name**: `com.corralx.app`
- **Application ID**: `com.corralx.app`

## SHA-1 Certificate Fingerprint

### SHA-1 (Único para Debug y Release)
**Nota**: Tanto la configuración de debug como release usan el mismo keystore (`mykey.jks`), por lo tanto usan el mismo SHA-1.

```
F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4
```

**Keystore utilizado**: `android/app/mykey.jks`  
**Alias**: `androiddebugkey`  
**Configuración**: Ambos `signingConfigs.debug` y `signingConfigs.release` usan el mismo keystore

## Pasos para Configurar OAuth Client en Google Cloud Console

### 1. Acceder a Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona el proyecto: **corralx-777-aipp** (o el proyecto correcto)
3. Si no tienes el proyecto, créalo primero

### 2. Habilitar Google Sign-In API

1. Ve a **APIs & Services** → **Library**
2. Busca "Google Sign-In API" o "Google+ API"
3. Haz clic en **Enable** si no está habilitada

### 3. Crear OAuth 2.0 Client ID para Android

1. Ve a **APIs & Services** → **Credentials**
2. Haz clic en **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Si es la primera vez, configura el consent screen:
   - **User Type**: External (o Internal si es para uso interno)
   - Completa la información requerida
   - Guarda y continúa

4. En **Application type**, selecciona **Android**

5. Completa el formulario:
   - **Name**: `CorralX Android App` (o el nombre que prefieras)
   - **Package name**: `com.corralx.app`
   - **SHA-1 certificate fingerprint**: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`

6. **IMPORTANTE**: Como ambos (debug y release) usan el mismo keystore, solo necesitas agregar un SHA-1 al OAuth client

### 4. Obtener el Client ID

1. Después de crear el OAuth client, se mostrará un popup con el **Client ID**
2. Copia el **Client ID** (formato: `XXXXX-XXXXX.apps.googleusercontent.com`)
3. Guarda este Client ID en un lugar seguro

### 5. Actualizar AndroidManifest.xml

Después de obtener el Client ID, actualiza el archivo `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.auth.api.credentials.ClientId"
    android:value="TU_NUEVO_CLIENT_ID_AQUI.apps.googleusercontent.com"/>
```

### 6. Verificar la Configuración

1. Asegúrate de que el **Package name** coincida exactamente con `com.corralx.app`
2. Verifica que los **SHA-1 fingerprints** sean correctos
3. Espera unos minutos para que los cambios se propaguen (puede tomar hasta 10 minutos)

## Notas Importantes

- ⚠️ **El SHA-1 debe coincidir exactamente** con el certificado usado para firmar la app
- ⚠️ **El Package name debe coincidir exactamente** con el `applicationId` en `build.gradle`
- ⚠️ **En este proyecto, debug y release usan el mismo keystore** (`mykey.jks`), por lo tanto solo necesitas un SHA-1
- ⚠️ Los cambios pueden tardar hasta 10 minutos en propagarse

## Verificación

Para verificar que todo está correcto:

1. Compila la app: `flutter build apk --debug` o `flutter run`
2. Intenta iniciar sesión con Google
3. Si hay errores, verifica:
   - Que el Package name coincida exactamente
   - Que el SHA-1 sea correcto
   - Que hayas esperado suficiente tiempo para la propagación

## Solución de Problemas

### Error: "OAuth client not found"
- Verifica que el Package name coincida exactamente
- Verifica que el SHA-1 sea correcto
- Espera unos minutos más para la propagación

### Error: "Invalid client"
- Verifica que el Client ID esté correcto en AndroidManifest.xml
- Verifica que el OAuth client esté en el proyecto correcto de Google Cloud

### Error: "Sign in failed"
- Verifica que la API de Google Sign-In esté habilitada
- Verifica que el consent screen esté configurado correctamente
- Verifica que el SHA-1 usado sea el correcto (en este caso, solo hay uno porque ambos usan el mismo keystore)

## Información Actual del Proyecto

- **Project ID**: `corralx-777-aipp`
- **Package Name**: `com.corralx.app`
- **SHA-1 (Debug y Release)**: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
- **OAuth Client ID (Android)**: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com`
- **Client ID (Web)**: `332023551639-2hpmjjs8j2jn70g7ppdhsfujeosfha7b.apps.googleusercontent.com`

## Próximos Pasos

1. Crear el OAuth client en Google Cloud Console
2. Copiar el nuevo Client ID
3. Actualizar `AndroidManifest.xml` con el nuevo Client ID
4. Probar la compilación y el inicio de sesión con Google

