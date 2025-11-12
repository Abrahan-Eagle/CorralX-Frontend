# Checklist: Configuración Completa de OAuth para Android

## ✅ Completado

### 1. OAuth Client ID de Android
- ✅ **Client ID creado en Google Cloud Console**: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com`
- ✅ **Package Name**: `com.corralx.app`
- ✅ **SHA-1**: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
- ✅ **Client ID actualizado en AndroidManifest.xml**

### 2. Código Flutter
- ✅ `GoogleSignIn` configurado en `google_sign_in_service.dart`
- ✅ Endpoint del backend configurado: `/api/auth/google`
- ✅ Manejo de tokens (accessToken e idToken)

### 3. Backend
- ✅ Endpoint `/api/auth/google` implementado
- ✅ Manejo de datos de perfil de Google
- ✅ Creación/actualización de usuarios
- ✅ Generación de tokens Sanctum

---

## ⚠️ Pendiente / Verificación Necesaria

### 1. Google Cloud Console - APIs Habilitadas

**✅ APIs Necesarias:**
- ✅ **Google People API** - Ya habilitada ✅
- ⚠️ **Google Sign-In API** - Ya no existe como API separada (fue integrada en otras APIs)
- ⚠️ **OAuth2 API** - Es parte del sistema base de Google Cloud y no necesita habilitarse explícitamente

**Nota Importante:**
- El código actual usa `https://www.googleapis.com/oauth2/v3/userinfo` para obtener información del perfil
- Esta endpoint NO requiere habilitación de APIs adicionales, es parte del sistema OAuth2 de Google
- **Google People API ya está habilitada**, lo cual es suficiente para funcionalidades avanzadas
- Para Google Sign-In básico en Android, **NO necesitas APIs adicionales** si el OAuth Client está bien configurado

**✅ Estado Actual:**
- ✅ Google People API: Habilitada
- ✅ OAuth Client ID: Configurado correctamente
- ✅ SHA-1: Configurado correctamente
- ✅ AndroidManifest.xml: Actualizado con Client ID

### 2. OAuth Consent Screen

**Verificar configuración:**
- [ ] **User Type**: External (o Internal si es para uso interno)
- [ ] **App name**: CorralX (o el nombre de tu app)
- [ ] **User support email**: Tu email de soporte
- [ ] **Developer contact information**: Tu email
- [ ] **Scopes**: Verificar que estén configurados los scopes necesarios:
  - `openid`
  - `profile`
  - `email`

**Cómo verificar:**
1. Ve a **APIs & Services** → **OAuth consent screen**
2. Verifica que la información esté completa
3. Si está en modo "Testing", verifica que los usuarios de prueba estén agregados

### 3. Configuración de GoogleSignIn en Flutter (Opcional pero Recomendado)

**Actualizar `google_sign_in_service.dart`:**

Actualmente el código usa:
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn();
```

**Recomendación:** Configurar `serverClientId` para obtener un `idToken` válido para verificación en el backend:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['openid', 'profile', 'email'],
  serverClientId: '332023551639-2hpmjjs8j2jn70g7ppdhsfujeosfha7b.apps.googleusercontent.com', // Client ID de Web
);
```

**Client ID de Web**: `332023551639-2hpmjjs8j2jn70g7ppdhsfujeosfha7b.apps.googleusercontent.com`

**Beneficios:**
- Obtiene un `idToken` válido que puede ser verificado por el backend
- Mejor seguridad al validar el token en el servidor
- Compatible con backend que valida tokens de Google

**Nota:** Actualmente el backend NO valida el token, solo confía en los datos del perfil. Si quieres agregar validación, necesitarás:
- Configurar `serverClientId` en Flutter
- Implementar validación de tokens en el backend usando la librería de Google

### 4. Verificación en Google Cloud Console

