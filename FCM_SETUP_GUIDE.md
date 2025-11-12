# Guía Completa de Configuración de FCM (Firebase Cloud Messaging)

## 📋 Estado Actual

### ✅ Frontend (Flutter)
- ✅ Firebase inicializado correctamente
- ✅ Permisos de notificación otorgados
- ✅ Canal de notificaciones Android configurado (estilo WhatsApp)
- ✅ Device token obtenido y registrado en backend
- ✅ Notificaciones locales configuradas
- ✅ Handlers de notificaciones configurados (foreground, background, terminated)
- ✅ Retry y manejo robusto de errores implementado
- ✅ Re-registro de token después del login

### ✅ Backend (Laravel)
- ✅ FirebaseService configurado con variables de entorno
- ✅ Endpoint `/api/fcm/register-token` implementado
- ✅ Endpoint `/api/fcm/unregister-token` implementado
- ✅ Envío de notificaciones push en ChatController
- ✅ Configuración mediante variables de entorno
- ✅ Logging detallado implementado
- ✅ Manejo de errores robusto

---

## 🔧 Configuración del Backend

### 1. Variables de Entorno (.env)

Agregar las siguientes variables al archivo `.env` del backend:

```env
# Firebase Configuration
FIREBASE_CREDENTIALS=storage/app/corralx777-firebase-adminsdk-fbsvc-05f9be7fae.json
FIREBASE_DATABASE_URL=https://corralx777-default-rtdb.firebaseio.com
FIREBASE_STORAGE_BUCKET=corralx777.firebasestorage.app
```

### 2. Archivo de Credenciales

**Ubicación**: `storage/app/corralx777-firebase-adminsdk-fbsvc-05f9be7fae.json`

**Verificar que el archivo existe**:
```bash
ls -la storage/app/corralx777-firebase-adminsdk-fbsvc-05f9be7fae.json
```

**Permisos** (si es necesario):
```bash
chmod 644 storage/app/corralx777-firebase-adminsdk-fbsvc-05f9be7fae.json
```

### 3. Configuración en `config/services.php`

La configuración de Firebase está en `config/services.php`:

```php
'firebase' => [
    'credentials' => env('FIREBASE_CREDENTIALS', 'storage/app/firebase-credentials.json'),
    'database_url' => env('FIREBASE_DATABASE_URL', ''),
    'storage_bucket' => env('FIREBASE_STORAGE_BUCKET', ''),
],
```

### 4. Limpiar Cache de Configuración

Después de actualizar `.env` o `config/services.php`, ejecutar:

```bash
php artisan config:clear
php artisan cache:clear
```

---

## 📱 Configuración del Frontend

### 1. Archivo `google-services.json`

**Ubicación**: `android/app/google-services.json`

**Verificar que el archivo existe** y contiene el `package_name` correcto:
```json
{
  "project_info": {
    "project_number": "602721721479",
    "project_id": "corralx777",
    "storage_bucket": "corralx777.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:602721721479:android:cc528afbed14424ba4ec22",
        "android_client_info": {
          "package_name": "com.corralx.app"
        }
      }
    }
  ]
}
```

### 2. AndroidManifest.xml

Verificar que el `AndroidManifest.xml` tenga:
- ✅ Permisos de notificación
- ✅ Servicio de Firebase Cloud Messaging
- ✅ Receptor de notificaciones en segundo plano

### 3. FirebaseService (Flutter)

Verificar que `FirebaseService` esté:
- ✅ Inicializado en `main.dart`
- ✅ Registrando device token después del login
- ✅ Configurando handlers de notificaciones
- ✅ Re-registrando token después del login exitoso

---

## 🧪 Pruebas

### 1. Probar Registro de Token

1. Abrir la app en el dispositivo
2. Iniciar sesión con Google
3. Verificar en los logs:
   ```
   📱 Device token obtenido: ...
   ✅ Device token registrado en backend
   ✅ FCM token re-registrado después del login
   ```

### 2. Probar Envío de Notificación

1. Enviar un mensaje desde la app
2. Verificar en los logs del backend:
   ```
   🚀 INICIO sendPushNotification
   🔍 Debug sendPushNotification
   🔥 LLAMANDO FirebaseService->sendToDevice
   ✅ Notificación push enviada
   ```

### 3. Probar Recepción de Notificación

1. Cerrar la app o ponerla en background
2. Enviar un mensaje desde otro dispositivo/usuario
3. Verificar que se reciba la notificación
4. Verificar que al tocar la notificación, se abra la conversación

---

## 🐛 Solución de Problemas

### Error: "Archivo de credenciales de Firebase no encontrado"

**Causa**: El archivo de credenciales no existe o la ruta es incorrecta.

**Solución**:
1. Verificar que el archivo existe en `storage/app/corralx777-firebase-adminsdk-fbsvc-05f9be7fae.json`
2. Verificar que la variable `FIREBASE_CREDENTIALS` en `.env` es correcta
3. Ejecutar `php artisan config:clear` y `php artisan cache:clear`

### Error: "Firebase messaging no disponible"

**Causa**: El FirebaseService no se inicializó correctamente.

**Solución**:
1. Verificar los logs del backend para ver el error específico
2. Verificar que el archivo de credenciales es válido
3. Verificar que las credenciales tienen los permisos correctos en Firebase Console

### Error: "Device token no registrado"

**Causa**: El usuario no está autenticado o el token no se pudo registrar.

