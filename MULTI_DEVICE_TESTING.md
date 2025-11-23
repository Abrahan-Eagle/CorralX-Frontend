# 📱 Guía de Testing Multi-Dispositivo - CorralX

Esta guía explica cómo compilar y ejecutar la app en **dos dispositivos simultáneamente** para probar funcionalidades como el chat en tiempo real.

---

## 🎯 Objetivo

Compilar la app en dos celulares al mismo tiempo para poder:
- ✅ Probar chat en tiempo real entre dos usuarios
- ✅ Ver mensajes en ambos dispositivos simultáneamente
- ✅ Verificar notificaciones push
- ✅ Probar funcionalidades que requieren interacción entre usuarios
- ✅ Monitorear logs de ambos dispositivos

---

## 📋 Requisitos Previos

1. **Dos dispositivos Android conectados** a la misma red:
   - Dispositivo 1: `192.168.27.8:5555`
   - Dispositivo 2: `192.168.27.5:5555`

2. **Verificar conexión:**
   ```bash
   adb devices
   ```

3. **Conectar dispositivos si no están conectados:**
   ```bash
   adb connect 192.168.27.8:5555
   adb connect 192.168.27.5:5555
   ```

---

## 🚀 Métodos de Ejecución

### Método 1: Script Automático (Recomendado)

El script `run_dual_devices.sh` ejecuta ambas instancias automáticamente y muestra logs de ambos dispositivos con colores diferentes.

**Uso:**
```bash
chmod +x run_dual_devices.sh
./run_dual_devices.sh
```

**Características:**
- ✅ Ejecuta ambas instancias en paralelo
- ✅ Logs con colores para distinguir cada dispositivo
- ✅ Guarda logs en archivos separados (`logs/device1_*.log`, `logs/device2_*.log`)
- ✅ Detiene ambas instancias con Ctrl+C

---

### Método 2: Dos Terminales Separadas (Más Control)

Este método te da más control sobre cada dispositivo individualmente.

#### Terminal 1 - Dispositivo 1:
```bash
chmod +x run_dual_devices_simple.sh
./run_dual_devices_simple.sh 1
```

O manualmente:
```bash
flutter run -d 192.168.27.8:5555 2>&1 | cat
```

#### Terminal 2 - Dispositivo 2:
```bash
./run_dual_devices_simple.sh 2
```

O manualmente:
```bash
flutter run -d 192.168.27.5:5555 2>&1 | cat
```

**Ventajas:**
- ✅ Puedes detener cada dispositivo independientemente
- ✅ Ver logs de cada dispositivo en terminal separada
- ✅ Más fácil identificar problemas específicos de un dispositivo

---

### Método 3: Background Processes

Ejecutar ambas instancias en segundo plano:

```bash
# Dispositivo 1 en background
flutter run -d 192.168.27.8:5555 > logs/device1.log 2>&1 &
PID1=$!
echo "Device 1 PID: $PID1"

# Dispositivo 2 en background
flutter run -d 192.168.27.5:5555 > logs/device2.log 2>&1 &
PID2=$!
echo "Device 2 PID: $PID2"

# Ver logs en tiempo real
tail -f logs/device1.log &
tail -f logs/device2.log

# Para detener ambos:
kill $PID1 $PID2
```

---

## 🔍 Monitoreo de Logs

### Ver logs en tiempo real de ambos dispositivos:

```bash
# Opción 1: Usar el script automático (muestra ambos con colores)
./run_dual_devices.sh

# Opción 2: Ver logs guardados
tail -f logs/device1_*.log logs/device2_*.log

# Opción 3: Buscar errores en ambos
grep -i "error\|exception\|failed" logs/device*.log
```

---

## 🐛 Troubleshooting

### Problema: "More than one device connected"

**Solución:** Especificar el dispositivo con `-d`:
```bash
flutter run -d 192.168.27.8:5555  # Dispositivo específico
```

