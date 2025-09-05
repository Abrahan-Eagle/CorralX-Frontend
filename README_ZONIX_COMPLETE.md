# 📱 ZONIX - Sistema Integral de Gestión de Distribución de Gas Doméstico

## 🎯 Descripción del Proyecto

**ZONIX** es una plataforma integral de gestión de distribución de gas doméstico que controla el flujo completo desde la solicitud hasta la entrega de bombonas de gas, implementando reglas estrictas de control y distribución para prevenir abusos y garantizar una distribución eficiente.

### 🏗️ Arquitectura Técnica

- **Frontend**: Flutter 3.35.2 (Dart 3.9.0) - Aplicación móvil multiplataforma
- **Backend**: Laravel 10 (PHP 8.1+) - API REST con Sanctum para autenticación
- **Base de Datos**: MySQL - Gestión de usuarios, perfiles, tickets y estaciones
- **Autenticación**: Google Sign-In + Laravel Sanctum (JWT tokens)
- **Dispositivo**: Android 192.168.27.10:5555 (configuración fija)

### 🌐 URLs de Producción
- **Frontend**: https://zonix.aiblockweb.com
- **Backend**: https://zonix.aiblockweb.com/api
- **Laravel**: v10.48.22 (PHP v8.3.24)

---

## 🏭 MODELO DE NEGOCIO

### 🎯 Propósito Principal
ZONIX implementa un **sistema de control estricto** para la distribución de gas doméstico, garantizando:
- **Prevención de abusos** con reglas de tiempo y frecuencia
- **Gestión eficiente** de colas virtuales y físicas
- **Trazabilidad completa** del proceso de distribución
- **Control de capacidad** por estación y día

### 🏪 Infraestructura de Estaciones

#### **Configuración de Estaciones**
```php
// Características de las Estaciones
'days_available' => 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday'
'opening_time' => '09:00:00'
'closing_time' => '17:00:00'
'active' => true
'code' => 'CAR_LLD_001' // Códigos únicos por región
```

#### **Red de Estaciones**
- **12 estaciones** distribuidas en Carabobo, Valencia, Guacara
- **Horarios específicos** por día de la semana
- **Límite diario**: 200 citas por estación
- **Geolocalización** con coordenadas GPS precisas
- **Responsables asignados** por estación

### 🛢️ Gestión de Bombonas de Gas

#### **Tipos de Bombonas**
```php
// Configuración de Bombonas
'cylinder_type' => ['small', 'wide']
'cylinder_weight' => ['10kg', '18kg', '45kg']
'gas_cylinder_code' => 'CYL001' // Código único de fabricación
'approved' => true // Aprobación requerida antes de uso
```

#### **Validaciones de Bombonas**
- ✅ **Aprobación requerida** antes de uso
- ✅ **Código único** de fabricación
- ✅ **Fecha de fabricación** válida
- ✅ **Proveedor asociado** verificado

---

## 🔄 FLUJO DE TRABAJO COMPLETO

### 📋 FASE 1: CREACIÓN DE TICKET

#### **Reglas de Validación Implementadas**
```php
// Reglas de Negocio Críticas
1. Regla de 21 días para usuarios internos
2. Solo domingos para usuarios externos  
3. Límite diario de 200 tickets por estación
4. Validación de días disponibles por estación
5. Prevención de tickets duplicados
6. Asignación automática de posición en cola
```

#### **Proceso de Creación**
1. **Usuario autenticado** → Selecciona bombona de gas
2. **Sistema valida** → Reglas de negocio aplicadas
3. **Asignación automática** → Posición en cola (1-200)
4. **Generación QR** → Código único de bombona
5. **Programación** → Cita para siguiente día hábil

### 🔍 FASE 2: VERIFICACIÓN (SALES ADMIN)

#### **Estados del Ticket**
```php
// Flujo de Estados
'pending' → 'verifying' → 'waiting' → 'dispatched'
```

