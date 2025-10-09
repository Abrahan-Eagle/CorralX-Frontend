import 'dart:async';
import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/chat/models/message.dart';

/// Servicio WebSocket usando Pusher Channels para chat en tiempo real
/// Compatible con Laravel Echo Server siguiendo documentación oficial de Laravel
class WebSocketService {
  static const storage = FlutterSecureStorage();

  late PusherChannelsFlutter pusher;
  bool _isInitialized = false;

  // Estados de conexión
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;

  // Callbacks
  Function(Message message)? _onMessageCallback;
  Function(int convId, int userId, bool isTyping)? _onTypingCallback;
  Function(WebSocketConnectionState state)? _onConnectionChangeCallback;

  /// Estado actual de la conexión
  WebSocketConnectionState get connectionState => _connectionState;

  /// Verificar si está conectado
  bool get isConnected =>
      _connectionState == WebSocketConnectionState.connected;

  /// CONECTAR a Pusher/Laravel Echo Server
  /// Siguiendo documentación oficial de Laravel Broadcasting
  Future<void> connect() async {
    try {
      final token = await storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        print('❌ WebSocket: Token no disponible');
        _updateConnectionState(WebSocketConnectionState.error);
        return;
      }

      // Obtener configuración del servidor
      final apiUrl = AppConfig.apiUrl.replaceAll('http://', '').replaceAll('https://', '');
      final host = apiUrl.split(':')[0]; // 192.168.27.12

      print('🔌 WebSocket: Inicializando Pusher Channels...');
      print('🌐 Host: $host');
      print('🔑 Token: ${token.substring(0, 20)}...');

      _updateConnectionState(WebSocketConnectionState.connecting);

      pusher = PusherChannelsFlutter.getInstance();

      // ✅ Configuración según documentación de Laravel Broadcasting
      // https://laravel.com/docs/broadcasting#client-side-installation
      try {
        await pusher.init(
          apiKey: 'corralx-secret-key-2025', // PUSHER_APP_KEY del backend
          cluster: 'mt1', // PUSHER_APP_CLUSTER
          
          // ✅ Callback de autorización para canales privados
          onAuthorizer: (channelName, socketId, options) async {
            print('🔐 Pusher: Autorizando $channelName con socketId: $socketId');
            
            // Laravel espera el token en el header Authorization
            return {
              'Authorization': 'Bearer $token',
            };
          },
          
          // ✅ Eventos globales de Pusher
          onEvent: (event) {
            _handlePusherEvent(event);
          },
          
          // ✅ Cambios de estado de conexión
          onConnectionStateChange: (currentState, previousState) {
            print('🔄 Pusher: $previousState → $currentState');
            _handleConnectionStateChange(currentState, previousState);
          },
          
          // ✅ Manejo de errores
          onError: (message, code, error) {
            print('❌ Pusher Error: $message (code: $code)');
            _updateConnectionState(WebSocketConnectionState.error);
          },
        );

        _isInitialized = true;

        // ✅ Conectar a Pusher
        await pusher.connect();

        print('✅ WebSocket: Pusher inicializado y conectado');
        _updateConnectionState(WebSocketConnectionState.connected);
      } catch (e) {
        print('💥 Error en pusher.init(): $e');
        _updateConnectionState(WebSocketConnectionState.error);
        rethrow;
      }
    } catch (e) {
      print('💥 Error al conectar Pusher: $e');
      print('📋 Stack: $e');
      _updateConnectionState(WebSocketConnectionState.error);
    }
  }

  /// DESCONECTAR
  Future<void> disconnect() async {
    print('🔌 WebSocket: Desconectando...');

    try {
      if (_isInitialized) {
        await pusher.disconnect();
      }
      _updateConnectionState(WebSocketConnectionState.disconnected);
      print('✅ WebSocket: Desconectado');
    } catch (e) {
      print('⚠️ Error al desconectar: $e');
    }
  }

  /// SUSCRIBIRSE a un canal privado de conversación
  /// Según documentación: https://laravel.com/docs/broadcasting#authorizing-channels
  Future<void> subscribeToConversation(int conversationId) async {
    if (!_isInitialized || !isConnected) {
      print('⚠️ WebSocket: No está listo para suscribirse');
      print('   Inicializado: $_isInitialized, Conectado: $isConnected');
      return;
    }

    try {
      final channelName = 'private-conversation.$conversationId';

      print('📡 WebSocket: Suscribiendo a $channelName');

      // ✅ Pusher maneja automáticamente la autenticación
      // Llamará a onAuthorizer y hará POST /broadcasting/auth
      await pusher.subscribe(channelName: channelName);

      print('✅ WebSocket: Suscrito a $channelName');
    } catch (e) {
      print('💥 Error suscribiéndose: $e');
      print('📋 Detalle: ${e.toString()}');
    }
  }

  /// DESUSCRIBIRSE de un canal
  Future<void> unsubscribeFromConversation(int conversationId) async {
    final channelName = 'private-conversation.$conversationId';

    print('📡 WebSocket: Desuscribiendo de $channelName');

    try {
      await pusher.unsubscribe(channelName: channelName);
      print('✅ WebSocket: Desuscrito');
    } catch (e) {
      print('⚠️ Error al desuscribirse: $e');
    }
  }

  /// Manejar eventos de Pusher
  void _handlePusherEvent(PusherEvent event) {
    print('📬 Pusher Event recibido:');
    print('   Canal: ${event.channelName}');
    print('   Evento: ${event.eventName}');
    print('   Data: ${event.data}');

    try {
      // Parsear el data JSON
      final data = event.data != null && event.data!.isNotEmpty
          ? jsonDecode(event.data!)
          : <String, dynamic>{};

      // Determinar tipo de evento según nombre
      switch (event.eventName) {
        case 'MessageSent':
        case '.MessageSent': // Con punto también
          _processMessageSent(data);
          break;
        case 'TypingStarted':
        case '.TypingStarted':
          _processTypingEvent(data, true);
          break;
        case 'TypingStopped':
        case '.TypingStopped':
          _processTypingEvent(data, false);
          break;
        default:
          print('⚠️ Evento no manejado: ${event.eventName}');
      }
    } catch (e) {
      print('💥 Error procesando evento: $e');
      print('📦 Data original: ${event.data}');
    }
  }

  /// Procesar evento MessageSent
  void _processMessageSent(Map<String, dynamic> data) {
    try {
      print('📨 WebSocket: Procesando MessageSent...');

      final messageData = data['message'] as Map<String, dynamic>;
      final message = Message.fromJson(messageData);

      // Notificar al callback
      if (_onMessageCallback != null) {
        _onMessageCallback!(message);
      }

      print('✅ Mensaje procesado: ${message.id}');
    } catch (e) {
      print('💥 Error procesando MessageSent: $e');
      print('📦 Data recibida: $data');
    }
  }

  /// Procesar evento de Typing
  void _processTypingEvent(Map<String, dynamic> data, bool isTyping) {
    try {
      print('⌨️ WebSocket: Procesando Typing (isTyping: $isTyping)...');

      final convId = data['conversation_id'] as int;
      final userId = data['user_id'] as int;

      if (_onTypingCallback != null) {
        _onTypingCallback!(convId, userId, isTyping);
      }

      print('✅ Typing procesado: conv=$convId, user=$userId');
    } catch (e) {
      print('💥 Error procesando Typing: $e');
      print('📦 Data recibida: $data');
    }
  }

  /// Manejar cambios de estado de conexión
  void _handleConnectionStateChange(
      String? currentState, String? previousState) {
    print('🔄 Pusher: Estado cambió de $previousState → $currentState');

    switch (currentState) {
      case 'CONNECTED':
        _updateConnectionState(WebSocketConnectionState.connected);
        break;
      case 'CONNECTING':
        _updateConnectionState(WebSocketConnectionState.connecting);
        break;
      case 'DISCONNECTED':
        _updateConnectionState(WebSocketConnectionState.disconnected);
        break;
      case 'RECONNECTING':
        _updateConnectionState(WebSocketConnectionState.reconnecting);
        break;
      default:
        print('⚠️ Estado desconocido: $currentState');
    }
  }

  /// Actualizar estado y notificar callbacks
  void _updateConnectionState(WebSocketConnectionState newState) {
    if (_connectionState == newState) return;

    _connectionState = newState;
    print('🔄 WebSocket: Estado → $newState');

    if (_onConnectionChangeCallback != null) {
      _onConnectionChangeCallback!(newState);
    }
  }

  /// REGISTRAR callback para mensajes nuevos
  void onMessage(Function(Message message) callback) {
    _onMessageCallback = callback;
    print('🎧 WebSocket: Callback de mensajes registrado');
  }

  /// REGISTRAR callback para typing indicators
  void onTyping(Function(int convId, int userId, bool isTyping) callback) {
    _onTypingCallback = callback;
    print('🎧 WebSocket: Callback de typing registrado');
  }

  /// REGISTRAR callback para cambios de estado de conexión
  void onConnectionChange(Function(WebSocketConnectionState state) callback) {
    _onConnectionChangeCallback = callback;
    print('🎧 WebSocket: Callback de estado registrado');
  }

  /// Limpiar recursos
  void dispose() {
    print('🧹 WebSocket: Limpiando recursos...');
    disconnect();
    _onMessageCallback = null;
    _onTypingCallback = null;
    _onConnectionChangeCallback = null;
  }
}

/// Estados de conexión WebSocket
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}
