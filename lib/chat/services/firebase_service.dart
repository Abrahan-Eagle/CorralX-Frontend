import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:corralx/config/app_config.dart';

/// Servicio de Firebase Cloud Messaging para notificaciones push
///
/// Maneja:
/// - Inicialización de Firebase
/// - Registro de device token
/// - Notificaciones push cuando app está cerrada/background
/// - Deep linking a conversación específica
class FirebaseService {
  static FirebaseMessaging? _messaging;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Function(int conversationId)? _onNotificationTap;
  static Function(int orderId)? _onOrderNotificationTap;

  /// Inicializar Firebase y FCM
  static Future<bool> initialize() async {
    if (_initialized) {
      print('⚠️ FirebaseService: Ya inicializado');
      return true;
    }

    try {
      print('🔧 FirebaseService: Inicializando Firebase...');

      // Inicializar Firebase Core
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      // Solicitar permisos
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permisos de notificación otorgados');
      } else {
        print('⚠️ Permisos de notificación denegados');
        return false;
      }

      // Configurar canal de notificaciones Android (estilo WhatsApp)
      await _setupAndroidNotificationChannel();

      // Configurar notificaciones locales
      await _setupLocalNotifications();

      // Configurar handlers de notificaciones
      _setupNotificationHandlers();

      // Obtener y registrar device token
      await _registerDeviceToken();

      _initialized = true;
      print('✅ FirebaseService: Inicializado correctamente');
      return true;
    } catch (e) {
      print('❌ Error inicializando Firebase: $e');
      _initialized = false;
      return false;
    }
  }

  /// Configurar canal de notificaciones Android (estilo WhatsApp)
  static Future<void> _setupAndroidNotificationChannel() async {
    // Canal principal para mensajes de chat
    const androidChannel = AndroidNotificationChannel(
      'chat_messages_fcm',
      'Mensajes de Chat',
      description: 'Notificaciones de mensajes nuevos en tiempo real',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF386A20), // Verde de CorralX
      playSound: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Canal por defecto para otras notificaciones (pedidos, etc.)
    const defaultChannel = AndroidNotificationChannel(
      'corralx_default_channel',
      'Notificaciones CorralX',
      description: 'Notificaciones generales de la aplicación',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF386A20),
      playSound: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);

    print('✅ Canales de notificaciones Android configurados');
  }

  /// Configurar notificaciones locales
  static Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final payload = response.payload!;

          // Verificar si es notificación de pedido (formato: "order_123")
          if (payload.startsWith('order_')) {
            final orderId = int.tryParse(payload.replaceFirst('order_', ''));
            if (orderId != null && _onOrderNotificationTap != null) {
              _onOrderNotificationTap!(orderId);
              return;
            }
          }

          // Notificación de chat (formato: "123")
          final conversationId = int.tryParse(payload);
          if (conversationId != null && _onNotificationTap != null) {
            _onNotificationTap!(conversationId);
          }
        }
      },
    );

    // Crear canal de notificación para Android
    const channel = AndroidNotificationChannel(
      'chat_messages_fcm',
      'Mensajes de Chat',
      description: 'Notificaciones de mensajes nuevos en tiempo real',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Configurar handlers de notificaciones
  static void _setupNotificationHandlers() {
    // Mensaje recibido mientras app está en FOREGROUND: mostrar notificación local con mejor UI
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 FCM: Mensaje recibido (foreground)');
      _showLocalNotification(message);
    });

    // Mensaje clickeado cuando app está en BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 FCM: Notificación clickeada (background)');
      _handleNotificationTap(message);
    });

    // Mensaje recibido en BACKGROUND (handler top-level)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Registrar device token en el backend (método público para re-registrar después del login)
  static Future<void> registerDeviceToken() async {
    await _registerDeviceToken();
  }

  /// Registrar device token en el backend con retry y manejo robusto de errores
  static Future<void> _registerDeviceToken({int retryCount = 0}) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    try {
      // Intentar obtener token con timeout
      final token =
          await _messaging!.getToken().timeout(const Duration(seconds: 10));

      if (token == null || token.isEmpty) {
        print('⚠️ No se pudo obtener device token');
        if (retryCount < maxRetries) {
          print('🔄 Reintentando en ${retryDelay.inSeconds} segundos...');
          await Future.delayed(retryDelay);
          return _registerDeviceToken(retryCount: retryCount + 1);
        }
        return;
      }

      print('📱 Device token obtenido: ${token.substring(0, 20)}...');

      // Enviar token al backend
      const storage = FlutterSecureStorage();
      final authToken =
          await storage.read(key: 'token'); // ✅ Usar 'token' no 'auth_token'
      final apiUrl = AppConfig.apiUrl; // ✅ Usar AppConfig para URL dinámica

      if (authToken == null) {
        print('⚠️ No hay auth token, no se puede registrar FCM token');
        // Guardar token localmente para intentar registrarlo después del login
        return;
      }

      final response = await http
          .post(
            Uri.parse('$apiUrl/api/fcm/register-token'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'device_token': token}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Device token registrado en backend');
      } else {
        print('❌ Error registrando token: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } on TimeoutException {
      print(
          '⏱️ Timeout obteniendo FCM token (intento ${retryCount + 1}/$maxRetries)');
      if (retryCount < maxRetries) {
        await Future.delayed(retryDelay * (retryCount + 1));
        return _registerDeviceToken(retryCount: retryCount + 1);
      }
      print('⚠️ No se pudo obtener FCM token después de $maxRetries intentos');
    } on PlatformException catch (e) {
      // Error específico de Firebase/Google Play Services
      if (e.code == 'SERVICE_NOT_AVAILABLE' ||
          e.message?.contains('SERVICE_NOT_AVAILABLE') == true) {
        print('⚠️ Google Play Services no disponible o sin conexión');
        print(
            '💡 El dispositivo necesita Google Play Services actualizado y conexión a Internet');
        if (retryCount < maxRetries) {
          print(
              '🔄 Reintentando en ${retryDelay.inSeconds * (retryCount + 1)} segundos...');
          await Future.delayed(retryDelay * (retryCount + 1));
          return _registerDeviceToken(retryCount: retryCount + 1);
        }
      } else {
        print(
            '❌ Error de plataforma registrando device token: ${e.code} - ${e.message}');
      }
    } catch (e) {
      print('❌ Error registrando device token: $e');
      // No bloquear la inicialización de Firebase si falla el registro del token
      // El token se puede registrar más tarde cuando el usuario esté autenticado
    }
  }

  /// Mostrar notificación local cuando app está en foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final notificationType = data['type'] ?? '';

    // Determinar si es notificación de pedido o chat
    if (notificationType.startsWith('order_')) {
      // Notificación de pedido
      await _showOrderNotificationForeground(message);
      return;
    }

    // Notificación de chat (comportamiento original)
    // Extraer datos del mensaje (similar a WhatsApp)
    final conversationId =
        int.tryParse((data['conversation_id'] ?? '').toString());
    final senderName =
        (data['sender_name'] ?? notification?.title ?? 'CorralX').toString();
    final messageContent = (data['snippet'] ??
            data['body'] ??
            notification?.body ??
            'Nuevo mensaje')
        .toString();
    final groupKey = 'corralx_chat_${conversationId ?? 'general'}';

    print('📱 Mostrando notificación estilo WhatsApp:');
    print('   - Remitente: $senderName');
    print('   - Mensaje: $messageContent');
    print('   - Conversation ID: $conversationId');

    // Estilo WhatsApp: InboxStyle con múltiples mensajes del mismo chat
    final androidDetails = AndroidNotificationDetails(
      'chat_messages_fcm',
      'Mensajes de Chat',
      channelDescription: 'Notificaciones de mensajes nuevos en tiempo real',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      // Usar InboxStyle para agrupar mensajes como WhatsApp
      styleInformation: InboxStyleInformation(
        [messageContent], // Lista de mensajes del mismo chat
        contentTitle: senderName, // Nombre del remitente como título
        summaryText: 'CorralX', // App name como summary
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
        htmlFormatLines: false,
      ),
      ticker: 'Nuevo mensaje de $senderName',
      groupKey: groupKey, // Agrupar mensajes del mismo chat
      groupAlertBehavior:
          GroupAlertBehavior.summary, // Mostrar solo un resumen del grupo
      // Acciones como WhatsApp: Responder, Marcar como leído, Silenciar
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'reply',
          'Responder',
          icon: DrawableResourceAndroidBitmap('ic_reply'),
          inputs: [
            AndroidNotificationActionInput(
              label: 'Escribe una respuesta',
              allowFreeFormInput: true,
            )
          ],
        ),
        const AndroidNotificationAction(
          'mark_read',
          'Marcar como leído',
          icon: DrawableResourceAndroidBitmap('ic_done'),
        ),
        const AndroidNotificationAction(
          'mute',
          'Silenciar',
          icon: DrawableResourceAndroidBitmap('ic_notifications_off'),
        ),
      ],
      // Configuración adicional para mejor apariencia
      color: const Color(0xFF386A20), // Verde de CorralX
      ledColor: const Color(0xFF386A20),
      ledOnMs: 1000,
      ledOffMs: 500,
      // Configuración adicional para estilo WhatsApp
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      autoCancel: false, // No auto-cancelar para permitir acciones
      ongoing: false,
      showProgress: false,
      maxProgress: 0,
      indeterminate: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      conversationId ?? DateTime.now().millisecondsSinceEpoch % 2147483647,
      senderName, // Título: nombre del remitente
      messageContent, // Cuerpo: contenido del mensaje
      details,
      payload: conversationId?.toString(),
    );
  }

  /// Mostrar notificación de pedido en foreground
  static Future<void> _showOrderNotificationForeground(
      RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final orderId = int.tryParse((data['order_id'] ?? '').toString());
    final title =
        notification?.title ?? data['title'] ?? 'Actualización de pedido';
    final body =
        notification?.body ?? data['body'] ?? 'Tu pedido ha sido actualizado';

    print('📦 Mostrando notificación de pedido (foreground):');
    print('   - Order ID: $orderId');
    print('   - Title: $title');
    print('   - Body: $body');

    final androidDetails = AndroidNotificationDetails(
      'corralx_default_channel',
      'Notificaciones CorralX',
      channelDescription: 'Notificaciones de pedidos y actualizaciones',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF386A20),
      ledColor: const Color(0xFF386A20),
      ledOnMs: 1000,
      ledOffMs: 500,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      orderId ?? DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      details,
      payload: 'order_${orderId}',
    );
  }

  /// Manejar tap en notificación
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final notificationType = data['type'] ?? '';

    // Manejar notificaciones de pedidos
    if (notificationType.startsWith('order_')) {
      final orderId = int.tryParse(data['order_id'] ?? '');
      if (orderId != null && _onOrderNotificationTap != null) {
        _onOrderNotificationTap!(orderId);
        return;
      }
    }

    // Manejar notificaciones de chat (comportamiento original)
    final conversationId = int.tryParse(data['conversation_id'] ?? '');
    if (conversationId != null && _onNotificationTap != null) {
      _onNotificationTap!(conversationId);
    }
  }

  /// Registrar callback de tap en notificación de chat
  static void onNotificationTap(Function(int conversationId) callback) {
    _onNotificationTap = callback;
  }

  /// Registrar callback de tap en notificación de pedido
  static void onOrderNotificationTap(Function(int orderId) callback) {
    _onOrderNotificationTap = callback;
  }

  /// Desconectar y limpiar
  static Future<void> disconnect() async {
    try {
      await _messaging?.deleteToken();
      _initialized = false;
      print('🛑 FirebaseService: Token eliminado');
    } catch (e) {
      print('❌ Error eliminando token: $e');
    }
  }
}