#### **Proceso Sales Admin**
1. **Escanear QR** → Validar bombona
2. **Verificar datos** → Documentos, teléfonos, direcciones
3. **Aprobar ticket** → Cambiar estado a `verifying`
4. **Marcar en espera** → Cambiar estado a `waiting`

### 🚚 FASE 3: DESPACHO (DISPATCHER)

#### **Endpoints de Despacho**
```http
POST /api/dispatch/tickets/{qrCodeId}/qr-code
POST /api/dispatch/tickets/{id}/dispatch
```

#### **Proceso Dispatcher**
1. **Escanear QR** → Buscar ticket en estado `waiting`
2. **Validar estado** → Confirmar que está listo
3. **Entregar bombona** → Marcar como `dispatched`
4. **Registro completo** → Historial actualizado

---

## 📊 REGLAS DE NEGOCIO IMPLEMENTADAS

### ⏰ Control de Tiempo
```php
// Regla de 21 días entre compras
$daysSinceLastAppointment = Carbon::now()->diffInDays($lastTicket->appointment_date);
if ($daysSinceLastAppointment < 21) {
    return response()->json(['message' => 'You must wait ' . (21 - $daysSinceLastAppointment) . ' more days']);
}
```

### 🌅 Control de Días
```php
// Solo domingos para usuarios externos
if ($isExternal && !Carbon::now()->isSunday()) {
    return response()->json(['message' => 'External appointments are only allowed on Sundays']);
}
```

### 🏪 Control de Estaciones
```php
// Validación de días disponibles por estación
$currentDay = Carbon::now()->format('l'); // "Tuesday"
$daysAvailable = explode(',', $station->days_available);
if (!in_array($currentDay, $daysAvailable)) {
    return response()->json(['message' => 'Appointments are not allowed today']);
}
```

### 📈 Control de Capacidad
```php
// Límite diario de 200 tickets por estación
$dailyAppointments = GasTicket::whereDate('appointment_date', $appointmentDate)
    ->where('station_id', $stationId)
    ->count();

if ($dailyAppointments >= 200) {
    return response()->json(['message' => 'Daily appointment limit reached']);
}
```

---

## 👥 ROLES Y PERMISOS

### 👤 Usuario Regular
- ✅ Crear tickets de gas
- ✅ Ver historial personal
- ✅ Gestionar perfil completo
- ✅ Ver detalles de bombonas y estaciones
- ❌ No puede cambiar estados de tickets

### 🔍 Sales Admin (Administrador de Ventas)
- ✅ Verificar datos de usuarios
- ✅ Escanear códigos QR
- ✅ Cambiar estados: `pending` → `verifying` → `waiting`
- ✅ Aprobar/rechazar solicitudes
- ✅ Gestión de verificaciones de datos
- ❌ No puede despachar tickets

### 🚚 Dispatcher (Despachador)
- ✅ Escanear tickets para despacho
- ✅ Cambiar estado: `waiting` → `dispatched`
- ✅ Gestionar cola física
- ✅ Validar estado de tickets
- ❌ No puede verificar datos

---

## 🔐 Flujo de Autenticación
1. **Usuario no autenticado** → Inicia sesión con Google
2. **AuthController** → Valida y crea/actualiza usuario
3. **Token + Rol** → Se almacena en `flutter_secure_storage`
4. **Onboarding** → Si es nuevo usuario, completa perfil
5. **Main App** → Navegación según rol asignado

---

## 📋 API Endpoints Completa

### 🔐 Autenticación
```http
POST /api/auth/google
Content-Type: application/json
{
  "success": true,
  "token": "google_token",
  "data": "google_profile_data",
  "message": "Datos recibidos correctamente."
}

Response:
{
  "token": "sanctum_jwt_token",
  "user": {
    "id": 1,
    "role": "sales_admin|dispatcher|user",
    "completed_onboarding": 1
  }
}
```

