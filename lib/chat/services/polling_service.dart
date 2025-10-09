import 'dart:async';
import 'package:zonix/chat/models/message.dart';
import 'package:zonix/chat/services/chat_service.dart';

/// Servicio de HTTP Polling para chat en tiempo semi-real
/// 
/// Alternativa a WebSocket cuando la autenticación de canales privados
/// no es posible. Hace peticiones HTTP cada 4 segundos para obtener
/// mensajes nuevos.
/// 
/// Ventajas:
/// - ✅ Funciona garantizado (usa APIs HTTP existentes)
/// - ✅ Sin problemas de autenticación
/// - ✅ Simple y confiable
/// 
/// Desventajas:
/// - ⏱️ Delay de 3-5 segundos (no instantáneo)
/// - 🔋 Mayor consumo de batería
class PollingService {
  Timer? _pollingTimer;
  Timer? _typingPollingTimer;
  bool _isPolling = false;
  int? _lastMessageId;
  int? _activeConversationId;

  /// Intervalo de polling en segundos
  static const int pollingInterval = 4;
  static const int typingPollingInterval = 2;

  /// Callback para nuevos mensajes
  Function(List<Message>)? _onNewMessages;

  /// Callback para typing indicators
  Function(bool isTyping)? _onTypingChange;

  /// INICIAR polling para una conversación
  void startPolling(
    int conversationId, {
    required Function(List<Message>) onNewMessages,
  }) {
    print('🔄 PollingService: Iniciando polling para conv $conversationId');
    print('⏱️ Intervalo: $pollingInterval segundos');

    // Detener polling anterior si existe
    stopPolling();

    _activeConversationId = conversationId;
    _onNewMessages = onNewMessages;
    _isPolling = true;
    _lastMessageId = null;

    // Primera carga inmediata
    _pollMessages();

    // Luego polling periódico
    _pollingTimer = Timer.periodic(
      Duration(seconds: pollingInterval),
      (_) => _pollMessages(),
    );

    print('✅ PollingService: Polling iniciado');
  }

  /// DETENER polling
  void stopPolling() {
    if (_pollingTimer != null) {
      print('🛑 PollingService: Deteniendo polling');
      _pollingTimer?.cancel();
      _pollingTimer = null;
      _isPolling = false;
      _activeConversationId = null;
      _onNewMessages = null;
      _lastMessageId = null;
    }

    if (_typingPollingTimer != null) {
      _typingPollingTimer?.cancel();
      _typingPollingTimer = null;
      _onTypingChange = null;
    }
  }

  /// Hacer polling de mensajes
  Future<void> _pollMessages() async {
    if (!_isPolling || _activeConversationId == null) {
      return;
    }

    try {
      print('🔍 Polling: Consultando mensajes de conv $_activeConversationId');

      // Obtener mensajes de la conversación
      final messages =
          await ChatService.getMessages(_activeConversationId!);

      if (messages.isEmpty) {
        print('📭 Polling: Sin mensajes');
        return;
      }

      // Detectar mensajes nuevos
      final latestId = messages.first.id;

      if (_lastMessageId == null) {
        // Primera carga
        print('📥 Polling: Primera carga - ${messages.length} mensajes');
        _lastMessageId = latestId;
        
        if (_onNewMessages != null) {
          _onNewMessages!(messages);
        }
      } else if (latestId > _lastMessageId!) {
        // Hay mensajes nuevos
        final newMessages = messages
            .where((msg) => msg.id > _lastMessageId!)
            .toList();

        print('📨 Polling: ${newMessages.length} mensajes nuevos detectados');
        _lastMessageId = latestId;

        // Notificar con TODOS los mensajes (para mantener orden)
        if (_onNewMessages != null) {
          _onNewMessages!(messages);
        }
      } else {
        print('💤 Polling: Sin mensajes nuevos');
      }
    } catch (e) {
      print('⚠️ Polling: Error consultando mensajes: $e');
      // No detener el polling, seguir intentando
    }
  }

  /// INICIAR polling de typing indicators
  /// 
  /// Nota: Typing indicators con polling son menos precisos
  /// Se detecta actividad de escritura consultando el endpoint
  void startTypingPolling(
    int conversationId, {
    required Function(bool isTyping) onTypingChange,
  }) {
    print('⌨️ PollingService: Iniciando typing polling');

    _onTypingChange = onTypingChange;

    // Polling cada 2 segundos para typing (más frecuente)
    _typingPollingTimer = Timer.periodic(
      Duration(seconds: typingPollingInterval),
      (_) => _pollTyping(conversationId),
    );
  }

  /// Hacer polling de typing indicators
  Future<void> _pollTyping(int conversationId) async {
    try {
      // Aquí podrías consultar un endpoint que retorne
      // si el otro usuario está escribiendo
      // Por ahora, lo dejamos como placeholder
      
      // TODO: Implementar endpoint /api/chat/conversations/{id}/typing
      // que retorne {is_typing: true/false}
      
    } catch (e) {
      print('⚠️ Polling: Error consultando typing: $e');
    }
  }

  /// Verificar si está activo
  bool get isPolling => _isPolling;

  /// Obtener conversación activa
  int? get activeConversationId => _activeConversationId;

  /// Forzar polling inmediato (útil para pull-to-refresh)
  Future<void> pollNow() async {
    if (_isPolling) {
      print('🔄 Polling: Forzando actualización inmediata');
      await _pollMessages();
    }
  }

  /// Limpiar recursos
  void dispose() {
    print('🧹 PollingService: Limpiando recursos');
    stopPolling();
  }
}

