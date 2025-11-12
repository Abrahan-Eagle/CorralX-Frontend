# Actualización Requerida: Token FCM

## ✅ Estado Actual

### Frontend
- ✅ `google-services.json` actualizado con proyecto `corralx777`
- ✅ Package name correcto: `com.corralx.app`
- ✅ Project ID coincide con el backend

### Backend
- ✅ Credenciales configuradas para proyecto `corralx777`
- ✅ FirebaseService funcionando correctamente
- ⚠️ Token FCM actual es del proyecto anterior (`corralx-777`)

---

## ⚠️ Problema

El token FCM registrado en la base de datos fue generado con el proyecto anterior (`corralx-777`). Ahora que el frontend usa el proyecto `corralx777`, el token actual **no es válido** para el nuevo proyecto.

---

## ✅ Solución

### 1. Recompilar la app con el nuevo `google-services.json`

```bash
cd CorralX-Frontend
flutter clean
flutter pub get
flutter run -d [DEVICE_ID]
```

### 2. Reiniciar la app completamente

- Cerrar completamente la app (no solo minimizar)
- Volver a abrirla
- Esto forzará a Firebase a generar un nuevo token FCM válido para el proyecto `corralx777`

### 3. Iniciar sesión en la app

- Cuando el usuario inicie sesión, el frontend automáticamente registrará el nuevo token FCM en el backend
- El nuevo token será válido para el proyecto `corralx777`

### 4. Verificar que el token se haya actualizado

```bash
cd CorralX-Backend
php artisan tinker --execute="use App\Models\Profile; \$profile = Profile::whereNotNull('fcm_device_token')->first(); if (\$profile) { echo 'Token actualizado: ' . substr(\$profile->fcm_device_token, 0, 50) . '...' . PHP_EOL; }"
```

### 5. Probar enviar una notificación

```bash
cd CorralX-Backend
php artisan tinker --execute="use App\Models\Profile; use App\Services\FirebaseService; \$profile = Profile::whereNotNull('fcm_device_token')->first(); if (\$profile) { \$service = new FirebaseService(); \$result = \$service->sendToDevice(\$profile->fcm_device_token, 'Prueba FCM', 'Notificación de prueba desde backend', ['type' => 'test']); echo 'Resultado: ' . (\$result ? '✅ ÉXITO' : '❌ FALLÓ') . PHP_EOL; }"
```

---

## 🔍 Verificación

### Verificar que los proyectos coinciden:

```bash
# Frontend
cat android/app/google-services.json | jq -r '.project_info.project_id'
# Debe mostrar: corralx777

# Backend
cat storage/app/corralx777-firebase-adminsdk-fbsvc-c0fbc31cfc.json | jq -r '.project_id'
# Debe mostrar: corralx777
```

### Verificar que el package name es correcto:

```bash
cat android/app/google-services.json | jq -r '.client[0].client_info.android_client_info.package_name'
# Debe mostrar: com.corralx.app
```

---

## 📋 Checklist

- [x] `google-services.json` actualizado con proyecto `corralx777`
- [x] Package name correcto (`com.corralx.app`)
- [x] Project ID coincide con el backend
- [ ] App recompilada con el nuevo `google-services.json`
- [ ] App reiniciada completamente
- [ ] Usuario inició sesión en la app
- [ ] Nuevo token FCM registrado en el backend
- [ ] Notificación de prueba enviada exitosamente
- [ ] Notificación recibida en el dispositivo

---

## 🚀 Próximos Pasos

1. **Recompilar la app:**
   ```bash
   cd CorralX-Frontend
   flutter clean
   flutter pub get
   flutter run -d [DEVICE_ID]
   ```

2. **Reiniciar la app completamente**

3. **Iniciar sesión en la app**

4. **Verificar que el token se haya actualizado**

5. **Probar enviar una notificación**

---

## ✅ Conclusión

Una vez que el usuario reinicie la app y genere un nuevo token FCM válido para el proyecto `corralx777`, las notificaciones deberían funcionar correctamente. El servicio FCM está configurado correctamente, solo falta que el token sea válido para el proyecto correcto.