```http
GET /api/auth/user
Authorization: Bearer {token}

Response:
{
  "id": 1,
  "google_id": "123456789",
  "role": "sales_admin",
  "name": "Usuario",
  "email": "usuario@example.com"
}
```

```http
POST /api/auth/logout
Authorization: Bearer {token}
```

### 🎫 Tickets de Gas
```http
GET /api/tickets/{userId}
Authorization: Bearer {token}

Response:
[
  {
    "id": 1,
    "profile_id": 4,
    "gas_cylinders_id": 4,
    "status": "pending",
    "queue_position": 1,
    "qr_code": "CYL-1934545464-4",
    "reserved_date": "2025-08-27",
    "appointment_date": "2025-08-28",
    "expiry_date": "2025-08-29",
    "profile": {
      "id": 4,
      "firstName": "Abraham",
      "lastName": "pulido",
      "station_id": 1,
      "phones": [...],
      "emails": [...],
      "documents": [...],
      "addresses": [...],
      "user": {...}
    },
    "station": {
      "code": "ST001"
    },
    "gas_cylinder": {
      "gas_cylinder_code": "CYL001",
      "cylinder_quantity": 1,
      "cylinder_type": "Propano",
      "cylinder_weight": "11kg"
    }
  }
]
```

```http
POST /api/tickets
Authorization: Bearer {token}
Content-Type: application/json
{
  "user_id": 1,
  "gas_cylinders_id": 4,
  "is_external": false,
  "station_id": 1
}
```

```http
GET /api/tickets/getGasCylinders/{userId}
GET /api/tickets/stations/getGasStations
```

### 👤 Perfiles
```http
GET /api/profiles/{id}
POST /api/profiles (multipart)
POST /api/profiles/{id} (multipart)
```

### 🔍 Verificación de Datos (Sales Admin)
```http
POST /api/data-verification/{profile_id}/update-status-check-scanner/profiles
Authorization: Bearer {token}
Content-Type: application/json
{
  "selectedOptionId": 1
}
```

### 🚚 Despacho (Dispatcher)
```http
POST /api/dispatch/tickets/{qrCodeId}/qr-code
POST /api/dispatch/tickets/{id}/dispatch
Authorization: Bearer {token}
```

---

## 🛠️ Configuración Local

### 📁 Estructura de Proyectos
```
/var/www/html/proyectos/AIPP/PRODUCCION/ZONIX/
├── zonix/                    # Frontend Flutter
│   ├── lib/
│   ├── android/
│   ├── pubspec.yaml
│   └── .env                  # API_URL_LOCAL=http://192.168.27.4:8000
└── zonix-backend/            # Backend Laravel
    ├── app/
    ├── routes/
    ├── database/
    └── .env                  # DB config + APP_URL
```

### 🔧 Configuración de Entornos

#### **Frontend (.env)**
```env
API_URL_LOCAL=http://192.168.27.4:8000
API_URL_PROD=https://zonix.aiblockweb.com
```

#### **Backend (.env)**
```env
APP_NAME=ZONIX
APP_ENV=local
APP_KEY=base64:47UxuoU+DDS8aGfqd2DOnYk9ChaPfyxR2M1oG8KfVxc=
APP_URL=https://zonix.aiblockweb.com
DB_DATABASE=zionix_BD
DB_USERNAME=su
DB_PASSWORD=123
```

### 📱 Configuración Android
```gradle
// Java 17 configurado correctamente
compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
}
kotlinOptions {
    jvmTarget = '17'
}
```

---

## 🚀 FUNCIONALIDADES IMPLEMENTADAS

### 🔄 Sistema de Refresh Automático
```dart
// Implementado en GasTicketListScreen
Timer.periodic(const Duration(seconds: 30), (timer) {
    if (mounted && _userId > 0) {
        _loadTickets(_userId);
    }
});
```

