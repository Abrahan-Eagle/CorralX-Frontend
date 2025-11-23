# 🔍 Explicación de Errores Encontrados

---

## 1. ❌ Error: `E/FileUtils: err write to mi_exception_log`

**¿Qué es?**
- Error del **sistema operativo Android**, no de nuestra app
- Android intenta escribir logs internos del sistema a un archivo

**¿Por qué ocurre?**
- El sistema intenta escribir a `/data/user/0/com.corralx.app/files/mi_exception_log`
- Puede fallar por permisos o porque el directorio no existe
- Común en versiones antiguas de Android

**¿Es crítico?**
- ❌ **NO ES CRÍTICO** - No afecta la funcionalidad

---

## 2. ❌ Error: `E/open libmigui.so failed!`

**¿Qué es?**
- Librería específica de dispositivos **Xiaomi/MIUI**
- Se usa para funcionalidades avanzadas de UI

**¿Por qué ocurre?**
- Dispositivo **Redmi Note 9 Pro** (Xiaomi)
- La librería no está disponible en todas las versiones de MIUI

**¿Es crítico?**
- ❌ **NO ES CRÍTICO** - No afecta la funcionalidad

---

## 3. ❌ Notificaciones Push: "SenderId mismatch"

**PROBLEMA CRÍTICO ENCONTRADO:**

El error en los logs del backend muestra:
```
❌ Error enviando notificación push {"error":"SenderId mismatch"}
```

**¿Qué significa?**
- El **Sender ID** de Firebase no coincide entre el backend y el frontend
- Firebase rechaza las notificaciones porque el token FCM fue registrado con un Sender ID diferente

**Causa:**
- El `google-services.json` del frontend tiene un Sender ID
- El backend está usando credenciales de Firebase con un Sender ID diferente
- Los tokens FCM están vinculados al Sender ID del frontend, pero el backend intenta enviar con otro

**Solución necesaria:**
1. Verificar que ambos usen el mismo proyecto de Firebase
2. Asegurar que el Sender ID coincida
3. Verificar las credenciales del backend