**Solución**:
1. Verificar que el usuario esté autenticado
2. Verificar que el endpoint `/api/fcm/register-token` esté funcionando
3. Verificar que el token se esté guardando en el perfil del usuario

### Error: "Notificación no recibida"

**Causa**: El dispositivo no tiene el token registrado o hay un problema con FCM.

**Solución**:
1. Verificar que el device token esté registrado en el backend
2. Verificar que el dispositivo tenga conexión a Internet
3. Verificar que Google Play Services esté actualizado
4. Verificar que los permisos de notificación estén otorgados

---

## 📊 Logs Esperados

### Backend - Inicialización
```
✅ Firebase Service inicializado
   credentials_path: /path/to/storage/app/corralx777-firebase-adminsdk-fbsvc-05f9be7fae.json
   project_id: corralx777
```

### Backend - Registro de Token
```
✅ FCM token registrado
   profile_id: 123
   token: euCgRAAPSwSIsQvOa1HF...
```

### Backend - Envío de Notificación
```
🚀 INICIO sendPushNotification
🔍 Debug sendPushNotification
🔥 LLAMANDO FirebaseService->sendToDevice
✅ Notificación push enviada
   title: Nombre del remitente
   body: Mensaje...
   device_token: euCgRAAPSwSIsQvOa1HF...
   conversation_id: 123
   message_id: 456
```

### Frontend - Inicialización
```
🔧 FirebaseService: Inicializando Firebase...
✅ Permisos de notificación otorgados
✅ Canal de notificaciones Android configurado (estilo WhatsApp)
📱 Device token obtenido: euCgRAAPSwSIsQvOa1HF...
✅ Device token registrado en backend
✅ FirebaseService: Inicializado correctamente
```

### Frontend - Login
```
🔑 OAuth2 Tokens obtenidos:
   - accessToken: ✅ Obtenido (ya29.a0ATi6K2tlFRH5g...)
   - idToken: ✅ Obtenido (eyJhbGciOiJSUzI1NiIs...)
   - serverClientId configurado: ✅ Sí
💡 Inicio de sesión exitoso
✅ FCM token re-registrado después del login
```

### Frontend - Recepción de Notificación
```
📬 FCM: Mensaje recibido (foreground)
📱 Mostrando notificación estilo WhatsApp:
   - Remitente: Nombre del remitente
   - Mensaje: Contenido del mensaje
   - Conversation ID: 123
```

---

## ✅ Checklist de Configuración

### Backend
- [ ] Variables de entorno configuradas en `.env`
- [ ] Archivo de credenciales en `storage/app/corralx777-firebase-adminsdk-fbsvc-05f9be7fae.json`
- [ ] Configuración en `config/services.php`
- [ ] Cache de configuración limpiado
- [ ] FirebaseService inicializado correctamente
- [ ] Endpoints de registro de tokens funcionando
- [ ] Envío de notificaciones funcionando

### Frontend
- [ ] Archivo `google-services.json` configurado
- [ ] `AndroidManifest.xml` configurado
- [ ] `FirebaseService` inicializado
- [ ] Permisos de notificación otorgados
- [ ] Device token obtenido y registrado
- [ ] Handlers de notificaciones configurados
- [ ] Notificaciones locales configuradas
- [ ] Re-registro de token después del login

### Pruebas
- [ ] Device token se registra correctamente
- [ ] Notificaciones se envían correctamente
- [ ] Notificaciones se reciben correctamente
- [ ] Notificaciones se muestran correctamente
- [ ] Tap en notificación abre la conversación correcta

---

## 📝 Notas Importantes

1. **Variables de Entorno**: Las variables de entorno deben estar configuradas correctamente en el `.env` del backend.

2. **Archivo de Credenciales**: El archivo de credenciales debe estar en `storage/app/` y debe tener permisos de lectura.

3. **Cache de Configuración**: Después de actualizar `.env` o `config/services.php`, ejecutar `php artisan config:clear` y `php artisan cache:clear`.

4. **Google Play Services**: El dispositivo Android debe tener Google Play Services actualizado para que FCM funcione correctamente.

5. **Permisos de Notificación**: El usuario debe otorgar permisos de notificación para que las notificaciones se muestren.

6. **Token de Dispositivo**: El token de dispositivo se registra automáticamente después del login. Si el usuario no está autenticado, el token se intentará registrar después del login.

7. **Notificaciones en Background**: Las notificaciones en background se muestran automáticamente cuando la app está cerrada o en segundo plano.

8. **Notificaciones en Foreground**: Las notificaciones en foreground se muestran como notificaciones locales estilo WhatsApp.

---

## 🔗 Referencias

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Kreait Firebase PHP Documentation](https://firebase-php.readthedocs.io/)
- [Flutter Firebase Messaging Documentation](https://firebase.flutter.dev/docs/messaging/overview)

---

## 🎯 Configuración Actual

| Componente | Valor |
|------------|-------|
| **Project ID** | `corralx777` |
| **Package Name** | `com.corralx.app` |
| **Credentials File** | `storage/app/corralx777-firebase-adminsdk-fbsvc-05f9be7fae.json` |
| **Database URL** | `https://corralx777-default-rtdb.firebaseio.com` |
| **Storage Bucket** | `corralx777.firebasestorage.app` |
| **Backend Endpoint** | `/api/fcm/register-token` |
| **Frontend Service** | `FirebaseService` |

---

**Última actualización**: 2025-01-13

