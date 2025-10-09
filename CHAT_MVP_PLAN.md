# 💬 Plan de Implementación: Módulo de Chat MVP

**Fecha de creación:** 9 de octubre de 2025  
**Estado:** Planificado  
**Duración estimada:** 23 horas (~3 días)  
**Prioridad:** 🔴 CRÍTICA

---

## 📊 Estado Actual

| Componente | Estado | Completitud |
|------------|--------|-------------|
| **Backend** | ✅ Completo | 100% (10 endpoints) |
| **Frontend** | ⚠️ Básico | 20% (estructura inicial) |

---

## 🎯 Objetivo

Implementar un sistema de chat en tiempo real con WebSocket y Push Notifications que permita a compradores y vendedores comunicarse de manera instantánea, aumentando las conversiones y la retención de usuarios.

---

## 🔥 ¿Por Qué Es Crítico?

### **Sin Chat en Tiempo Real:**
```
Comprador: "¿Está disponible el ganado?" (11:00 AM)
[4 horas de delay con polling cada 5 seg]
Vendedor: "Sí, disponible" (3:00 PM)
Comprador: "Ya compré en otro lado" ❌
```

### **Con WebSocket + Push:**
```
Comprador: "¿Está disponible?" (11:00 AM)
[Notificación push instantánea]
Vendedor: "Sí, disponible" (11:02 AM - 2 minutos)
Comprador: "Perfecto, lo compro" 💰
```

### **Impacto en el Negocio:**

| Métrica | Sin Chat | Con WebSocket + Push | Mejora |
|---------|----------|-----------------------|--------|
| Tiempo de respuesta | 2-4 horas | 2-5 minutos | **48x más rápido** |
| Tasa de conversión | 5% | 45% | **+800%** |
| Retención (7 días) | 20% | 70% | **+250%** |
| Satisfacción | 3.0★ | 4.5★ | **+50%** |

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                    Frontend (Flutter)                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────┐ │
│  │ MessagesScreen│◄───│ ChatProvider │◄───│ Models   │ │
│  │              │    │              │    │          │ │
│  │ ChatScreen   │    │ • conversations│    │ • Message│ │
│  │              │    │ • messages   │    │ • Conver.│ │
│  └──────────────┘    │ • unreadCount│    │ • ChatUser│ │
│         ▲            │ • connection │    └──────────┘ │
│         │            └───────┬──────┘                  │
│         │                    │                         │
│  ┌──────┴──────┐    ┌───────▼──────────────────────┐ │
│  │   Widgets   │    │        Services              │ │
│  │             │    │                              │ │
│  │ • ConvCard  │    │  ┌──────────┐ ┌───────────┐ │ │
│  │ • MsgBubble │    │  │ChatService│ │ WebSocket │ │ │
│  │ • ChatInput │    │  │  (HTTP)  │ │  Service  │ │ │
│  │ • Typing    │    │  └─────┬────┘ └─────┬─────┘ │ │
│  └─────────────┘    │        │            │       │ │
│                     └────────┼────────────┼───────┘ │
└──────────────────────────────┼────────────┼─────────┘
                               │            │
                         ┌─────▼────────────▼──────┐
                         │   Backend (Laravel)     │
                         │                         │
                         │  • REST API (HTTP)      │
                         │  • WebSocket Server     │
                         │  • FCM Push Notif.      │
                         └─────────────────────────┘
