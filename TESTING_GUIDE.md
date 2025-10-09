# 🧪 GUÍA DE TESTING FINAL - MVP

## 📅 Fecha: 9 de Octubre 2025, 23:50

---

## 📱 **DISPOSITIVOS LISTOS:**

```
✅ D1 (192.168.27.3): PID 17345
✅ D2 (192.168.27.4): PID 18929
```

**Estado:** Apps abiertas y corriendo

---

## 🧪 **TEST 1: MENSAJE APARECE Y NO DESAPARECE**

### 📋 **Pasos:**

1. **D1:** Abre la app
2. **D1:** Ve a "Mensajes" (ícono de chat en bottom nav)
3. **D1:** Abre conversación 687 (o cualquier conversación)
4. **D1:** Escribe mensaje: "Test 1 - Mensaje no desaparece"
5. **D1:** Presiona enviar ✅

### ✅ **Resultado Esperado:**

```
D1 (INMEDIATO):
✅ Mensaje aparece INMEDIATAMENTE
✅ Muestra estado "Enviando..." (icono gris)
✅ En ~1 segundo cambia a "Enviado" (check verde)
✅ Mensaje NO desaparece en ningún momento
✅ Mensaje permanece visible
```

### ❌ **Si falla:**

```
❌ Mensaje desaparece después de aparecer
❌ Mensaje tarda más de 2 segundos en aparecer
❌ Aparece error "Failed to send"
```

**Reportar:** "Test 1 FALLÓ: [descripción del error]"

---

## 🧪 **TEST 2: MENSAJES BIDIRECCIONALES (D1 ↔ D2)**

### 📋 **Pasos:**

1. **D1 y D2:** Ambos abren la MISMA conversación (ej: conversación 687)
2. **D1:** Envía mensaje: "Hola desde D1" ✅
3. **Espera:** 4-5 segundos
4. **D2:** Verifica si apareció el mensaje
5. **D2:** Envía respuesta: "Hola desde D2" ✅
6. **Espera:** 4-5 segundos
7. **D1:** Verifica si apareció la respuesta

### ✅ **Resultado Esperado:**

```
D1 → D2:
[D1] Envía "Hola desde D1"
[D1] Mensaje aparece inmediatamente ✅
[D2] Espera 4-5 segundos
[D2] Mensaje aparece en chat ✅

D2 → D1:
[D2] Envía "Hola desde D2"
[D2] Mensaje aparece inmediatamente ✅
[D1] Espera 4-5 segundos
[D1] Mensaje aparece en chat ✅
```

### ⏱️ **Latencia Aceptable:**

- **Propio dispositivo:** Inmediato (<1s)
- **Otro dispositivo:** 4-6 segundos (HTTP Polling)

### ❌ **Si falla:**

```
❌ Mensaje no aparece en D2 después de 10 segundos
❌ Mensaje aparece duplicado
❌ Orden de mensajes incorrecto
```

**Reportar:** "Test 2 FALLÓ: [descripción]"

---

## 🧪 **TEST 3: MÚLTIPLES MENSAJES CONSECUTIVOS**

### 📋 **Pasos:**

1. **D1:** Abre conversación
2. **D1:** Envía 3 mensajes seguidos (sin esperar):
   - "Mensaje 1"
   - "Mensaje 2"
   - "Mensaje 3"
3. **D1:** Verifica que los 3 aparezcan inmediatamente
4. **D2:** Espera 4-5 segundos
5. **D2:** Verifica que aparezcan los 3 mensajes

### ✅ **Resultado Esperado:**

```
D1 (envío):
✅ Los 3 mensajes aparecen INMEDIATAMENTE
✅ En orden correcto (1, 2, 3)
✅ Todos con estado "Enviando..." → "Enviado"
✅ Ninguno desaparece

D2 (recepción):
✅ En 4-5 segundos aparecen LOS 3 JUNTOS
✅ En orden correcto (1, 2, 3)
✅ Todos con check verde
```

### ❌ **Si falla:**