### Problema: Dispositivo no conectado

**Solución:**
```bash
# Verificar dispositivos
adb devices

# Conectar dispositivo
adb connect 192.168.27.8:5555
adb connect 192.168.27.5:5555
```

### Problema: Puerto ocupado

**Solución:**
```bash
# Matar procesos de Flutter
pkill -f "flutter run"

# O matar proceso específico
kill <PID>
```

### Problema: Build falla en segundo dispositivo

**Solución:** Flutter puede tener problemas compilando en paralelo. Opciones:
1. Compilar primero en un dispositivo, luego en el otro
2. Usar dos máquinas diferentes
3. Esperar 10-15 segundos entre compilaciones

---

## 📊 Casos de Uso

### 1. Probar Chat en Tiempo Real

1. **Dispositivo 1:** Login como Usuario A
2. **Dispositivo 2:** Login como Usuario B
3. **Dispositivo 1:** Enviar mensaje a Usuario B
4. **Dispositivo 2:** Verificar recepción instantánea
5. **Dispositivo 2:** Responder
6. **Dispositivo 1:** Verificar respuesta

### 2. Probar Notificaciones Push

1. **Dispositivo 1:** Login como Usuario A
2. **Dispositivo 2:** Login como Usuario B
3. **Dispositivo 2:** Minimizar app (background)
4. **Dispositivo 1:** Enviar mensaje
5. **Dispositivo 2:** Verificar notificación recibida

### 3. Probar Marketplace

1. **Dispositivo 1:** Publicar producto
2. **Dispositivo 2:** Buscar y ver producto
3. **Dispositivo 2:** Contactar vendedor (Usuario A)
4. **Dispositivo 1:** Recibir notificación de mensaje

---

## 💡 Tips

1. **Colores en logs:** El script automático usa colores para distinguir dispositivos:
   - 🟢 Verde = Dispositivo 1
   - 🔵 Azul = Dispositivo 2

2. **Hot Reload:** Ambos dispositivos soportan hot reload simultáneamente:
   - Presiona `r` en la terminal para hot reload
   - Presiona `R` para hot restart

3. **Hot Restart:** Reinicia ambos dispositivos con:
   - `R` en cada terminal

4. **Debugging:** Usa breakpoints en VS Code/Cursor y ambos dispositivos se detendrán

5. **Performance:** Si la compilación es lenta, compila primero en un dispositivo, espera 30 segundos, luego compila en el segundo

---

## 🎯 Ejemplo de Sesión de Testing

```bash
# Terminal 1
$ ./run_dual_devices_simple.sh 1
[DEVICE 1] Compilando y ejecutando...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk (45.2MB).
Installing build/app/outputs/flutter-apk/app.apk...
[DEVICE 1] Flutter run key commands.
[DEVICE 1] r Hot reload. 🔥🔥🔥
[DEVICE 1] R Hot restart.
[DEVICE 1] h Repeat this help message.
[DEVICE 1] d Detach (terminate "flutter run" but leave application running).

# Terminal 2
$ ./run_dual_devices_simple.sh 2
[DEVICE 2] Compilando y ejecutando...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk (45.2MB).
Installing build/app/outputs/flutter-apk/app.apk...
[DEVICE 2] Flutter run key commands.
[DEVICE 2] r Hot reload. 🔥🔥🔥
[DEVICE 2] R Hot restart.
```

---

## ✅ Checklist de Testing

- [ ] Ambos dispositivos conectados (`adb devices`)
- [ ] App compilada en ambos dispositivos
- [ ] Usuarios diferentes logueados en cada dispositivo
- [ ] Chat funcionando en tiempo real
- [ ] Notificaciones push funcionando
- [ ] Logs monitoreados en ambas terminales
- [ ] Errores identificados y corregidos

---

**¿Listo para probar?** 🚀

Ejecuta: `./run_dual_devices.sh` o usa dos terminales con el método simple.