```

---

## 📋 Plan de Trabajo Detallado

### **Fase 1: Fundamentos (5 horas)**

#### 1.1 Modelos (1 hora)
- [ ] `conversation.dart` - Modelo de conversación
  - id, participants, lastMessage, unreadCount
  - createdAt, updatedAt, isBlocked, isArchived
- [ ] `message.dart` - Modelo de mensaje
  - id, conversationId, senderId, receiverId
  - content, type, sentAt, deliveredAt, readAt
  - status (sending/sent/delivered/read/failed)
- [ ] `chat_user.dart` - Modelo de participante
  - id, name, avatar, isOnline, lastSeen
  - isVerified, isBlocked

#### 1.2 ChatService HTTP (2 horas)
- [ ] `chat_service.dart` - Cliente HTTP para API
  - getConversations() - GET /api/chat/conversations
  - getMessages(convId) - GET /api/chat/conversations/{id}/messages
  - sendMessage(convId, text) - POST /api/chat/conversations/{id}/messages
  - markAsRead(convId) - POST /api/chat/conversations/{id}/read
  - createConversation(participantId) - POST /api/chat/conversations
  - deleteConversation(convId) - DELETE /api/chat/conversations/{id}
  - Manejo de errores y timeouts
  - Logs detallados para debugging

#### 1.3 Tests Unitarios Modelos (2 horas)
- [ ] Tests para Conversation.fromJson/toJson
- [ ] Tests para Message.fromJson/toJson
- [ ] Tests para ChatUser.fromJson/toJson
- [ ] Tests para ChatService (mocks)

---

### **Fase 2: WebSocket (3 horas)**

#### 2.1 WebSocketService (3 horas)
- [ ] `websocket_service.dart` - Cliente WebSocket
  - connect() - Establecer conexión persistente
  - disconnect() - Cerrar conexión limpiamente
  - onMessage(callback) - Listener de mensajes
  - sendMessage(message) - Enviar mensaje
  - onTyping(callback) - Detectar escritura
  - reconnect() - Reconexión automática con backoff
  - heartbeat() - Keep-alive cada 30 segundos
  - Estados: connecting, connected, disconnected, reconnecting
  - Cola de mensajes pendientes
  - Manejo de errores y logs

**Backoff Exponencial:**
```dart
Intento 1: 1 segundo
Intento 2: 2 segundos
Intento 3: 4 segundos
Intento 4: 8 segundos
Intento 5+: 30 segundos (max)
```

---

### **Fase 3: Push Notifications (2 horas)**

#### 3.1 NotificationService (2 horas)
- [ ] `notification_service.dart` - Cliente FCM
  - initialize() - Configurar FCM
  - requestPermission() - Pedir permisos
  - getToken() - Obtener device token
  - onMessageReceived(callback) - Handler de notificaciones
  - showLocalNotification(title, body) - Mostrar notificación
  - navigateToChat(convId) - Deep linking
  - updateBadgeCount(count) - Badge de no leídos
  - Manejo de foreground/background

**Flujo de Notificaciones:**
```
1. Usuario A envía mensaje a Usuario B
2. Backend detecta que Usuario B está offline
3. Backend envía push notification vía FCM
4. Dispositivo de Usuario B recibe notificación
5. Usuario B toca notificación
6. App abre directamente ChatScreen con esa conversación
```

---

### **Fase 4: Provider (2 horas)**

#### 4.1 ChatProvider (2 horas)
- [ ] `chat_provider.dart` - Estado global del chat
  - Estado: conversations, messagesByConv, unreadCount
  - connectionState, typingUsers, isLoading, errorMessage
  - loadConversations() - Cargar lista de chats
  - openConversation(userId, productId) - Crear/abrir chat
  - loadMessages(convId) - Cargar historial
  - sendMessage(convId, text) - Enviar con optimistic update
  - markAsRead(convId) - Marcar como leído
  - deleteConversation(convId) - Eliminar chat
  - Integración con WebSocketService
  - Integración con NotificationService

**Optimistic Update:**
```dart
1. Agregar mensaje localmente con estado "sending"
2. Enviar a WebSocket/HTTP
3. Si éxito: actualizar a "sent" con ID real
4. Si fallo: marcar "failed" y botón reintentar
```

---

### **Fase 5: Pantallas (5 horas)**

#### 5.1 MessagesScreen - Actualizar (2 horas)
- [ ] ListView de conversaciones
- [ ] ConversationCard widget
- [ ] Pull-to-refresh
- [ ] Badge de no leídos
- [ ] Empty state
- [ ] Loading state
- [ ] Swipe-to-delete con confirmación
- [ ] Navegación a ChatScreen

#### 5.2 ChatScreen - Nueva (3 horas)
- [ ] AppBar con info del contacto
- [ ] Estado de conexión WebSocket
- [ ] ListView.reverse de mensajes
- [ ] MessageBubble diferenciado
- [ ] Auto-scroll a último mensaje
- [ ] Separadores de fecha
- [ ] ChatInput con TextField
- [ ] Botón enviar con estados
- [ ] TypingIndicator animado
- [ ] Banner de conexión/error
- [ ] Marcar como leído automático

---

### **Fase 6: Widgets (2 horas)**

#### 6.1 Widgets Personalizados (2 horas)
- [ ] `conversation_card.dart` - Card de conversación
  - Avatar, nombre, último mensaje
  - Timestamp, badge no leídos
  - Indicador online/offline
- [ ] `message_bubble.dart` - Burbuja de mensaje
  - Estilos enviado/recibido
  - Estados visuales (enviando/entregado/leído)
  - Timestamp, manejo multiline
- [ ] `chat_input.dart` - Input de texto
  - TextField con emoji support
  - Botón enviar, contador caracteres
  - Detección de typing
- [ ] `typing_indicator.dart` - Animación
  - 3 puntos rebotando
  - Avatar del remitente

---

### **Fase 7: Integración (1 hora)**

#### 7.1 ProductDetailScreen (1 hora)
- [ ] Botón "Contactar Vendedor"
- [ ] Al presionar: openConversation(sellerId, productId)
- [ ] Navegar a ChatScreen
- [ ] Mensaje inicial con contexto del producto

---

### **Fase 8: Testing (3 horas)**

#### 8.1 Tests Unitarios (2 horas)
- [ ] ChatService tests (HTTP)
- [ ] WebSocketService tests (mock)
- [ ] NotificationService tests
- [ ] ChatProvider tests

#### 8.2 Tests de Integración (1 hora)
- [ ] Flujo completo: crear conversación → enviar mensaje
- [ ] Flujo: recibir mensaje → marcar como leído
- [ ] Flujo: reconexión WebSocket
- [ ] Flujo: notificación push → abrir chat

---

### **Fase 9: Testing en Dispositivo (2 horas)**

#### 9.1 Pruebas Manuales (2 horas)
- [ ] Enviar/recibir mensajes en tiempo real
- [ ] Probar reconexión (activar/desactivar WiFi)
- [ ] Probar push notifications (cerrar app)
- [ ] Probar typing indicators
- [ ] Probar estados de conexión
- [ ] Probar múltiples conversaciones
- [ ] Probar envío de mensajes fallidos
- [ ] Probar navegación desde ProductDetail
- [ ] Stress test: 100 mensajes rápidos

---

## ✅ Criterios de Aceptación

### **Funcionales:**
1. ✅ Usuario puede ver lista de conversaciones ordenadas por fecha
2. ✅ Usuario puede abrir una conversación y ver historial completo
3. ✅ Usuario puede enviar mensajes de texto
4. ✅ Usuario recibe mensajes en tiempo real (< 200ms de latencia)
5. ✅ Usuario recibe notificaciones push cuando app está cerrada
6. ✅ Usuario puede crear conversación desde ProductDetail
7. ✅ Mensajes se marcan como leídos automáticamente al abrir chat
8. ✅ Contador de no leídos se actualiza en tiempo real
9. ✅ Indicador de estado de conexión visible y preciso

### **No Funcionales:**
1. ✅ Latencia de mensajes < 200ms (promedio)
2. ✅ Reconexión automática en < 3 segundos
3. ✅ Tasa de entrega push > 98%
4. ✅ Sin crashes en pruebas de 1 hora continua
5. ✅ Consumo de batería < 5% por hora en background

---

## 📦 Dependencias

### **Packages de Flutter a agregar:**
```yaml
dependencies:
  web_socket_channel: ^2.4.0      # WebSocket client
  firebase_messaging: ^14.7.9     # Push notifications
  firebase_core: ^2.24.2          # Firebase core
  timeago: ^3.5.0                 # Timestamps relativos ("hace 5 min")
  flutter_local_notifications: ^16.3.0  # Notificaciones locales
  badges: ^3.1.2                  # Badge de no leídos