```
❌ Algún mensaje desaparece
❌ Mensajes en orden incorrecto
❌ Solo aparecen 1 o 2 mensajes (falta alguno)
❌ Mensajes duplicados
```

**Reportar:** "Test 3 FALLÓ: [descripción]"

---

## 🔍 **MONITOREO DE LOGS (OPCIONAL):**

Si quieres ver logs en tiempo real mientras haces los tests:

### Para D1:
```bash
adb -s 192.168.27.3:5555 logcat --pid=17345 | grep -iE "polling|chatprovider|mensaje|optimistic|merge"
```

### Para D2:
```bash
adb -s 192.168.27.4:5555 logcat --pid=18929 | grep -iE "polling|chatprovider|mensaje|optimistic|merge"
```

### Logs esperados (D1 envía):
```
📤 ChatProvider.sendMessage - ConvID: 687
🔄 Optimistic: Mensaje agregado localmente
✅ Mensaje enviado exitosamente - ID: 1234
🔍 Polling: Consultando mensajes de conv 687
📥 Polling: Actualización recibida - 51 mensajes
📨 1 mensaje(s) nuevo(s) detectado(s)
```

### Logs esperados (D2 recibe):
```
🔍 Polling: Consultando mensajes de conv 687
📥 Polling: Actualización recibida - 51 mensajes
📨 1 mensaje(s) nuevo(s) detectado(s)
```

---

## 📊 **CHECKLIST DE VALIDACIÓN:**

### ✅ **Funcionalidades Core:**
- [ ] Enviar mensaje (aparece inmediato)
- [ ] Mensaje NO desaparece
- [ ] Check verde aparece (~1s)
- [ ] Otro dispositivo recibe (~4s)
- [ ] Múltiples mensajes en orden
- [ ] Sin duplicados
- [ ] Sin pérdida de mensajes

### ⚠️ **Limitaciones Conocidas (Esperadas):**
- [ ] Typing "está escribiendo..." NO aparece (correcto, no soportado)
- [ ] Latencia de 4-6 segundos entre dispositivos (correcto, HTTP Polling)

### ❌ **Errores que NO deben ocurrir:**
- [ ] HTTP 500 al enviar
- [ ] Mensajes que desaparecen
- [ ] Mensajes duplicados
- [ ] Orden incorrecto
- [ ] App se cierra (crash)

---

## 🎯 **CRITERIOS DE ACEPTACIÓN MVP:**

Para que el MVP sea **APROBADO**, los 3 tests deben pasar:

```
✅ Test 1: PASS - Mensaje aparece y NO desaparece
✅ Test 2: PASS - Mensajes bidireccionales funcionan
✅ Test 3: PASS - Múltiples mensajes en orden
```

**Si los 3 tests pasan:**
```
✅✅✅ MVP APROBADO
→ Listo para desplegar
```

**Si algún test falla:**
```
❌ MVP PENDIENTE
→ Corregir errores detectados
→ Re-testing
```

---

## 📝 **FORMATO DE REPORTE:**

Por favor reporta los resultados así:

```
🧪 RESULTADOS DE TESTING:

TEST 1: [PASS ✅ / FAIL ❌]
Detalles: [Mensaje apareció inmediatamente y no desapareció]

TEST 2: [PASS ✅ / FAIL ❌]
Detalles: [Mensajes entre D1 y D2 funcionaron con ~4s delay]

TEST 3: [PASS ✅ / FAIL ❌]
Detalles: [3 mensajes aparecieron en orden correcto]

ERRORES ENCONTRADOS:
- [Ninguno / Descripción de errores]

CONCLUSIÓN: [MVP APROBADO ✅ / MVP PENDIENTE ❌]
```

---

## 🚀 **¿LISTO PARA EMPEZAR?**

**Por favor realiza los 3 tests y reporta los resultados.**

Apps ya están corriendo:
- ✅ D1: PID 17345
- ✅ D2: PID 18929

**Empieza con Test 1** 🎯

