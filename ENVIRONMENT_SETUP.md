# Configuración de Entornos - Corral X Frontend

## 📋 Variables de Entorno

El proyecto está configurado para funcionar tanto en **desarrollo local** como en **producción** usando variables de entorno.

### 🔧 Configuración Actual

#### **Desarrollo Local:**
- **API URL:** `http://192.168.27.11:8000`
- **WebSocket:** `ws://10.152.173.87:6001`
- **Entorno:** `development`

#### **Producción:**
- **API URL:** `https://backend.corralx.com`
- **WebSocket:** `wss://backend.corralx.com`
- **Entorno:** `production`

### 🚀 Cómo Funciona

El servicio `OnboardingApiService` usa la clase `AppConfig` que:

1. **Lee las variables de entorno** del archivo `.env`
2. **Selecciona automáticamente** la URL correcta según el entorno
3. **Aplica timeouts configurados** para las llamadas HTTP
4. **Maneja errores de conexión** con fallbacks

### 📝 Variables Disponibles

```dart
// URLs de API
API_URL_LOCAL=http://192.168.27.11:8000
API_URL_PROD=https://backend.corralx.com

// WebSockets
WS_URL_LOCAL=ws://10.152.173.87:6001
WS_URL_PROD=wss://backend.corralx.com

// Configuración de timeouts (millisegundos)
CONNECTION_TIMEOUT=30000
RECEIVE_TIMEOUT=30000
REQUEST_TIMEOUT=30000

// Entorno actual
ENVIRONMENT=development
```

### 🔄 Cambio de Entorno

Para cambiar entre desarrollo y producción:

1. **Editar `.env`:**
   ```bash
   # Para desarrollo
   ENVIRONMENT=development
   
   # Para producción
   ENVIRONMENT=production
   ```

2. **Recompilar la app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### ✅ Funcionamiento Verificado

- ✅ **Desarrollo local** - Conecta a `http://192.168.27.11:8000`
- ✅ **Producción** - Conecta a `https://backend.corralx.com`
- ✅ **Timeouts configurados** - 30 segundos por defecto
- ✅ **Manejo de errores** - Fallbacks a datos mock
- ✅ **Autenticación** - Preparado para tokens JWT
- ✅ **Subida de archivos** - Multipart requests

### 🔍 Debugging

Para verificar qué URL está usando:

```dart
print('API URL: ${AppConfig.apiUrl}');
print('Base URL: ${AppConfig.apiBaseUrl}');
print('Entorno: ${AppConfig.environment}');
```

### 📱 Build para Producción

```bash
# Build para Android
flutter build apk --dart-define=ENVIRONMENT=production

# Build para iOS
flutter build ios --dart-define=ENVIRONMENT=production
```

### 🛠️ Configuración Adicional

Si necesitas cambiar las URLs, edita el archivo `.env` y reinicia la aplicación. El servicio se conectará automáticamente a la nueva configuración.
