# 🔧 Corrección de Notificaciones Push

## ❌ Problema Encontrado

**Error:** `SenderId mismatch`

**Causa:**
- Frontend usa proyecto Firebase: `corralx-777-aipp` (Project Number: `332023551639`)
- Backend usa proyecto Firebase: `corralx777`
- Los tokens FCM se generan con el Sender ID del frontend (`332023551639`)
- El backend intenta enviar notificaciones usando un proyecto diferente (`corralx777`)
- Firebase rechaza porque el token no pertenece al proyecto del backend

---

## ✅ Solución

### Opción 1: Actualizar backend para usar el mismo proyecto que frontend (RECOMENDADO)

El backend debe usar las credenciales del proyecto `corralx-777-aipp`:

1. **Descargar credenciales del proyecto correcto:**
   - Ir a [Firebase Console](https://console.firebase.google.com/)
   - Seleccionar proyecto: **corralx-777-aipp**
   - Ir a **Configuración del proyecto** → **Service accounts**
   - Clic en **Generate new private key**
   - Descargar el archivo JSON

2. **Subir al backend:**
   ```bash
   cd CorralX-Backend
   cp ~/Downloads/corralx-777-aipp-firebase-adminsdk-xxxxx.json storage/app/
   ```

3. **Actualizar `.env` del backend:**
   ```env
   FIREBASE_CREDENTIALS=storage/app/corralx-777-aipp-firebase-adminsdk-xxxxx.json
   FIREBASE_DATABASE_URL=https://corralx-777-aipp-default-rtdb.firebaseio.com
   FIREBASE_STORAGE_BUCKET=corralx-777-aipp.firebasestorage.app
   ```

4. **Limpiar caché:**
   ```bash
   php artisan config:clear
   php artisan cache:clear
   ```

---

### Opción 2: Actualizar frontend para usar el proyecto del backend

Si prefieres usar `corralx777` en ambos:

1. **Descargar `google-services.json` del proyecto `corralx777`**
2. **Reemplazar en frontend:** `android/app/google-services.json`
3. **Recompilar la app**

---

## 🔍 Verificación

Después de aplicar la solución:

1. **Verificar proyecto del backend:**
   ```bash
   cd CorralX-Backend
   php artisan tinker --execute="echo config('services.firebase.credentials');"
   ```

2. **Verificar que coincidan:**
   - Frontend: Project Number `332023551639`
   - Backend: Mismo Project Number en credenciales

3. **Probar notificación:**
   - Enviar un mensaje entre dos usuarios
   - Verificar que la notificación llegue

---

## 📝 Cambios Realizados

1. ✅ Corregido problema de conversión de `$snippet` (Stringable a string)
2. ✅ Corregido problema de conversión de `full_message` (Stringable a string)

---

## ⚠️ Nota Importante

**El proyecto de Firebase debe coincidir entre frontend y backend para que las notificaciones funcionen correctamente.**

El error "SenderId mismatch" se produce cuando:
- El token FCM fue generado con un Sender ID
- El backend intenta enviar con otro Sender ID diferente

