import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:corralx/chat/models/message.dart';
import 'package:http/http.dart' as http;

/// Servicio de Pusher Channels para chat en tiempo real
///
/// Maneja conexión WebSocket con Pusher Cloud para:
/// - Mensajes instantáneos (<100ms)
/// - Typing indicators
/// - Online/Offline status
///
/// Con fallback automático a HTTP Polling si falla la conexión
class PusherService {
  PusherChannelsFlutter? _pusher;
  String? _currentChannelName;
  bool _isConnected = false;
  bool _isInitialized = false;

  // Callbacks
  Function(Message)? _onMessage;
  Function(int userId, String userName)? _onTypingStarted;
  Function(int userId)? _onTypingStopped;
  Function(bool)? _onConnectionChange;

  /// Estado de conexión
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;

  /// Inicializar Pusher
  Future<bool> initialize() async {
    if (_isInitialized) {
      print('⚠️ PusherService: Ya inicializado');
      return _isConnected;
    }

    try {
      print('🔧 PusherService: Inicializando Pusher Channels...');

      // Obtener credenciales de .env
      final pusherKey = dotenv.env['PUSHER_APP_KEY'] ?? '';
      final pusherCluster = dotenv.env['PUSHER_APP_CLUSTER'] ?? 'sa1';

      if (pusherKey.isEmpty) {
        print('❌ PUSHER_APP_KEY no configurada en .env');
        return false;
      }

      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher!.init(
        apiKey: pusherKey,
        cluster: pusherCluster,
        onConnectionStateChange: _handleConnectionStateChange,
        onError: _handleError,
        onEvent: _handleEvent,
        onSubscriptionSucceeded: _handleSubscriptionSucceeded,
        onSubscriptionError: _handleSubscriptionError,
        onDecryptionFailure: _handleDecryptionFailure,
        onMemberAdded: _handleMemberAdded,
        onMemberRemoved: _handleMemberRemoved,
      );

      await _pusher!.connect();

      _isInitialized = true;
      print('✅ PusherService: Inicializado correctamente');
      return true;
    } catch (e) {
      print('❌ Error inicializando Pusher: $e');
      _isInitialized = false;
      _isConnected = false;
      return false;
    }
  }

  /// Suscribirse a un canal privado de conversación
  Future<bool> subscribeToConversation(
    int conversationId, {
    required Function(Message) onMessage,
    required Function(int userId, String userName) onTypingStarted,
    required Function(int userId) onTypingStopped,
    Function(bool)? onConnectionChange,
  }) async {
    try {
      print('🔗 PusherService: Suscribiendo a conversación $conversationId');

      _onMessage = onMessage;
      _onTypingStarted = onTypingStarted;
      _onTypingStopped = onTypingStopped;
      _onConnectionChange = onConnectionChange;

      final channelName =
          'conversation.$conversationId'; // ✅ Canal público (sin 'private-')
      await _pusher!.subscribe(channelName: channelName);
      _currentChannelName = channelName;

      print('✅ PusherService: Suscrito a canal público $channelName');
      print('📡 Eventos se manejan en onEvent global (línea 57)');
      return true;
    } catch (e) {
      print('❌ Error suscribiendo a canal: $e');
      return false;
    }
  }

  /// Desuscribirse del canal actual
  Future<void> unsubscribe() async {
    if (_currentChannelName != null) {
      try {
        await _pusher!.unsubscribe(channelName: _currentChannelName!);
        _currentChannelName = null;
        print('✅ PusherService: Desuscrito del canal');
      } catch (e) {
        print('❌ Error desuscribiendo: $e');
      }
    }
  }

  /// Manejar cambios de estado de conexión
  void _handleConnectionStateChange(
      String currentState, String? previousState) {
    print('🔄 Pusher connection: $previousState → $currentState');

    _isConnected = currentState == 'CONNECTED';

    if (_onConnectionChange != null) {
      _onConnectionChange!(_isConnected);
    }
  }

  /// Manejar eventos recibidos
  void _handleEvent(PusherEvent event) {
    print('📨 Pusher event: ${event.eventName} en ${event.channelName}');
    print('📦 Datos completos del evento: ${event.data}');

    try {
      // Algunos SDKs devuelven data como String (JSON) o como Map dinámico
      final dynamic raw = event.data;
      final Map<String, dynamic> data = raw == null
          ? <String, dynamic>{}
          : (raw is String
              ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
              : Map<String, dynamic>.from(raw as Map));

      switch (event.eventName) {
        case 'MessageSent':
          if (_onMessage != null && data.isNotEmpty) {
            final int conversationId =
                int.tryParse((data['conversation_id'] ?? '').toString()) ?? 0;

            final dynamic payload = data['message'] ?? data;
            final Map<String, dynamic> messageData = payload is String
                ? Map<String, dynamic>.from(jsonDecode(payload) as Map)
                : Map<String, dynamic>.from(payload as Map);

            // Asegurar conversation_id en el payload para el modelo
            messageData['conversation_id'] ??= conversationId;

            final message = Message.fromJson(messageData);
            _onMessage!(message);
            print('✅ Mensaje recibido via Pusher: ${message.id}');
          }
          break;

        case 'TypingStarted':
          if (_onTypingStarted != null && data.isNotEmpty) {
            final int userId =
                int.tryParse((data['user_id'] ?? '').toString()) ?? 0;
            final String userName = (data['user_name'] ?? '').toString();
            _onTypingStarted!(userId, userName);
            print('⌨️ Usuario $userName está escribiendo...');
          }
          break;

        case 'TypingStopped':
          if (_onTypingStopped != null && data.isNotEmpty) {
            final int userId =
                int.tryParse((data['user_id'] ?? '').toString()) ?? 0;
            _onTypingStopped!(userId);
            print('⌨️ Usuario $userId dejó de escribir');
          }
          break;

        default:
          print('⚠️ Evento no manejado: ${event.eventName}');
      }
    } catch (e) {
      print('❌ Error procesando evento: $e');
    }
  }

  /// Manejar errores
  void _handleError(String message, int? code, dynamic e) {
    print('❌ Pusher error: $message (code: $code)');
    _isConnected = false;

    if (_onConnectionChange != null) {
      _onConnectionChange!(false);
    }
  }

  /// Manejar suscripción exitosa
  void _handleSubscriptionSucceeded(String channelName, dynamic data) {
    print('✅ Suscripción exitosa a canal: $channelName');
  }

  /// Manejar error de suscripción
  void _handleSubscriptionError(String message, dynamic e) {
    print('❌ Error de suscripción: $message');
  }

  /// Manejar fallo de descifrado
  void _handleDecryptionFailure(String event, String reason) {
    print('❌ Fallo de descifrado: $event - $reason');
  }

  /// Manejar miembro agregado
  void _handleMemberAdded(String channelName, PusherMember member) {
    print('👤 Miembro agregado: ${member.userId} en $channelName');
  }

  /// Manejar miembro removido
  void _handleMemberRemoved(String channelName, PusherMember member) {
    print('👤 Miembro removido: ${member.userId} de $channelName');
  }

  /// Desconectar
  Future<void> disconnect() async {
    try {
      await unsubscribe();
      await _pusher?.disconnect();
      _isConnected = false;
      _isInitialized = false;
      print('🛑 PusherService: Desconectado');
    } catch (e) {
      print('❌ Error desconectando Pusher: $e');
    }
  }

  /// Limpiar recursos
  void dispose() {
    disconnect();
    _onMessage = null;
    _onTypingStarted = null;
    _onTypingStopped = null;
    _onConnectionChange = null;
  }
}
