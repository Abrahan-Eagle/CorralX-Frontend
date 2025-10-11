import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/chat/models/conversation.dart';
import 'package:zonix/chat/models/message.dart';
import 'package:zonix/chat/services/chat_service.dart';
import 'package:zonix/chat/services/pusher_service.dart'; // ✅ Pusher Channels (tiempo real)
import 'package:zonix/chat/services/polling_service.dart'; // ✅ HTTP Polling (fallback)
import 'package:zonix/profiles/providers/profile_provider.dart'; // ✅ Para obtener profileId

/// Provider global para gestión del chat
/// Maneja conversaciones, mensajes, HTTP Polling y notificaciones
///
/// MVP: Usa HTTP Polling en vez de WebSocket para evitar problemas
/// de autenticación de canales privados con Laravel Echo Server
class ChatProvider extends ChangeNotifier {
  // ============================================
  // ESTADO
  // ============================================

  /// Referencia al ProfileProvider para obtener el profileId actual
  ProfileProvider? _profileProvider;

  /// Lista de conversaciones del usuario
  List<Conversation> _conversations = [];
  List<Conversation> get conversations => _conversations;

  /// Mensajes organizados por conversación
  final Map<int, List<Message>> _messagesByConv = {};
  Map<int, List<Message>> get messagesByConv => _messagesByConv;

  /// Contador total de mensajes no leídos
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Indicador de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Indicador de envío de mensaje
  bool _isSending = false;
  bool get isSending => _isSending;

  /// Mensaje de error
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Usuarios que están escribiendo (por conversación)
  final Map<int, Set<int>> _typingUsers = {};

  /// Servicio de Pusher (principal - tiempo real)
  final PusherService _pusherService = PusherService();

  /// Servicio de Polling (fallback si Pusher falla)
  final PollingService _pollingService = PollingService();

  /// ID de conversación actualmente abierta (para marcar como leído automático)
  int? _activeConversationId;

  /// Indicador de servicio activo
  bool _isUsingPusher = false;
  bool get isUsingPusher => _isUsingPusher;
  bool get isUsingPolling => !_isUsingPusher;

  /// Estado de conexión
  bool get isConnected =>
      _isUsingPusher ? _pusherService.isConnected : _pollingService.isPolling;

  // ============================================
  // INICIALIZACIÓN
  // ============================================

  ChatProvider(this._profileProvider) {
    print('🚀 ChatProvider: Inicializando...');
    _initializeServices();
  }

  /// Inicializar servicios (Pusher con fallback a Polling)
  Future<void> _initializeServices() async {
    print('🔧 ChatProvider: Inicializando servicios...');

    // Verificar si Pusher está habilitado en .env
    final enablePusher = dotenv.env['ENABLE_PUSHER'] == 'true';

    if (enablePusher) {
      // Intentar inicializar Pusher primero
      print('🔗 Intentando conectar a Pusher Channels...');
      final pusherOk = await _pusherService.initialize();

      if (pusherOk) {
        _isUsingPusher = true;
        print('✅ ChatProvider: Usando Pusher Channels (tiempo real)');
        print('   - Mensajes instantáneos (<100ms)');
        print('   - Typing indicators activos');
      } else {
        print('⚠️ Pusher falló, usando HTTP Polling como fallback');
        _isUsingPusher = false;
        print('✅ ChatProvider: Usando HTTP Polling');
        print('⏱️ Intervalo: ${PollingService.pollingInterval} segundos');
      }
    } else {
      print('⚠️ Pusher deshabilitado en .env');
      _isUsingPusher = false;
      print('✅ ChatProvider: Usando HTTP Polling');
      print('⏱️ Intervalo: ${PollingService.pollingInterval} segundos');
    }

    print('✅ ChatProvider: Servicios inicializados');
  }

  // ============================================
  // CONVERSACIONES
  // ============================================