/// Handler de mensajes en background (top-level function requerida)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print('📬 FCM: Mensaje recibido en background');
  print('Data: ${message.data}');
  print('Type: ${message.data['type']}');

  // Determinar tipo de notificación
  final notificationType = message.data['type'] ?? '';

  if (notificationType.startsWith('order_')) {
    // Notificación de pedido
    await _showOrderNotification(message);
  } else {
    // Notificación de chat (comportamiento original)
    await _showWhatsAppStyleNotification(message);
  }
}

/// Mostrar notificación de pedido (para background)
Future<void> _showOrderNotification(RemoteMessage message) async {
  try {
    final data = message.data;
    final notification = message.notification;

    // Extraer datos del pedido
    final orderId = int.tryParse((data['order_id'] ?? '').toString());
    final eventType =
        (data['type'] ?? 'order_created').toString().replaceFirst('order_', '');
    final title =
        notification?.title ?? data['title'] ?? 'Actualización de pedido';
    final body =
        notification?.body ?? data['body'] ?? 'Tu pedido ha sido actualizado';

    print('📦 Mostrando notificación de pedido en background:');
    print('   - Order ID: $orderId');
    print('   - Event Type: $eventType');
    print('   - Title: $title');
    print('   - Body: $body');

    // Configurar notificación de pedido
    final androidDetails = AndroidNotificationDetails(
      'corralx_default_channel', // Usar canal por defecto para pedidos
      'Notificaciones CorralX',
      channelDescription: 'Notificaciones de pedidos y actualizaciones',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF386A20),
      ledColor: const Color(0xFF386A20),
      ledOnMs: 1000,
      ledOffMs: 500,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final localNotifications = FlutterLocalNotificationsPlugin();
    await localNotifications.show(
      orderId ?? DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      details,
      payload: orderId?.toString(),
    );

    print('✅ Notificación de pedido mostrada en background');
  } catch (e) {
    print('❌ Error mostrando notificación de pedido: $e');
  }
}

