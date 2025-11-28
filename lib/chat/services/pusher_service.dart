import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:corralx/chat/models/message.dart';

/// Servicio de Pusher Channels para chat en tiempo real
///
/// Maneja conexión WebSocket con Pusher Cloud para:
/// - Mensajes instantáneos (<100ms)
/// - Typing indicators
/// - Online/Offline status
///
/// Con fallback automático a HTTP Polling si falla la conexión
/// 
/// ✅ Singleton para que todos los providers compartan la misma instancia
class PusherService {
  // ✅ Singleton instance
  static PusherService? _instance;
  static PusherService get instance {
    _instance ??= PusherService._();
    return _instance!;
  }
  
  // ✅ Constructor privado para singleton
  PusherService._();
  
  PusherChannelsFlutter? _pusher;
  String? _currentChannelName;
  bool _isConnected = false;
  bool _isInitialized = false;

  // Callbacks
  Function(Message)? _onMessage;
  Function(int userId, String userName)? _onTypingStarted;
  Function(int userId)? _onTypingStopped;
  Function(bool)? _onConnectionChange;
  
  // Callback genérico para eventos de Orders
  Function(String eventName, Map<String, dynamic> data)? _onOrderEvent;
  
  // Canales suscritos (múltiples)
  final Set<String> _subscribedChannels = {};

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
        _subscribedChannels.remove(_currentChannelName);
        _currentChannelName = null;
        print('✅ PusherService: Desuscrito del canal');
      } catch (e) {
        print('❌ Error desuscribiendo: $e');
      }
    }
  }
  
  /// Suscribirse a un canal de perfil para eventos de Orders
  Future<bool> subscribeToProfile(
    int profileId, {
    required Function(String eventName, Map<String, dynamic> data) onOrderEvent,
  }) async {
    try {
      print('🔗 PusherService: Suscribiendo a perfil $profileId');
      
      _onOrderEvent = onOrderEvent;
      
      final channelName = 'profile.$profileId';
      
      // Si ya está suscrito, no hacer nada
      if (_subscribedChannels.contains(channelName)) {
        print('⚠️ Ya está suscrito a $channelName');
        return true;
      }
      
      await _pusher!.subscribe(channelName: channelName);
      _subscribedChannels.add(channelName);
      
      print('✅ PusherService: Suscrito a canal de perfil $channelName');
      return true;
    } catch (e) {
      print('❌ Error suscribiendo a perfil: $e');
      return false;
    }
  }
  
  /// Desuscribirse de un canal de perfil
  Future<void> unsubscribeFromProfile(int profileId) async {
    final channelName = 'profile.$profileId';
    if (_subscribedChannels.contains(channelName)) {
      try {
        await _pusher!.unsubscribe(channelName: channelName);
        _subscribedChannels.remove(channelName);
        print('✅ PusherService: Desuscrito de perfil $profileId');
      } catch (e) {
        print('❌ Error desuscribiendo de perfil: $e');
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

        // Eventos de Orders
        case 'OrderCreated':
        case 'OrderAccepted':
        case 'OrderRejected':
        case 'OrderUpdated':
        case 'OrderDelivered':
        case 'OrderCompleted':
        case 'OrderCancelled':
          print('🔍 PusherService: Procesando evento de Order - ${event.eventName}');
          print('🔍 _onOrderEvent es null: ${_onOrderEvent == null}');
          print('🔍 data.isEmpty: ${data.isEmpty}');
          if (_onOrderEvent != null) {
            if (data.isNotEmpty) {
              _onOrderEvent!(event.eventName, data);
              print('✅ Evento de pedido recibido y procesado: ${event.eventName}');
            } else {
              print('⚠️ Evento de pedido sin datos: ${event.eventName}');
            }
          } else {
            print('⚠️ _onOrderEvent callback no está configurado para evento: ${event.eventName}');
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
    _onOrderEvent = null;
    _subscribedChannels.clear();
  }
}