### 📱 Formato de Contacto Mejorado
```dart
// Formato correcto de teléfonos
String _formatPhoneNumber(List<String> operatorNames, List<String> phoneNumbers) {
    // Resultado: "0412 - 4352014"
}
```

### 🖼️ Gestión de Imágenes
```php
// URLs completas para producción
$baseUrl = env('APP_URL'); // https://zonix.aiblockweb.com
$profileData['photo_users'] = $baseUrl . '/storage/' . $path;
```

### 🛡️ ProGuard Rules Completas
```pro
// Reglas para release builds
-keep class io.flutter.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
```

---

## 📊 ESTADO ACTUAL DEL PROYECTO

### ✅ Funcionalidades Completadas
- **Autenticación Google** con roles y permisos
- **Gestión completa de perfiles** con datos personales
- **Sistema de tickets** con reglas de negocio
- **Verificación de datos** por Sales Admin
- **Despacho de tickets** por Dispatcher
- **Refresh automático** cada 30 segundos
- **Formato correcto** de números de teléfono
- **Gestión de imágenes** en producción
- **Configuración Android** optimizada

### 🎯 Puntos Críticos del Negocio

#### **✅ Fortalezas Identificadas**
1. **Control estricto** de distribución de gas
2. **Prevención de abuso** con regla de 21 días
3. **Gestión eficiente** de colas virtuales
4. **Trazabilidad completa** del proceso
5. **Roles bien definidos** con permisos específicos

#### **⚠️ Consideraciones de Negocio**
1. **Capacidad limitada** (200 tickets/día/estación)
2. **Dependencia de horarios** de estaciones
3. **Validación manual** por Sales Admin
4. **Proceso secuencial** que puede crear cuellos de botella

---

## 🎯 RECOMENDACIONES PARA MVP COMPLETO

### 🚨 **COMPONENTES CRÍTICOS FALTANTES**

#### **1. 🔔 Sistema de Notificaciones Push**
```dart
// ❌ FALTANTE: Notificaciones en tiempo real
- Notificaciones cuando el ticket cambia de estado
- Alertas de recordatorio de cita
- Notificaciones de expiración de tickets
- Alertas para Sales Admin y Dispatcher
```

**Impacto:** Sin notificaciones, los usuarios no saben cuándo su ticket está listo, causando pérdida de eficiencia.

#### **2. 💳 Sistema de Pagos**
```php
// ❌ FALTANTE: Procesamiento de pagos
- Integración con pasarelas de pago (Stripe, PayPal, MercadoPago)
- Pago por bombona de gas
- Facturación electrónica
- Comprobantes de pago
- Gestión de reembolsos
```

**Impacto:** Sin pagos, el sistema no puede generar ingresos ni completar el ciclo de negocio.

#### **3. 📊 Dashboard de Analytics y Reportes**
```php
// ❌ FALTANTE: Métricas de negocio
- Dashboard para administradores
- Reportes de ventas por estación
- Estadísticas de tickets por día/semana/mes
- Métricas de eficiencia operativa
- Reportes de usuarios activos
```

**Impacto:** Sin analytics, no hay visibilidad del rendimiento del negocio.

#### **4. 📧 Sistema de Emails Automáticos**
```php
// ❌ FALTANTE: Comunicación automática
- Confirmación de ticket creado
- Recordatorio de cita
- Notificación de cambio de estado
- Comprobante de entrega
- Emails de bienvenida
```

**Impacto:** Sin emails, la comunicación con usuarios es limitada.

#### **5. 🔍 Sistema de Búsqueda y Filtros**
```dart
// ❌ FALTANTE: Búsqueda avanzada
- Búsqueda de tickets por fecha
- Filtros por estado de ticket
- Búsqueda de usuarios por nombre
- Filtros por estación
- Historial de transacciones
```

**Impacto:** Sin búsqueda, la gestión de datos es ineficiente.

### ⚠️ **COMPONENTES IMPORTANTES FALTANTES**

