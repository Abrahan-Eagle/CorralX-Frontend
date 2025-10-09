import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones locales para chat
/// Maneja notificaciones cuando la app está en foreground
/// TODO: Agregar Firebase Cloud Messaging para push notifications cuando app está cerrada
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Function(int conversationId)? _onNotificationTapCallback;

  /// INICIALIZAR servicio de notificaciones
  static Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ NotificationService: Ya inicializado');
      return;
    }

    print('🔔 NotificationService: Inicializando...');

    // Configuración Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializar con callback de tap
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('🔔 Notificación tocada: ${response.payload}');

        if (response.payload != null) {
          final conversationId = int.tryParse(response.payload!);
          if (conversationId != null && _onNotificationTapCallback != null) {
            _onNotificationTapCallback!(conversationId);
          }
        }
      },
    );

    _initialized = true;
    print('✅ NotificationService: Inicializado correctamente');
  }

  /// SOLICITAR permisos
  static Future<bool> requestPermission() async {
    print('🔔 NotificationService: Solicitando permisos...');

    // Android 13+ requiere permisos explícitos
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    bool? granted;
    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission();
    }

    print('🔔 Permisos: ${granted == true ? "✅ Concedidos" : "❌ Denegados"}');
    return granted ?? true;
  }

  /// MOSTRAR notificación local
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    int? conversationId,
  }) async {
    if (!_initialized) {
      print('⚠️ NotificationService: No inicializado, inicializando...');
      await initialize();
    }

    print('🔔 Mostrando notificación: $title');

    const androidDetails = AndroidNotificationDetails(
      'chat_messages', // Channel ID
      'Mensajes de Chat', // Channel name
      channelDescription: 'Notificaciones de nuevos mensajes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      conversationId ?? 0, // Notification ID
      title,
      body,
      details,
      payload: conversationId?.toString(),
    );

    print('✅ Notificación mostrada');
  }

  /// ACTUALIZAR badge count (iOS/Android)
  static Future<void> updateBadgeCount(int count) async {
    print('🔢 NotificationService: Actualizando badge a $count');

    // TODO: Implementar actualización de badge
    // En Android esto puede requerir plugins adicionales
    // En iOS se hace a través de Firebase
  }

  /// REGISTRAR callback cuando se toca una notificación
  static void onNotificationTap(Function(int conversationId) callback) {
    _onNotificationTapCallback = callback;
    print('🎧 NotificationService: Callback de tap registrado');
  }

  /// CANCELAR notificación específica
  static Future<void> cancelNotification(int conversationId) async {
    await _notifications.cancel(conversationId);
    print('❌ Notificación $conversationId cancelada');
  }

  /// CANCELAR todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('❌ Todas las notificaciones canceladas');
  }

  /// VERIFICAR si se otorgaron permisos
  static Future<bool> areNotificationsEnabled() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final bool? enabled = await androidPlugin.areNotificationsEnabled();
      return enabled ?? false;
    }

    return true; // iOS asume true
  }
}

/// TODO: Agregar Firebase Cloud Messaging (FCM)
/// 
/// Para implementar FCM en el futuro:
/// 
/// 1. Agregar dependencia:
///    firebase_messaging: ^14.7.9
///    firebase_core: ^2.24.2
/// 
/// 2. Configurar Firebase:
///    - Crear proyecto en Firebase Console
///    - Descargar google-services.json
///    - Configurar en android/app/
/// 
/// 3. Implementar métodos adicionales:
///    - getToken() - Obtener FCM token
///    - onBackgroundMessage() - Manejar mensajes en background
///    - sendTokenToBackend() - Guardar token en BD
/// 
/// 4. Backend debe enviar notificaciones vía FCM cuando:
///    - Usuario está offline
///    - Usuario está online pero app en background

