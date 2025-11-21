# 🔍 Usar SHA-1 del Upload Key para Todas las Compilaciones

## ❓ PREGUNTA

¿Qué pasa si uso el SHA-1 de mi Upload Key (`F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`) para las 3 tipos de compilación?

## 📋 RESPUESTA DIRECTA

**NO funcionará para AAB de Play Store** porque Google Play re-firma la app con su propia clave (Play Store ASK).

---

## 🔑 ¿QUÉ PASA CON CADA TIPO?

### 1. APK Debug Local
- **Keystore usado:** `~/.android/debug.keystore` (diferente al tuyo)
- **SHA-1 del debug keystore:** Diferente (no es tu `mykey.jks`)
- **Si configuras SHA-1 de Upload Key:** ❌ **NO funcionará** (clave diferente)

### 2. APK Release Local
- **Keystore usado:** `android/app/mykey.jks` (tu keystore)
- **SHA-1:** `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
- **Si configuras SHA-1 de Upload Key:** ✅ **Funcionará** (coincide exactamente)

### 3. AAB Play Store
- **AAB inicial:** Firmado con `mykey.jks` → SHA-1: `F8:F5:86:28:...` ✅
- **PERO Google Play re-firma:** Con Play Store ASK → SHA-1: `49:7F:A1:F3:...`
- **App que descarga el usuario:** Firmada con Play Store ASK
- **Si configuras SHA-1 de Upload Key:** ❌ **NO funcionará** (la app final está firmada con clave diferente)

---

## 📊 COMPARACIÓN

| Configuración | APK Debug Local | APK Release Local | AAB Play Store |
|---------------|----------------|-------------------|----------------|
| **SHA-1 Upload Key** (`F8:F5:86:28:...`) | ❌ No funciona | ✅ Funciona | ❌ No funciona |
| **SHA-1 Play Store ASK** (`49:7F:A1:F3:...`) | ❌ No funciona | ⚠️ Puede funcionar | ✅ Funciona |

---

## 🎯 CONCLUSIÓN

**Si usas solo el SHA-1 de tu Upload Key:**
- ✅ **APK Release Local:** Funcionará
- ❌ **AAB Play Store:** NO funcionará (crítico para producción)
- ❌ **APK Debug Local:** NO funcionará (pero no es crítico)

**Problema principal:** Play Store no funcionará, que es tu prioridad para producción.

---

## ✅ SOLUCIÓN IDEAL

### Opción 1: SHA-1 de Play Store (Recomendada para Producción)

**Configura:**
- SHA-1: `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68` (Play Store ASK)

**Resultado:**
- ✅ AAB Play Store: Funciona (prioridad principal)
- ⚠️ APK Local: Puede funcionar (depende del Consent Screen)

---

### Opción 2: Múltiples SHA-1 (Si Google Cloud Console lo permite)

**Configura AMBOS:**
1. `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4` (Upload Key)
2. `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68` (Play Store ASK)

**Resultado:**
- ✅ APK Release Local: Funciona
- ✅ AAB Play Store: Funciona
- ⚠️ APK Debug Local: Puede funcionar

**Problema:** Google Cloud Console puede no permitir múltiples SHA-1.

---

## 💡 RECOMENDACIÓN FINAL

**Para tu caso de uso (producción en Play Store):**

1. **Usa SHA-1 de Play Store ASK** (`49:7F:A1:F3:...`)
   - ✅ Play Store funcionará (objetivo principal)
   - ⚠️ Desarrollo local puede requerir configuraciones adicionales

2. **NO uses solo SHA-1 de Upload Key**
   - ❌ Play Store NO funcionará (problema crítico)
   - ✅ Solo APK Release local funcionará

---

## 🚫 POR QUÉ NO FUNCIONA EN PLAY STORE CON UPLOAD KEY

Cuando subes un AAB a Play Store:

1. **Tú firmas el AAB** con tu `mykey.jks` (Upload Key)
   - SHA-1: `F8:F5:86:28:...`
   - ✅ Google Play acepta el AAB porque lo firmaste con tu clave

2. **Google Play re-firma la app** con su propia App Signing Key (ASK)
   - SHA-1: `49:7F:A1:F3:...`
   - Esta es la clave que usa para distribuir la app a usuarios

3. **El usuario descarga la app** firmada con Play Store ASK
   - SHA-1: `49:7F:A1:F3:...` (NO tu Upload Key)
   - Si solo tienes tu Upload Key configurado, OAuth NO funcionará

---

## 📝 RESUMEN COMPARATIVO

### Escenario 1: Solo SHA-1 Upload Key
```
Configuración: F8:F5:86:28:... (tu Upload Key)

✅ APK Release Local: Funciona
❌ AAB Play Store: NO funciona (crítico)
❌ APK Debug Local: NO funciona (no crítico)
```

### Escenario 2: Solo SHA-1 Play Store ASK (Recomendado)
```
Configuración: 49:7F:A1:F3:... (Play Store ASK)

✅ AAB Play Store: Funciona (prioridad)
⚠️ APK Release Local: Puede funcionar
❌ APK Debug Local: NO funciona (no crítico)
```

### Escenario 3: Ambos SHA-1 (Ideal, si es posible)
```
Configuración: F8:F5:86:28:... + 49:7F:A1:F3:...

✅ APK Release Local: Funciona
✅ AAB Play Store: Funciona
⚠️ APK Debug Local: Puede funcionar
```

---

**¿Cuál elegir?**

- **Producción (Play Store):** Usa SHA-1 de Play Store ASK
- **Desarrollo local:** Puedes usar métodos alternativos o configuraciones adicionales
- **Ideal:** Ambos SHA-1 si Google Cloud Console lo permite

---

**Conclusión:** NO uses solo el SHA-1 de tu Upload Key si quieres que Play Store funcione. Usa el SHA-1 de Play Store ASK para producción.