#### **6. 🗺️ Geolocalización Avanzada**
```dart
// ❌ FALTANTE: Ubicación inteligente
- Detección automática de estación más cercana
- Mapa interactivo de estaciones
- Distancia y tiempo de viaje
- Rutas optimizadas
```

#### **7. 📱 Funcionalidades Offline**
```dart
// ❌ FALTANTE: Modo offline
- Sincronización cuando hay conexión
- Almacenamiento local de datos
- Funcionalidad básica sin internet
- Queue de acciones pendientes
```

#### **8. 🔐 Seguridad Avanzada**
```php
// ❌ FALTANTE: Seguridad robusta
- Rate limiting por IP
- Detección de fraudes
- Auditoría de acciones
- Encriptación de datos sensibles
- Backup automático
```

#### **9. 📋 Gestión de Inventario**
```php
// ❌ FALTANTE: Control de stock
- Stock de bombonas por estación
- Alertas de stock bajo
- Reabastecimiento automático
- Trazabilidad de bombonas
```

#### **10. 👥 Gestión de Usuarios Avanzada**
```php
// ❌ FALTANTE: Administración de usuarios
- Panel de administración
- Gestión de roles y permisos
- Bloqueo/desbloqueo de usuarios
- Historial de actividades
```

### 🎯 **PRIORIZACIÓN PARA MVP**

#### **🔥 CRÍTICO (MVP Mínimo)**
1. **Sistema de Notificaciones Push** - Esencial para la experiencia del usuario
2. **Sistema de Pagos** - Necesario para generar ingresos
3. **Dashboard Básico** - Para monitorear el negocio

#### **⚡ IMPORTANTE (MVP Completo)**
4. **Sistema de Emails** - Mejora la comunicación
5. **Búsqueda y Filtros** - Mejora la usabilidad
6. **Geolocalización** - Optimiza la experiencia

#### **📈 ESCALABLE (Post-MVP)**
7. **Funcionalidades Offline** - Mejora la confiabilidad
8. **Seguridad Avanzada** - Protege el negocio
9. **Gestión de Inventario** - Optimiza operaciones
10. **Panel de Administración** - Facilita la gestión

### 💡 **PLAN DE IMPLEMENTACIÓN**

#### **Fase 1: MVP Mínimo (2-3 semanas)**
```bash
# 1. Notificaciones Push
flutter pub add firebase_messaging
flutter pub add flutter_local_notifications

# 2. Sistema de Pagos
composer require stripe/stripe-php
flutter pub add flutter_stripe

# 3. Dashboard Básico
# Crear endpoints de analytics en Laravel
# Crear pantalla de dashboard en Flutter
```

#### **Fase 2: MVP Completo (4-6 semanas)**
```bash
# 4. Sistema de Emails
composer require laravel/mail
# Configurar templates de email

# 5. Búsqueda y Filtros
# Implementar en frontend y backend

# 6. Geolocalización
flutter pub add google_maps_flutter
```

#### **Fase 3: Escalabilidad (6-8 semanas)**
```bash
# 7. Funcionalidades Offline
flutter pub add connectivity_plus
flutter pub add sqflite

# 8. Seguridad Avanzada
composer require spatie/laravel-permission
composer require spatie/laravel-activitylog

# 9. Gestión de Inventario
# Crear modelos y migraciones para stock

# 10. Panel de Administración
# Crear interfaz web de administración
```

### 📋 **CHECKLIST DE IMPLEMENTACIÓN**

#### **MVP Mínimo**
- [ ] Configurar Firebase para notificaciones push
- [ ] Integrar pasarela de pagos (Stripe/PayPal)
- [ ] Crear endpoints de analytics básicos
- [ ] Implementar dashboard simple
- [ ] Configurar notificaciones locales