/// Mostrar notificación estilo WhatsApp (para background)
Future<void> _showWhatsAppStyleNotification(RemoteMessage message) async {
  try {
    final data = message.data;

    // Extraer datos del mensaje
    final conversationId =
        int.tryParse((data['conversation_id'] ?? '').toString());
    final senderName =
        (data['sender_name'] ?? data['title'] ?? 'CorralX').toString();
    final messageContent =
        (data['snippet'] ?? data['body'] ?? 'Nuevo mensaje').toString();
    final groupKey = 'corralx_chat_${conversationId ?? 'general'}';

    print('📱 Mostrando notificación WhatsApp en background:');
    print('   - Remitente: $senderName');
    print('   - Mensaje: $messageContent');

    // Configurar notificación estilo WhatsApp
    final androidDetails = AndroidNotificationDetails(
      'chat_messages_fcm',
      'Mensajes de Chat',
      channelDescription: 'Notificaciones de mensajes nuevos en tiempo real',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      // Usar InboxStyle para agrupar mensajes como WhatsApp
      styleInformation: InboxStyleInformation(
        [messageContent],
        contentTitle: senderName,
        summaryText: 'CorralX',
      ),
      ticker: 'Nuevo mensaje de $senderName',
      groupKey: groupKey,
      groupAlertBehavior: GroupAlertBehavior.summary,
      // Acciones como WhatsApp
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'reply',
          'Responder',
          icon: DrawableResourceAndroidBitmap('ic_reply'),
          inputs: [
            AndroidNotificationActionInput(
              label: 'Escribe una respuesta',
              allowFreeFormInput: true,
            )
          ],
        ),
        const AndroidNotificationAction(
          'mark_read',
          'Marcar como leído',
          icon: DrawableResourceAndroidBitmap('ic_done'),
        ),
        const AndroidNotificationAction(
          'mute',
          'Silenciar',
          icon: DrawableResourceAndroidBitmap('ic_notifications_off'),
        ),
      ],
      color: const Color(0xFF386A20),
      ledColor: const Color(0xFF386A20),
      ledOnMs: 1000,
      ledOffMs: 500,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final localNotifications = FlutterLocalNotificationsPlugin();
    await localNotifications.show(
      conversationId ?? DateTime.now().millisecondsSinceEpoch % 2147483647,
      senderName,
      messageContent,
      details,
      payload: conversationId?.toString(),
    );

    print('✅ Notificación WhatsApp mostrada en background');
  } catch (e) {
    print('❌ Error mostrando notificación WhatsApp: $e');
  }
}
