import 'package:flutter/material.dart';
import 'package:zonix/chat/models/conversation.dart';
import 'package:zonix/chat/models/message.dart';
import 'package:zonix/chat/services/chat_service.dart';
import 'package:zonix/chat/services/websocket_service.dart';
import 'package:zonix/chat/services/notification_service.dart';

/// Provider global para gestión del chat
/// Maneja conversaciones, mensajes, WebSocket y notificaciones
class ChatProvider extends ChangeNotifier {
  // ============================================
  // ESTADO
  // ============================================

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

  /// Estado de conexión WebSocket
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;
  WebSocketConnectionState get connectionState => _connectionState;

  /// Usuarios que están escribiendo (por conversación)
  final Map<int, Set<int>> _typingUsers = {};

  /// Servicio WebSocket
  final WebSocketService _websocketService = WebSocketService();

  /// ID de conversación actualmente abierta (para marcar como leído automático)
  int? _activeConversationId;

  // ============================================
  // INICIALIZACIÓN
  // ============================================

  ChatProvider() {
    print('🚀 ChatProvider: Inicializando...');
    _initializeServices();
  }

  /// Inicializar servicios (WebSocket y Notificaciones)
  Future<void> _initializeServices() async {
    print('🔧 ChatProvider: Inicializando servicios...');

    // Inicializar notificaciones locales
    await NotificationService.initialize();

    // Configurar callbacks de notificaciones
    NotificationService.onNotificationTap((conversationId) {
      print('🔔 Notificación tocada: conv $conversationId');
      // TODO: Navegar a ChatScreen con ese conversationId
    });

    // Conectar WebSocket
    await _websocketService.connect();

    // Configurar callbacks de WebSocket
    _websocketService.onMessage((message) {
      _handleIncomingMessage(message);
    });

    _websocketService.onTyping((convId, userId, isTyping) {
      _handleTypingEvent(convId, userId, isTyping);
    });

    _websocketService.onConnectionChange((state) {
      _connectionState = state;
      notifyListeners();
    });

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

        // Suscribirse al canal WebSocket
        await _websocketService.subscribeToConversation(existingConv.id);

        return existingConv;
      }

      // 2. Crear nueva conversación
      print('➕ Creando nueva conversación...');
      final newConv = await ChatService.createConversation(otherProfileId);

      // Agregar a la lista
      _conversations.insert(0, newConv);

      // Suscribirse al canal
      await _websocketService.subscribeToConversation(newConv.id);

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

      // Desuscribirse del canal
      _websocketService.unsubscribeFromConversation(conversationId);

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
    print('💬 Contenido: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');

    _isSending = true;
    notifyListeners();

    try {
      // 1. Optimistic update - Agregar mensaje localmente
      final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = Message(
        id: tempId,
        conversationId: conversationId,
        senderId: 0, // TODO: Obtener del AuthProvider
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
      final realMessage = await ChatService.sendMessage(conversationId, content);

      // 3. Reemplazar mensaje temporal con el real
      final messageList = _messagesByConv[conversationId]!;
      final tempIndex = messageList.indexWhere((m) => m.id == tempId);

      if (tempIndex != -1) {
        messageList[tempIndex] = realMessage.copyWith(status: MessageStatus.sent);
      }

      // 4. Actualizar conversación con último mensaje
      _updateConversationLastMessage(conversationId, content);

      print('✅ Mensaje enviado exitosamente - ID: ${realMessage.id}');

      _isSending = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error enviando mensaje: $e');

      // Marcar mensaje como fallido
      final messageList = _messagesByConv[conversationId];
      if (messageList != null && messageList.isNotEmpty) {
        final lastMessage = messageList.last;
        if (lastMessage.status == MessageStatus.sending) {
          final failedMessage = lastMessage.copyWith(status: MessageStatus.failed);
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

  /// MANEJAR mensaje entrante desde WebSocket
  void _handleIncomingMessage(Message message) {
    print('📨 Mensaje WebSocket recibido: ${message.id}');

    final convId = message.conversationId;

    // Inicializar lista si no existe
    if (!_messagesByConv.containsKey(convId)) {
      _messagesByConv[convId] = [];
    }

    // Agregar mensaje
    _messagesByConv[convId]!.add(message);

    // Actualizar conversación
    _updateConversationLastMessage(convId, message.content);

    // Si no es la conversación activa, incrementar no leídos
    if (_activeConversationId != convId) {
      _incrementUnreadCount(convId);

      // Mostrar notificación local
      NotificationService.showLocalNotification(
        title: message.sender?.name ?? 'Nuevo mensaje',
        body: message.content,
        conversationId: convId,
      );
    }

    notifyListeners();
  }

  /// MANEJAR evento de typing
  void _handleTypingEvent(int convId, int userId, bool isTyping) {
    print('⌨️ Typing event: conv=$convId, user=$userId, typing=$isTyping');

    if (!_typingUsers.containsKey(convId)) {
      _typingUsers[convId] = {};
    }

    if (isTyping) {
      _typingUsers[convId]!.add(userId);
    } else {
      _typingUsers[convId]!.remove(userId);
    }

    notifyListeners();
  }

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
  Future<void> retryFailedMessage(int conversationId, Message failedMessage) async {
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
    _websocketService.dispose();
    super.dispose();
  }
}