#### **MVP Completo**
- [ ] Configurar sistema de emails automáticos
- [ ] Implementar búsqueda y filtros avanzados
- [ ] Integrar mapas y geolocalización
- [ ] Crear reportes básicos
- [ ] Optimizar UX/UI

#### **Post-MVP**
- [ ] Implementar funcionalidades offline
- [ ] Mejorar seguridad y auditoría
- [ ] Crear sistema de inventario
- [ ] Desarrollar panel de administración
- [ ] Optimizar performance

---

## 🧪 Testing

### Backend Tests
```bash
# Ejecutar tests de reglas de negocio
php artisan test --filter=GasTicketBusinessRulesTest

# Ejecutar tests de creación de tickets
php artisan test --filter=CreateGasTicketTest
```

### Frontend Tests
```bash
# Ejecutar tests unitarios
flutter test test/unit/

# Ejecutar tests de reglas de negocio
flutter test test/unit/business_rules_test.dart
```

---

## 🚀 Comandos de Desarrollo

### Frontend
```bash
# Compilar para desarrollo
flutter run -d 192.168.27.10:5555

# Compilar para producción
flutter run --release -d 192.168.27.10:5555

# Limpiar y actualizar dependencias
flutter clean && flutter pub get

# Verificar estado
flutter doctor
```

### Backend
```bash
# Iniciar servidor local
php artisan serve --host=192.168.27.4 --port=8000

# Limpiar cache
php artisan config:cache
php artisan route:cache

# Ejecutar migraciones
php artisan migrate:fresh --seed
```

---

## 📈 Métricas de Rendimiento

### Frontend
- **Tamaño APK**: 153.5MB
- **Tiempo de compilación**: ~91 segundos
- **Refresh automático**: 30 segundos
- **Dispositivo**: Android 192.168.27.10:5555

### Backend
- **Rutas API**: 62 endpoints
- **Base de datos**: MySQL optimizada
- **Autenticación**: Sanctum JWT
- **CORS**: Configurado para producción

---

## 🔒 Seguridad

### Implementaciones de Seguridad
- ✅ **Autenticación JWT** con Sanctum
- ✅ **Validación de roles** en cada endpoint
- ✅ **Sanitización de inputs** en todos los formularios
- ✅ **ProGuard/R8** para ofuscación de código
- ✅ **HTTPS** en producción
- ✅ **CORS** configurado correctamente

### Manejo de Errores
- ✅ **Logs estructurados** para debugging
- ✅ **Mensajes de error** amigables al usuario
- ✅ **Validación de datos** en frontend y backend
- ✅ **Recuperación de errores** de red

---

## 📞 Soporte y Contacto

### Información del Proyecto
- **Nombre**: ZONIX - Sistema de Gestión de Gas Doméstico
- **Versión**: 1.0.0+1
- **Entorno**: Producción activa
- **Última actualización**: Diciembre 2024

### Estado del Sistema
- ✅ **Frontend**: Funcionando correctamente
- ✅ **Backend**: API estable y optimizada
- ✅ **Base de datos**: Configurada y funcionando
- ✅ **Autenticación**: Google Sign-In operativo
- ✅ **Despliegue**: Automatizado en producción

---

## 🎯 CONCLUSIÓN

**ZONIX implementa un modelo de negocio sólido y bien estructurado para la distribución controlada de gas doméstico:**

✅ **Control total** del flujo de distribución
✅ **Prevención de abusos** con reglas estrictas
✅ **Trazabilidad completa** del proceso
✅ **Roles bien definidos** con responsabilidades claras
✅ **Automatización inteligente** de colas y programación
✅ **Validación en múltiples puntos** del proceso

**El sistema está diseñado para manejar la distribución controlada de gas doméstico con eficiencia, seguridad y transparencia total del proceso, garantizando un servicio confiable y bien regulado.**

**Para convertirse en un MVP completo y escalable, se requiere la implementación de los componentes críticos identificados en las recomendaciones, especialmente el sistema de notificaciones push, pagos y analytics.**
