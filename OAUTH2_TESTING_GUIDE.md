# Guía de Prueba: OAuth2 con serverClientId

## 🎯 Objetivo
Verificar que el flujo completo de Google Sign-In funciona correctamente con la nueva configuración de `serverClientId` y que se obtiene el `idToken` correctamente.

## 📋 Pasos para Probar

### 1. Cerrar Sesión Actual
1. Abrir la app en el dispositivo
2. Ir a la pantalla de **Perfil**
3. Hacer clic en el botón **"Cerrar Sesión"**
4. Confirmar el cierre de sesión
5. Verificar que se redirige a la pantalla de login

### 2. Iniciar Sesión con Google
1. En la pantalla de login, hacer clic en el botón **"Iniciar sesión con Google"**
2. Seleccionar una cuenta de Google
3. Autorizar los permisos solicitados
4. Verificar que se completa el inicio de sesión

### 3. Verificar Logs
Buscar en los logs los siguientes mensajes:

```
🔑 OAuth2 Tokens obtenidos:
   - accessToken: ✅ Obtenido (...)
   - idToken: ✅ Obtenido (...)
   - serverClientId configurado: ✅ Sí
💾 accessToken guardado temporalmente
💾 idToken guardado en secure storage
```

### 4. Verificar Funcionamiento
- ✅ La app debe redirigir a la pantalla principal
- ✅ El usuario debe estar autenticado
- ✅ El perfil debe cargarse correctamente
- ✅ No debe haber errores relacionados con OAuth2

## 🔍 Qué Verificar

### ✅ Tokens Obtenidos
- **accessToken**: Debe estar presente (siempre disponible)
- **idToken**: Debe estar presente (gracias a `serverClientId`)
- **serverClientId**: Debe estar configurado correctamente

### ✅ Autenticación
- El usuario debe autenticarse correctamente
- El token del backend debe obtenerse
- El perfil debe cargarse correctamente

### ✅ Sin Errores
- No debe haber errores relacionados con OAuth2
- No debe haber errores relacionados con `serverClientId`
- No debe haber errores relacionados con `idToken`

## 📝 Logs Esperados

### Logs de Inicio de Sesión
```
🔑 OAuth2 Tokens obtenidos:
   - accessToken: ✅ Obtenido (ya29.a0AfH6SMC...)
   - idToken: ✅ Obtenido (eyJhbGciOiJSUzI1NiI...)
   - serverClientId configurado: ✅ Sí
💾 accessToken guardado temporalmente
💾 idToken guardado en secure storage
```

### Logs de Autenticación
```
💡 Datos del perfil de usuario: {...}
💡 Respuesta del servidor: {success: true, ...}
💡 Token guardado correctamente con su expiración.
💡 Inicio de sesión exitoso
```

## ❌ Errores Posibles

### Error: "idToken no disponible"
**Causa**: La configuración de `serverClientId` no está funcionando correctamente.

**Solución**:
1. Verificar que el `serverClientId` esté configurado correctamente en `google_sign_in_service.dart`
2. Verificar que el OAuth Client ID (Web) esté configurado en Google Cloud Console
3. Verificar que el OAuth Consent Screen esté configurado correctamente

### Error: "OAuth client not found"
**Causa**: El OAuth Client ID no está configurado correctamente en Google Cloud Console.

**Solución**:
1. Verificar que el OAuth Client ID (Android) esté configurado en Google Cloud Console
2. Verificar que el Package Name coincida exactamente: `com.corralx.app`
3. Verificar que el SHA-1 sea correcto: `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`

### Error: "Sign in failed"
**Causa**: Problemas con la configuración de OAuth o el OAuth Consent Screen.

**Solución**:
1. Verificar que el OAuth Consent Screen esté configurado correctamente
2. Verificar que las APIs necesarias estén habilitadas (Google People API)
3. Verificar que el usuario tenga permisos para iniciar sesión (si está en modo Testing)

## 📊 Resultados Esperados

### ✅ Éxito
- ✅ `idToken` obtenido correctamente
- ✅ `accessToken` obtenido correctamente
- ✅ Autenticación exitosa
- ✅ Perfil cargado correctamente
- ✅ No hay errores

### ⚠️ Advertencias
- ⚠️ Si `idToken` no está disponible, verificar la configuración de `serverClientId`
- ⚠️ Si hay errores de OAuth, verificar la configuración en Google Cloud Console

## 🔧 Configuración Actual

| Componente | Valor |
|------------|-------|
| **OAuth Client ID (Android)** | `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com` |
| **OAuth Client ID (Web)** | `332023551639-2hpmjjs8j2jn70g7ppdhsfujeosfha7b.apps.googleusercontent.com` |
| **serverClientId** | Configurado en `GoogleSignIn` |
| **Scopes** | `['openid', 'profile', 'email']` |
| **Package Name** | `com.corralx.app` |
| **SHA-1** | `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4` |

## 📝 Notas

- El `idToken` solo estará disponible si `serverClientId` está configurado correctamente
- El `accessToken` siempre estará disponible
- El `idToken` es necesario para validación en el backend (si se implementa)
- El `accessToken` se usa para obtener información del perfil del usuario

---

**Última actualización**: 2025-01-13

