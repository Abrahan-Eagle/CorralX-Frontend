# 🔧 Cómo Agregar SHA-256 en Google Cloud Console

## ✅ Estado Actual (Visto en tu pantalla):
- **SHA-1 configurado:** `F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4` ✅
- **Package Name:** `com.corralx.app` ✅
- **Client ID:** `332023551639-bbhv3lmlbgeu9t7oap48k006m7uf0lkh.apps.googleusercontent.com` ✅

## ❌ Falta:
- **SHA-256:** `10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20`

---

## 📋 OPCIONES PARA AGREGAR SHA-256

### Opción 1: Campo Separado de SHA-256 (Más Común)

1. **En la misma página donde estás**, busca un campo adicional que diga:
   - **"Huella digital del certificado SHA-256"** o
   - **"SHA-256 certificate fingerprint"**

2. Si lo encuentras, simplemente:
   - Haz clic en el campo
   - Pega este SHA-256:
     ```
     10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20
     ```

---

### Opción 2: Agregar Múltiples Fingerprints en el mismo campo

1. **Si el campo SHA-1 permite múltiples valores:**
   - Puedes tener un botón **"+"** o **"ADD"** o **"Agregar"** cerca del campo SHA-1
   - Haz clic en ese botón
   - Se abrirá otro campo donde puedes pegar el SHA-256

2. O puedes **separar múltiples fingerprints con comas o líneas nuevas**

---

### Opción 3: En "Configuración avanzada"

1. **Desplázate hacia abajo** en la página
2. Busca la sección **"Configuración avanzada"** (que veo colapsada en tu imagen)
3. **Expande esa sección** (haz clic en la flecha o título)
4. Puede haber campos adicionales para SHA-256 ahí

---

### Opción 4: Editar el OAuth Client para agregar múltiples SHA

1. Si hay un botón **"Edit"** o **"Editar"** en la página
2. Puede haber una lista de fingerprints donde puedes agregar más
3. Busca algo como **"SHA certificate fingerprints"** (plural, no singular)

---

## 🔍 Si NO encuentras dónde agregar SHA-256:

### Verifica la versión de Google Cloud Console:

1. **Google Cloud Console puede tener versiones diferentes:**
   - Algunas versiones solo muestran SHA-1
   - Versiones más recientes permiten múltiples fingerprints

2. **Intenta esto:**
   - Haz clic en **"Editar"** o **"Edit"** si hay un botón
   - O intenta **eliminar el SHA-1 actual** y agregarlo nuevamente junto con SHA-256
   - O busca un botón **"Agregar huella digital"** o **"Add fingerprint"**

---

## 🧪 Alternativa: Si no puedes agregar SHA-256 directamente

Si Google Cloud Console no te permite agregar SHA-256 en la misma configuración:

### Opción A: Crear un segundo OAuth Client ID (NO recomendado)
- Podrías crear otro OAuth Client ID solo con SHA-256
- Pero esto complicaría las cosas

### Opción B: Contactar con Google Support
- Si tu versión de la consola no permite SHA-256
- Puede ser un problema de la interfaz

---

## ✅ Lo que DEBERÍAS ver después de agregar:

```
Huella digital del certificado SHA-1:
F8:F5:86:28:5A:02:6E:A5:72:4F:F7:37:1B:9A:99:94:3E:E2:28:B4

Huella digital del certificado SHA-256:
10:CF:23:0F:2E:E8:E5:9D:26:48:DD:39:8F:30:76:A2:73:1C:21:F0:32:A7:D0:F8:39:4A:0C:9D:DA:2C:47:20
```

---

## 💡 RECOMENDACIÓN:

1. **Primero**, desplázate hacia abajo en la página actual
2. **Busca** si hay otro campo de SHA-256 o un botón para agregar más fingerprints
3. **Revisa** la sección "Configuración avanzada" expandiéndola
4. **Si no encuentras nada**, intenta hacer clic en algún botón de **"Editar"** o **"Modificar"**

---

**¿Qué ves cuando haces scroll hacia abajo en esa página?** 
- ¿Hay más campos?
- ¿Hay botones para agregar más fingerprints?
- ¿Hay una sección de "Configuración avanzada" expandible?

Comparte lo que ves y te ayudo a encontrar exactamente dónde agregar el SHA-256.

