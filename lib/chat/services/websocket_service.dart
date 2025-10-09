import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/chat/models/message.dart';

/// Servicio WebSocket para chat en tiempo real usando Laravel Echo Server
/// Maneja conexión persistente, reconexión automática y eventos en tiempo real
class WebSocketService {
  static const storage = FlutterSecureStorage();

  IO.Socket? _socket;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectDelay = 30; // segundos

  // Estados de conexión
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;

  // Callbacks
  Function(Message message)? _onMessageCallback;
  Function(int convId, int userId, bool isTyping)? _onTypingCallback;
  Function(WebSocketConnectionState state)? _onConnectionChangeCallback;

  // Cola de mensajes pendientes si hay desconexión
  final List<Map<String, dynamic>> _pendingMessages = [];

  /// Estado actual de la conexión
  WebSocketConnectionState get connectionState => _connectionState;

  /// Verificar si está conectado
  bool get isConnected =>
      _connectionState == WebSocketConnectionState.connected;

  /// CONECTAR al Laravel Echo Server
  Future<void> connect() async {
    try {
      final token = await storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        print('❌ WebSocket: Token no disponible');
        _updateConnectionState(WebSocketConnectionState.error);
        return;
      }

      // URL del Echo Server (sin protocolo http://)
      final apiUrl =
          AppConfig.apiUrl.replaceAll('http://', '').replaceAll('https://', '');
      final echoServerUrl = 'http://${apiUrl.replaceAll(':8000', ':6001')}';

      print('🔌 WebSocket: Conectando a $echoServerUrl');
      print('🔑 Token: ${token.substring(0, 20)}...');

      _updateConnectionState(WebSocketConnectionState.connecting);

      _socket = IO.io(
        echoServerUrl,
        <String, dynamic>{
          'transports': ['websocket', 'polling'], // WebSocket primero
          'autoConnect': false, // Manual connect
          'query': {
            'appId': 'corralx-app',
            'key': 'corralx-secret-key-2025',
            'token': token, // ✅ Token en query (v1.0.2 no soporta setAuth)
          },
          'extraHeaders': {
            'Authorization': 'Bearer $token',
          },
          'path': '/socket.io/',
          'reconnection': true,
          'reconnectionAttempts': 5,
          'reconnectionDelay': 2000,
          'timeout': 10000,
          'forceNew': true,
        },
      );

      // ✅ Conectar manualmente DESPUÉS de configurar listeners
      print('🔌 WebSocket: Socket creado, configurando listeners...');

      // LISTENERS de eventos de Socket.IO
      _setupSocketListeners();

      // ✅ CONECTAR MANUALMENTE después de configurar listeners
      _socket!.connect();
      print('✅ WebSocket: Listeners configurados, conectando manualmente...');
    } catch (e) {
      print('💥 Error al conectar WebSocket: $e');
      _updateConnectionState(WebSocketConnectionState.error);
      _scheduleReconnect();
    }
  }

  /// Configurar listeners de eventos de Socket.IO
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Evento: Connecting (intentando conectar)
    _socket!.on('connecting', (_) {
      print('🔄 WebSocket: Evento "connecting" - Intentando conectar...');
    });

    // Evento: Conectado exitosamente
    _socket!.onConnect((_) {
      print('✅ WebSocket: ¡¡¡CONECTADO EXITOSAMENTE!!!');
      print('🎉 Socket ID: ${_socket!.id}');
      _reconnectAttempts = 0;
      _updateConnectionState(WebSocketConnectionState.connected);

      // Enviar mensajes pendientes
      _sendPendingMessages();

      // Iniciar heartbeat
      _startHeartbeat();
    });

    // Evento: Desconectado
    _socket!.onDisconnect((reason) {
      print('⚠️ WebSocket: Desconectado - Razón: $reason');
      _updateConnectionState(WebSocketConnectionState.disconnected);
      _stopHeartbeat();

      // No reconectar si fue desconexión manual
      if (reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    // Evento: Error de conexión
    _socket!.onConnectError((error) {
      print('❌ WebSocket: Error de conexión: $error');
      print('🔍 Tipo de error: ${error.runtimeType}');
      _updateConnectionState(WebSocketConnectionState.error);
      _scheduleReconnect();
    });

    // Evento: Error general
    _socket!.onError((error) {
      print('❌ WebSocket: Error general: $error');
    });

    // Evento: Reconnect attempt
    _socket!.on('reconnect_attempt', (attempt) {
      print('🔄 WebSocket: Intento de reconexión #$attempt');
    });

    // Evento: Reconnect failed
    _socket!.on('reconnect_failed', (_) {
      print('❌ WebSocket: Reconexión fallida después de todos los intentos');
    });

    // ✅ EVENTOS GLOBALES DE LARAVEL ECHO
    // Laravel Echo envía eventos con prefijo del namespace
    // Formato: "App\\Events\\EventName" o simplemente el nombre del evento

    // Evento: MessageSent (broadcast desde backend)
    _socket!.on('.MessageSent', (data) {
      print('📨 WebSocket: MessageSent recibido (con punto)');
      print('📦 Data: $data');
      _processMessageSent(data);
    });

    // También escuchar sin punto por si acaso
    _socket!.on('MessageSent', (data) {
      print('📨 WebSocket: MessageSent recibido (sin punto)');
      print('📦 Data: $data');
      _processMessageSent(data);
    });

    // Evento: TypingStarted
    _socket!.on('.TypingStarted', (data) {
      print('⌨️ WebSocket: TypingStarted recibido (con punto)');
      _processTypingEvent(data, true);
    });

    _socket!.on('TypingStarted', (data) {
      print('⌨️ WebSocket: TypingStarted recibido (sin punto)');
      _processTypingEvent(data, true);
    });

    // Evento: TypingStopped
    _socket!.on('.TypingStopped', (data) {
      print('⌨️ WebSocket: TypingStopped recibido (con punto)');
      _processTypingEvent(data, false);
    });

    _socket!.on('TypingStopped', (data) {
      print('⌨️ WebSocket: TypingStopped recibido (sin punto)');
      _processTypingEvent(data, false);
    });

    print('🎧 WebSocket: Listeners configurados');
  }

  /// Procesar evento MessageSent
  void _processMessageSent(dynamic data) {
    try {
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
  void _processTypingEvent(dynamic data, bool isTyping) {
    try {
      final convId = data['conversation_id'] as int;
      final userId = data['user_id'] as int;

      if (_onTypingCallback != null) {
        _onTypingCallback!(convId, userId, isTyping);
      }
    } catch (e) {
      print('💥 Error procesando Typing: $e');
      print('📦 Data recibida: $data');
    }
  }

  /// DESCONECTAR
  void disconnect() {
    print('🔌 WebSocket: Desconectando...');

    _stopHeartbeat();
    _reconnectTimer?.cancel();

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _updateConnectionState(WebSocketConnectionState.disconnected);
    print('✅ WebSocket: Desconectado');
  }

  /// SUSCRIBIRSE a un canal privado de conversación
  Future<void> subscribeToConversation(int conversationId) async {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ WebSocket: No conectado, no se puede suscribir');
      return;
    }

    try {
      final channelName = 'private-conversation.$conversationId';

      print('📡 WebSocket: Suscribiendo a $channelName');

      // ✅ Laravel Echo Server escucha eventos directamente del canal
      // NO necesita .emit('subscribe') en Socket.IO v1.x
      // Los eventos MessageSent, TypingStarted ya están configurados globalmente
      // Solo registramos el canal para referencia

      print(
          '✅ WebSocket: Canal $channelName configurado (eventos ya registrados globalmente)');
    } catch (e) {
      print('💥 Error configurando canal: $e');
    }
  }

  /// DESUSCRIBIRSE de un canal
  void unsubscribeFromConversation(int conversationId) {
    if (_socket == null) return;

    print('📡 WebSocket: Desuscribiendo de conversation.$conversationId');

    _socket!.emit('unsubscribe', {
      'channel': 'private-conversation.$conversationId',
    });

    print('✅ WebSocket: Desuscrito');
  }

  /// ENVIAR MENSAJE vía WebSocket (no usado en MVP, se usa HTTP)
  /// Mantener por si se quiere usar en el futuro
  void sendMessage(int conversationId, String content) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ WebSocket: No conectado, agregando a cola');
      _pendingMessages.add({
        'conversation_id': conversationId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return;
    }

    _socket!.emit('message', {
      'conversation_id': conversationId,
      'content': content,
    });

    print('📤 WebSocket: Mensaje enviado a conv $conversationId');
  }

  /// RECONEXIÓN automática con backoff exponencial
  void _scheduleReconnect() {
    // Cancelar timer anterior si existe
    _reconnectTimer?.cancel();

    // Calcular delay con backoff exponencial
    final delays = [1, 2, 4, 8, 16, 30]; // segundos
    final delayIndex = _reconnectAttempts < delays.length
        ? _reconnectAttempts
        : delays.length - 1;
    final delaySeconds = delays[delayIndex];

    print(
        '🔄 WebSocket: Reconectando en $delaySeconds segundos (intento ${_reconnectAttempts + 1})');

    _updateConnectionState(WebSocketConnectionState.reconnecting);

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectAttempts++;
      connect();
    });
  }

  /// HEARTBEAT - Keep-alive cada 30 segundos
  void _startHeartbeat() {
    _stopHeartbeat(); // Detener anterior si existe

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
        print('💓 WebSocket: Heartbeat enviado');
      } else {
        print('⚠️ WebSocket: Heartbeat - No conectado');
        _stopHeartbeat();
      }
    });

    print('💓 WebSocket: Heartbeat iniciado (cada 30s)');
  }

  /// Detener heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Enviar mensajes pendientes tras reconexión
  void _sendPendingMessages() {
    if (_pendingMessages.isEmpty) return;

    print(
        '📤 WebSocket: Enviando ${_pendingMessages.length} mensajes pendientes');

    for (var msg in _pendingMessages) {
      _socket!.emit('message', msg);
    }

    _pendingMessages.clear();
    print('✅ WebSocket: Mensajes pendientes enviados');
  }

  /// Actualizar estado y notificar callbacks
  void _updateConnectionState(WebSocketConnectionState newState) {
    if (_connectionState == newState) return;

    _connectionState = newState;

    print('🔄 WebSocket: Estado cambiado a $newState');

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
