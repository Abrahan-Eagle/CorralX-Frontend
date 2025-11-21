# 🔍 Explicación: SHA-1 por Tipo de Compilación

## ❓ PREGUNTA

¿Puedo usar el SHA-1 de Play Store (generado por Google) para las 3 tipos de compilación?

## 📋 RESPUESTA DIRECTA

**NO.** Cada tipo de compilación usa una clave diferente, por lo que necesita un SHA-1 diferente.

---

## 🔑 ¿QUÉ CLAVE SE USA EN CADA COMPILACIÓN?

### 1. APK Debug Local
- **Keystore usado:** `~/.android/debug.keystore` (keystore por defecto de Android)
- **SHA-1:** Diferente (no es tu `mykey.jks`)
- **Se firma con:** La clave de debug por defecto de Android Studio

### 2. APK Release Local
- **Keystore usado:** `android/app/mykey.jks` (tu keystore de producción)
- **SHA-1:** `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
- **Se firma con:** Tu clave de carga (Upload Key)

### 3. AAB Release para Play Store
- **Keystore usado para firmar AAB:** `android/app/mykey.jks` (tu keystore)
- **SHA-1 del AAB inicial:** `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4`
- **PERO luego Google Play re-firma la app** con su propia clave:
  - **SHA-1 después de re-firmado:** `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68`
- **Se firma con:** Play Store App Signing Key (ASK) de Google

---

## 🎯 ¿QUÉ SHA-1 NECESITAS EN CADA CASO?

| Tipo de Compilación | SHA-1 Necesario | ¿Por qué? |
|---------------------|-----------------|-----------|
| **APK Debug Local** | SHA-1 del keystore de debug por defecto | El APK está firmado con ese keystore |
| **APK Release Local** | `F8:F5:86:28:...` (Tu Upload Key) | El APK está firmado con `mykey.jks` |
| **AAB Play Store** | `49:7F:A1:F3:...` (Play Store ASK) | Google Play re-firma con su propia clave |

---

## ✅ SOLUCIÓN RECOMENDADA

### Opción 1: Configurar MÚLTIPLES SHA-1 (Mejor)

**En Google Cloud Console:**
- Configura **AMBOS** SHA-1 en el mismo OAuth Client ID:
  1. `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4` (Upload Key - para APK local)
  2. `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68` (Play Store ASK - para AAB)

**Problema:** Google Cloud Console puede no permitir múltiples SHA-1 en un solo OAuth Client ID.

---

### Opción 2: Usar Solo SHA-1 de Play Store (Producción)

**Configuración:**
- Solo configura: `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68`

**Resultado:**
- ✅ **AAB Play Store:** Funcionará perfectamente
- ✅ **APK Release Local:** Puede funcionar si el OAuth Consent Screen está publicado y no requiere verificación estricta de SHA-1
- ❌ **APK Debug Local:** Probablemente NO funcionará (usa keystore diferente)

**Ventaja:** Play Store funcionará (prioridad principal)

**Desventaja:** Desarrollo local puede tener problemas

---

### Opción 3: Dos OAuth Client IDs (Complejo pero Flexible)

**Configuración:**
1. OAuth Client ID 1: Solo SHA-1 de Upload Key → Para desarrollo local
2. OAuth Client ID 2: Solo SHA-1 de Play Store → Para Play Store

**Implementación:**
- Necesitas configurar `build.gradle` para usar diferentes `google-services.json` según el build type
- O configurar AndroidManifest dinámicamente según el build variant

**Ventaja:** Funciona en todos los casos

**Desventaja:** Configuración más compleja

---

## 💡 MI RECOMENDACIÓN

**Para tu caso (producción):**

1. **Configura el OAuth Client ID con el SHA-1 de Play Store ASK:**
   ```
   49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68
   ```

2. **Para desarrollo local:**
   - Si el OAuth Consent Screen está **publicado**, puede funcionar sin verificar SHA-1 estrictamente
   - Si está en modo **"Testing"**, agrega tu email como test user
   - Si no funciona, puedes probar con APK sin Google Sign-In en local, o usar otro método de autenticación para desarrollo

3. **Para Play Store:**
   - Con el SHA-1 de Play Store ASK configurado, funcionará perfectamente ✅

---

## 🧪 PRUEBA ESTO PRIMERO

### Configuración Simple (Recomendada para empezar):

1. **Google Cloud Console:**
   - Configura SOLO el SHA-1 de Play Store: `49:7F:A1:F3:3D:89:04:95:57:F1:04:B9:5B:E5:43:CE:5E:BF:C3:68`

2. **Firebase:**
   - Ya tienes los 3 fingerprints agregados ✅ (está bien)

3. **Descarga nuevo google-services.json:**
   - Descarga de Firebase y reemplaza en tu proyecto

4. **Prueba:**
   - **AAB Play Store:** Debería funcionar ✅
   - **APK Local:** Puede funcionar dependiendo del Consent Screen

**Si el APK local NO funciona:**
- Verifica que el OAuth Consent Screen tenga tu email como test user
- O considera usar solo para Play Store (producción es la prioridad)

---

## 📝 RESUMEN

| Escenario | SHA-1 de Play Store ÚNICO | SHA-1 Upload Key + Play Store |
|-----------|---------------------------|-------------------------------|
| **AAB Play Store** | ✅ Funciona | ✅ Funciona |
| **APK Release Local** | ⚠️ Puede funcionar | ✅ Funciona |
| **APK Debug Local** | ❌ Probablemente no | ⚠️ Puede funcionar |
| **Complejidad** | ✅ Simple | ⚠️ Complejo (si no permite múltiples) |

---

## 🎯 CONCLUSIÓN

**SÍ, puedes usar solo el SHA-1 de Play Store**, pero:
- ✅ Funcionará para **Play Store** (prioridad)
- ⚠️ Puede no funcionar para **desarrollo local**
- 💡 Recomendación: Úsalo solo si Play Store es tu prioridad y estás dispuesto a usar métodos alternativos para desarrollo local

**La mejor solución sería tener ambos SHA-1 configurados**, pero si Google Cloud Console no lo permite, usa el de Play Store para producción.

---

**¿Quieres que probemos primero con solo el SHA-1 de Play Store y vemos si el APK local funciona?**