  /// CARGAR lista de conversaciones
  Future<void> loadConversations() async {
    print('🔍 ChatProvider.loadConversations iniciado');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final conversations = await ChatService.getConversations();

      _conversations = conversations;

      // Calcular total de no leídos
      _unreadCount = conversations.fold<int>(
        0,
        (sum, conv) => sum + conv.unreadCount,
      );

      print('✅ Conversaciones cargadas: ${conversations.length}');
      print('📊 Total no leídos: $_unreadCount');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando conversaciones: $e');
      _errorMessage = 'Error al cargar conversaciones';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// ABRIR o crear conversación con otro usuario
  Future<Conversation?> openConversation(
    int otherProfileId, {
    int? productId,
  }) async {
    print('➕ ChatProvider.openConversation - ProfileID: $otherProfileId');

    try {
      // 1. Verificar si ya existe conversación
      final existingConv = _conversations.firstWhere(
        (conv) =>
            conv.profile1Id == otherProfileId ||
            conv.profile2Id == otherProfileId,
        orElse: () => Conversation(
          id: -1,
          profile1Id: 0,
          profile2Id: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingConv.id != -1) {
        print('✅ Conversación existente encontrada: ${existingConv.id}');

        // Cargar mensajes si no están cargados
        if (!_messagesByConv.containsKey(existingConv.id)) {
          await loadMessages(existingConv.id);
        }

        // ✅ Iniciado automáticamente por ChatScreen

        return existingConv;
      }

      // 2. Crear nueva conversación
      print('➕ Creando nueva conversación...');
      final newConv = await ChatService.createConversation(otherProfileId);

      // Agregar a la lista
      _conversations.insert(0, newConv);

      // ✅ Polling se iniciará cuando se abra ChatScreen

      notifyListeners();

      print('✅ Nueva conversación creada: ${newConv.id}');
      return newConv;
    } catch (e) {
      print('❌ Error abriendo conversación: $e');
      _errorMessage = 'Error al abrir conversación';
      notifyListeners();
      return null;
    }
  }

  /// ELIMINAR conversación
  Future<void> deleteConversation(int conversationId) async {
    print('🗑️ ChatProvider.deleteConversation - ConvID: $conversationId');

    try {
      await ChatService.deleteConversation(conversationId);

      // Remover localmente
      _conversations.removeWhere((conv) => conv.id == conversationId);
      _messagesByConv.remove(conversationId);

      // Detener polling si está activo
      if (_pollingService.activeConversationId == conversationId) {
        _pollingService.stopPolling();
      }

      print('✅ Conversación eliminada localmente');
      notifyListeners();
    } catch (e) {
      print('❌ Error eliminando conversación: $e');
      _errorMessage = 'Error al eliminar conversación';
      notifyListeners();
      rethrow;
    }
  }

  // ============================================
  // MENSAJES
  // ============================================

  /// CARGAR mensajes de una conversación
  Future<void> loadMessages(int conversationId) async {
    print('📥 ChatProvider.loadMessages - ConvID: $conversationId');

    try {
      final messages = await ChatService.getMessages(conversationId);

      _messagesByConv[conversationId] = messages;

      print('✅ Mensajes cargados: ${messages.length}');
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando mensajes: $e');
      _errorMessage = 'Error al cargar mensajes';
      notifyListeners();
      rethrow;
    }
  }

  /// ENVIAR mensaje con optimistic update
  Future<void> sendMessage(int conversationId, String content) async {
    print('📤 ChatProvider.sendMessage - ConvID: $conversationId');
    print(
        '💬 Contenido: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');

    _isSending = true;
    notifyListeners();

    try {
      // 1. Optimistic update - Agregar mensaje localmente
      final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      final currentProfileId =
          _profileProvider?.myProfile?.id ?? 0; // ✅ Obtener profileId real

      final tempMessage = Message(
        id: tempId,
        conversationId: conversationId,
        senderId:
            currentProfileId, // ✅ Usar profileId real para alineación correcta
        content: content,
        type: MessageType.text,
        status: MessageStatus.sending,
        sentAt: DateTime.now(),
      );

      // Inicializar lista si no existe
      if (!_messagesByConv.containsKey(conversationId)) {
        _messagesByConv[conversationId] = [];
      }

      _messagesByConv[conversationId]!.add(tempMessage);
      notifyListeners();

      print('🔄 Optimistic: Mensaje agregado localmente');

      // 2. Enviar al servidor vía HTTP
      final realMessage =
          await ChatService.sendMessage(conversationId, content);

      // 3. Reemplazar mensaje temporal con el real evitando duplicados
      final messageList = _messagesByConv[conversationId]!;
      final tempIndex = messageList.indexWhere((m) => m.id == tempId);
      final existingIndexWithReal =
          messageList.indexWhere((m) => m.id == realMessage.id);

      if (existingIndexWithReal != -1) {
        // Ya llegó vía Pusher; eliminar el temporal si aún existe
        if (tempIndex != -1) {
          messageList.removeAt(tempIndex);
        }
      } else if (tempIndex != -1) {
        // Reemplazar el temporal por el real
        messageList[tempIndex] =
            realMessage.copyWith(status: MessageStatus.sent);
      } else {
        // Ni temporal ni existente: agregar el real de forma segura
        messageList.add(realMessage.copyWith(status: MessageStatus.sent));
      }

      // 4. Actualizar conversación con último mensaje
      _updateConversationLastMessage(conversationId, content);

      print('✅ Mensaje enviado exitosamente - ID: ${realMessage.id}');

      // 5. ✅ Forzar polling inmediato para sincronizar con servidor
      _pollingService.pollNow();

      _isSending = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error enviando mensaje: $e');

      // Marcar mensaje como fallido
      final messageList = _messagesByConv[conversationId];
      if (messageList != null && messageList.isNotEmpty) {
        final lastMessage = messageList.last;
        if (lastMessage.status == MessageStatus.sending) {
          final failedMessage =
              lastMessage.copyWith(status: MessageStatus.failed);
          messageList[messageList.length - 1] = failedMessage;
        }
      }

      _errorMessage = 'Error al enviar mensaje';
      _isSending = false;
      notifyListeners();
      rethrow;
    }
  }

  /// MARCAR conversación como leída
  Future<void> markAsRead(int conversationId) async {
    print('👁️ ChatProvider.markAsRead - ConvID: $conversationId');

    try {
      await ChatService.markAsRead(conversationId);

      // Actualizar mensajes localmente
      final messages = _messagesByConv[conversationId];
      if (messages != null) {
        for (var i = 0; i < messages.length; i++) {
          if (messages[i].readAt == null) {
            messages[i] = messages[i].copyWith(
              readAt: DateTime.now(),
              status: MessageStatus.read,
            );
          }
        }
      }

      // Actualizar contador de no leídos
      final conv = _conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => Conversation(
          id: -1,
          profile1Id: 0,
          profile2Id: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (conv.id != -1) {
        _unreadCount -= conv.unreadCount;
        if (_unreadCount < 0) _unreadCount = 0;

        // Actualizar conversación
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          _conversations[index] = conv.copyWith(unreadCount: 0);
        }
      }

      print('✅ Mensajes marcados como leídos');
      notifyListeners();
    } catch (e) {
      print('⚠️ Error marcando como leído: $e');
      // No crítico, no lanzar error
    }
  }

  // ============================================
  // MÉTODOS RELACIONADOS CON WEBSOCKET REMOVIDOS
  // Se usa HTTP Polling en su lugar
  // ============================================

  /// Verificar si alguien está escribiendo en una conversación
  bool isTypingInConversation(int conversationId) {
    return _typingUsers[conversationId]?.isNotEmpty ?? false;
  }

  /// Obtener nombres de usuarios escribiendo
  List<int> getTypingUsers(int conversationId) {
    return _typingUsers[conversationId]?.toList() ?? [];
  }

  /// ACTUALIZAR última actividad de conversación
  void _updateConversationLastMessage(int convId, String content) {
    final index = _conversations.indexWhere((c) => c.id == convId);

    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: content,
        lastMessageAt: DateTime.now(),
      );

      // Mover al principio de la lista
      final conv = _conversations.removeAt(index);
      _conversations.insert(0, conv);
    }
  }

