import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
          final conversationId = int.tryParse(response.payload!);
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
    // Mensaje recibido mientras app está en FOREGROUND
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

  /// Registrar device token en el backend
  static Future<void> _registerDeviceToken() async {
    try {
      final token = await _messaging!.getToken();

      if (token == null) {
        print('⚠️ No se pudo obtener device token');
        return;
      }

      print('📱 Device token obtenido: ${token.substring(0, 20)}...');

      // Enviar token al backend
      const storage = FlutterSecureStorage();
      final authToken =
          await storage.read(key: 'token'); // ✅ Usar 'token' no 'auth_token'
      final apiUrl = dotenv.env['API_URL_LOCAL'] ?? 'http://192.168.27.12:8000';

      if (authToken == null) {
        print('⚠️ No hay auth token, no se puede registrar FCM token');
        return;
      }

      final response = await http.post(
        Uri.parse('$apiUrl/api/fcm/register-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'device_token': token}),
      );

      if (response.statusCode == 200) {
        print('✅ Device token registrado en backend');
      } else {
        print('❌ Error registrando token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registrando device token: $e');
    }
  }

  /// Mostrar notificación local cuando app está en foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_messages_fcm',
      'Mensajes de Chat',
      channelDescription: 'Notificaciones de mensajes nuevos en tiempo real',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Nuevo mensaje',
      notification.body ?? '',
      details,
      payload: message.data['conversation_id']?.toString(),
    );
  }

  /// Manejar tap en notificación
  static void _handleNotificationTap(RemoteMessage message) {
    final conversationId = int.tryParse(message.data['conversation_id'] ?? '');
    if (conversationId != null && _onNotificationTap != null) {
      _onNotificationTap!(conversationId);
    }
  }

  /// Registrar callback de tap en notificación
  static void onNotificationTap(Function(int conversationId) callback) {
    _onNotificationTap = callback;
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
  print('Título: ${message.notification?.title}');
  print('Cuerpo: ${message.notification?.body}');
}