**Verificar que el OAuth Client esté correctamente configurado:**
1. Ve a **APIs & Services** → **Credentials**
2. Busca el OAuth Client ID: `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com`
3. Verifica que:
   - **Application type**: Android
   - **Package name**: `com.corralx.app`
   - **SHA-1 certificate fingerprint**: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`

### 5. Probar el Flujo Completo

**Pasos para probar:**
1. Compila la app: `flutter build apk --debug` o `flutter run`
2. Ejecuta la app en un dispositivo Android
3. Intenta iniciar sesión con Google
4. Verifica que:
   - Se muestre el selector de cuenta de Google
   - Se complete el inicio de sesión
   - Se obtenga el token del backend
   - El usuario se cree/actualice correctamente en la base de datos

**Posibles errores:**
- **"OAuth client not found"**: Verifica que el Package name y SHA-1 coincidan exactamente
- **"Sign in failed"**: Verifica que las APIs estén habilitadas y el consent screen esté configurado
- **"Invalid client"**: Verifica que el Client ID en AndroidManifest.xml sea correcto
- **"Access blocked"**: Verifica que el OAuth consent screen esté configurado correctamente

### 6. Tiempo de Propagación

**Importante:** Los cambios en Google Cloud Console pueden tardar hasta **10 minutos** en propagarse. Si algo no funciona inmediatamente, espera unos minutos e intenta de nuevo.

---

## 📋 Resumen de Configuración Actual

| Componente | Valor |
|------------|-------|
| **Package Name** | `com.corralx.app` |
| **SHA-1 (Debug y Release)** | `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4` |
| **OAuth Client ID (Android)** | `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com` |
| **OAuth Client ID (Web)** | `332023551639-2hpmjjs8j2jn70g7ppdhsfujeosfha7b.apps.googleusercontent.com` |
| **Backend Endpoint** | `/api/auth/google` |
| **AndroidManifest.xml** | ✅ Actualizado con Client ID de Android |

---

## 🔧 Próximos Pasos Recomendados

1. **✅ APIs en Google Cloud Console** - COMPLETADO ✅
   - ✅ Google People API: Habilitada
   - ⚠️ Google Sign-In API: Ya no existe como API separada (no es necesaria)
   - ⚠️ OAuth2 API: Es parte del sistema base (no necesita habilitación)

2. **Verificar OAuth Consent Screen** (5 minutos) - ⚠️ IMPORTANTE
   - Completar información faltante
   - Verificar scopes: `openid`, `profile`, `email`
   - Agregar usuarios de prueba si está en modo Testing
   - **Este es el paso más importante después de las APIs**

3. **Configurar serverClientId en Flutter** (Opcional, 2 minutos)
   - Actualizar `google_sign_in_service.dart`
   - Agregar `serverClientId` con el Client ID de Web
   - Mejora la seguridad pero no es estrictamente necesario

4. **Probar el flujo completo** (10 minutos) - ⚠️ CRÍTICO
   - Compilar y ejecutar la app
   - Probar inicio de sesión con Google
   - Verificar que funcione correctamente
   - Si hay errores, verificar OAuth Consent Screen

5. **Implementar validación de tokens en backend** (Opcional, avanzado)
   - Instalar librería de Google para validar tokens
   - Implementar validación en `AuthController::googleUser`
   - Mejorar seguridad del flujo

---

## ❓ Preguntas Frecuentes

### ¿Por qué necesito el Client ID de Web si es una app Android?
El `serverClientId` (Client ID de Web) se usa para obtener un `idToken` que puede ser verificado por el backend. Esto mejora la seguridad al permitir que el backend valide que el token proviene realmente de Google.

### ¿Es necesario configurar serverClientId?
No es estrictamente necesario si el backend no valida los tokens. Sin embargo, es una buena práctica de seguridad para producción.

### ¿Qué pasa si el OAuth consent screen está en modo "Testing"?
Solo los usuarios agregados como "Test users" podrán iniciar sesión. Para producción, necesitas publicar la app o agregar más usuarios de prueba.

### ¿Cuánto tiempo tarda en propagarse un cambio en Google Cloud Console?
Generalmente entre 5-10 minutos, pero puede tomar hasta 30 minutos en algunos casos.

---

## 📝 Notas Adicionales

- El backend actualmente **NO valida** el token de Google, solo confía en los datos del perfil
- Para producción, se recomienda implementar validación de tokens en el backend
- El `idToken` solo estará disponible si se configura `serverClientId` en GoogleSignIn
- El `accessToken` siempre estará disponible y se puede usar para obtener información del perfil