  /// INCREMENTAR contador de no leídos
  void _incrementUnreadCount(int convId) {
    final index = _conversations.indexWhere((c) => c.id == convId);

    if (index != -1) {
      final currentUnread = _conversations[index].unreadCount;
      _conversations[index] =
          _conversations[index].copyWith(unreadCount: currentUnread + 1);

      _unreadCount++;
    }
  }

  /// ESTABLECER conversación activa (para marcar como leído automático)
  void setActiveConversation(int? conversationId) {
    _activeConversationId = conversationId;

    if (conversationId != null) {
      print('👁️ Conversación activa: $conversationId');
      markAsRead(conversationId);
    }
  }

  /// OBTENER mensajes de una conversación específica
  List<Message> getMessages(int conversationId) {
    return _messagesByConv[conversationId] ?? [];
  }

  /// REINTENTAR envío de mensaje fallido
  Future<void> retryFailedMessage(
      int conversationId, Message failedMessage) async {
    print('🔄 Reintentando envío de mensaje: ${failedMessage.id}');

    // Remover mensaje fallido
    final messageList = _messagesByConv[conversationId];
    if (messageList != null) {
      messageList.removeWhere((m) => m.id == failedMessage.id);
    }

    // Intentar enviar de nuevo
    await sendMessage(conversationId, failedMessage.content);
  }

  // ============================================
  // WEBSOCKET
  // ============================================

  /// SUSCRIBIRSE con HTTP Polling a una conversación
  Future<void> subscribeToConversation(int conversationId) async {
    _activeConversationId = conversationId;

    if (_isUsingPusher) {
      print('📡 ChatProvider: Suscribiendo a Pusher para conv $conversationId');

      try {
        final success = await _pusherService.subscribeToConversation(
          conversationId,
          onMessage: (message) {
            _handlePusherMessage(conversationId, message);
          },
          onTypingStarted: (userId, userName) {
            _handleTypingStarted(conversationId, userId);
          },
          onTypingStopped: (userId) {
            _handleTypingStopped(conversationId, userId);
          },
          onConnectionChange: (isConnected) {
            if (!isConnected) {
              print('⚠️ Pusher desconectado, activando fallback a Polling');
              _activatePollingFallback(conversationId);
            }
          },
        );

        if (success) {
          print('✅ Suscrito a Pusher exitosamente');
        } else {
          print('⚠️ Pusher falló, usando Polling como fallback');
          _activatePollingFallback(conversationId);
        }
      } catch (e) {
        print('❌ Error con Pusher: $e - Usando Polling');
        _activatePollingFallback(conversationId);
      }
    } else {
      print(
          '📡 ChatProvider: Iniciando HTTP Polling para conv $conversationId');
      _activatePollingFallback(conversationId);
    }
  }