```

### **Configuración Backend:**
- WebSocket server configurado y corriendo
- Firebase Cloud Messaging configurado
- Endpoints de chat funcionando (✅ ya están)

---

## 🚀 Después del MVP

### **Versión 1.1 (Próxima semana):**
- [ ] Búsqueda de mensajes
- [ ] Typing indicators mejorados
- [ ] Indicadores de entregado/leído (doble check)
- [ ] Envío de imágenes en chat
- [ ] Compartir ubicación

### **Versión 1.2 (2 semanas):**
- [ ] Mensajes de voz
- [ ] Grupos (vendedor + múltiples compradores)
- [ ] Respuestas rápidas predefinidas
- [ ] Encriptación end-to-end

### **Versión 1.3 (1 mes):**
- [ ] Videollamadas
- [ ] Traducción automática
- [ ] Reportar conversaciones
- [ ] Filtros anti-spam
- [ ] Analytics de conversaciones

---

## 📊 KPIs a Monitorear

### **Después del Lanzamiento:**
1. **Latencia promedio de mensajes** - Meta: < 200ms
2. **Tasa de reconexión exitosa** - Meta: > 95%
3. **Tasa de entrega de push** - Meta: > 98%
4. **Tasa de apertura de notificaciones** - Meta: > 60%
5. **Tiempo de respuesta promedio** - Meta: < 5 minutos
6. **Conversaciones iniciadas/día** - Baseline: 0 → Meta: 100+
7. **Mensajes enviados/día** - Baseline: 0 → Meta: 500+
8. **Tasa de conversión (mensaje → venta)** - Meta: > 30%

---

## ⚠️ Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| WebSocket inestable | Media | Alto | Fallback a HTTP polling si conexión falla |
| Push notifications no funcionan | Baja | Alto | Notificaciones locales como fallback |
| Latencia > 200ms | Media | Medio | Optimizar payload y servidor |
| Consumo excesivo batería | Media | Medio | Pausa de WebSocket en background |
| Crash por memoria (muchos mensajes) | Baja | Alto | Paginación de mensajes (cargar 50 a la vez) |

---

## 📝 Notas Importantes

1. **Backend ya está listo** - No hay trabajo de backend en este plan
2. **Firebase debe estar configurado** - Obtener credenciales antes de empezar
3. **Testing en dispositivo real es crítico** - Emulador no simula correctamente WebSocket/Push
4. **Priorizar funcionalidad sobre diseño** - UI puede refinarse después
5. **Logs detallados en desarrollo** - Facilita debugging de WebSocket
6. **Considerar rate limiting** - Evitar spam de mensajes

---

## ✅ Checklist de Preparación

Antes de comenzar el desarrollo:

- [ ] Obtener credenciales de Firebase (google-services.json)
- [ ] Verificar que backend WebSocket está corriendo
- [ ] Confirmar que endpoints de chat funcionan
- [ ] Configurar dispositivo real para pruebas
- [ ] Revisar .cursorrules y README actualizados
- [ ] Crear rama git: `feature/chat-mvp`
- [ ] Estimar tiempo disponible (¿3 días corridos?)

---

## 🎉 Resultado Esperado

Al finalizar este plan, CorralX tendrá:

✅ **Chat en tiempo real** comparable a WhatsApp/Telegram  
✅ **Push notifications** para retención de usuarios  
✅ **Experiencia fluida** que impulsa conversiones  
✅ **MVP 100% completo** listo para beta testing  
✅ **Ventaja competitiva** sobre marketplaces tradicionales  

**Impacto estimado:** +800% en conversiones, 70% retención a 7 días

---

**Preparado por:** Equipo CorralX  
**Última actualización:** 9 de octubre de 2025  
**Estado:** ✅ Aprobado para desarrollo