  /// Activar HTTP Polling como fallback
  void _activatePollingFallback(int conversationId) {
    _isUsingPusher = false;
    _pollingService.startPolling(
      conversationId,
      onNewMessages: (messages) {
        _handlePollingUpdate(conversationId, messages);
      },
    );
    notifyListeners();
  }

  /// DESUSCRIBIRSE (detener polling/pusher)
  void unsubscribeFromConversation(int conversationId) {
    print('🛑 ChatProvider: Desuscribiendo de conv $conversationId');

    if (_isUsingPusher) {
      _pusherService.unsubscribe();
    }

    _pollingService.stopPolling();
    _activeConversationId = null;
  }

  /// Manejar mensaje recibido via Pusher
  void _handlePusherMessage(int conversationId, Message message) {
    print('📨 Pusher: Mensaje recibido - ID ${message.id}');

    final currentMessages = _messagesByConv[conversationId] ?? [];

    // Verificar si el mensaje ya existe (evitar duplicados)
    final exists = currentMessages.any((m) => m.id == message.id);

    if (!exists) {
      currentMessages.add(message);
      currentMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      _messagesByConv[conversationId] = currentMessages;
      notifyListeners();
      print('✅ Mensaje agregado via Pusher');
    }
  }

  /// Manejar typing started via Pusher
  void _handleTypingStarted(int conversationId, int userId) {
    print('⌨️ Pusher: Usuario $userId está escribiendo');

    _typingUsers[conversationId] ??= {};
    _typingUsers[conversationId]!.add(userId);
    notifyListeners();
  }

  /// Manejar typing stopped via Pusher
  void _handleTypingStopped(int conversationId, int userId) {
    print('⌨️ Pusher: Usuario $userId dejó de escribir');

    _typingUsers[conversationId]?.remove(userId);
    notifyListeners();
  }

  /// Manejar actualización de polling
  void _handlePollingUpdate(int conversationId, List<Message> messages) {
    print('📥 Polling: Actualización recibida - ${messages.length} mensajes');

    // ✅ MERGE INTELIGENTE: Preservar mensajes optimistas
    final currentMessages = _messagesByConv[conversationId] ?? [];

    // 1. Extraer mensajes optimistas (aún enviando)
    final optimisticMessages = currentMessages
        .where((m) =>
            m.status == MessageStatus.sending &&
            m.id.toString().startsWith('temp-'))
        .toList();

    // 2. Crear mapa de mensajes del servidor por ID
    final serverMessagesMap = {for (var msg in messages) msg.id: msg};

    // 3. Actualizar o agregar mensajes del servidor
    final updatedMessages = <Message>[];

    // Agregar todos los mensajes del servidor
    updatedMessages.addAll(messages);

    // Agregar mensajes optimistas que NO están en el servidor aún
    for (final optMsg in optimisticMessages) {
      updatedMessages.add(optMsg);
    }

    // 4. Ordenar por fecha (más antiguos primero)
    updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    // 5. Detectar si hay mensajes nuevos
    final previousCount = currentMessages.length;
    final newCount = messages.length;

    if (newCount > previousCount) {
      final diff = newCount - previousCount;
      print('📨 $diff mensaje(s) nuevo(s) detectado(s)');
    } else {
      print('💤 Polling: Sin mensajes nuevos');
    }

    // 6. Actualizar y notificar
    _messagesByConv[conversationId] = updatedMessages;
    notifyListeners();
  }

  /// Forzar actualización inmediata (para pull-to-refresh)
  Future<void> refreshMessages() async {
    print('🔄 ChatProvider: Refresh manual solicitado');
    await _pollingService.pollNow();
  }

  // ============================================
  // TYPING INDICATORS
  // ============================================

  /// NOTIFICAR que el usuario está escribiendo
  Future<void> notifyTyping(int conversationId, bool isTyping) async {
    if (isTyping) {
      await ChatService.notifyTypingStarted(conversationId);
    } else {
      await ChatService.notifyTypingStopped(conversationId);
    }
  }

  // ============================================
  // LIMPIAR Y DISPOSE
  // ============================================

  /// Limpiar estado
  void clear() {
    _conversations = [];
    _messagesByConv.clear();
    _unreadCount = 0;
    _typingUsers.clear();
    _activeConversationId = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    print('🧹 ChatProvider: Disposing...');
    _pollingService.dispose();
    super.dispose();
  }
}
