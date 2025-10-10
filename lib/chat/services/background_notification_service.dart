import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de notificaciones en background
/// 
/// Realiza polling HTTP cada 15 minutos cuando la app está cerrada/background
/// y muestra notificaciones locales si hay mensajes nuevos.
/// 
/// 100% Nativo - Sin Firebase, sin Pusher, sin servicios externos.
class BackgroundNotificationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Intervalo de polling en minutos
  static const int pollingIntervalMinutes = 15;

  /// Inicializar servicio de background
  static Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false, // Background service (no notificación persistente)
        autoStartOnBoot: true, // Iniciar al reiniciar dispositivo
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    print('🔔 BackgroundNotificationService: Inicializado');
  }

  /// Iniciar servicio
  static Future<void> start() async {
    await _service.startService();
    print('✅ Background service iniciado');
  }

  /// Detener servicio
  static Future<void> stop() async {
    await _service.invoke('stop');
    print('🛑 Background service detenido');
  }

  /// Callback principal (Android)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Solo para Android
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stop').listen((event) {
      service.stopSelf();
    });

    // Timer periódico cada 15 minutos
    Timer.periodic(const Duration(minutes: pollingIntervalMinutes), (timer) async {
      print('🔍 Background polling ejecutándose...');

      try {
        await _checkNewMessages();
      } catch (e) {
        print('❌ Error en background polling: $e');
      }
    });

    // Primera ejecución inmediata
    await _checkNewMessages();
  }

  /// Callback para iOS background
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    try {
      await _checkNewMessages();
      return true;
    } catch (e) {
      print('❌ Error en iOS background: $e');
      return false;
    }
  }

  /// Consultar API y verificar mensajes nuevos
  static Future<void> _checkNewMessages() async {
    try {
      print('🔍 Verificando mensajes nuevos...');

      // 1. Obtener token de autenticación
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      
      final token = await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        print('⚠️ No hay token de autenticación');
        return;
      }

      // 2. Obtener URL base de API
      final apiUrl = await storage.read(key: 'api_base_url') ??
          'http://192.168.27.12:8000'; // Fallback

      // 3. Consultar conversaciones
      final response = await http.get(
        Uri.parse('$apiUrl/api/chat/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> conversations = jsonDecode(response.body);

        // 4. Calcular mensajes no leídos
        int totalUnread = 0;
        for (var conv in conversations) {
          totalUnread += (conv['unread_count'] as int?) ?? 0;
        }

        print('📬 Mensajes no leídos: $totalUnread');

        // 5. Mostrar notificación si hay mensajes nuevos
        if (totalUnread > 0) {
          await _showNotification(totalUnread);
        } else {
          print('✅ No hay mensajes nuevos');
        }
      } else if (response.statusCode == 401) {
        print('⚠️ Token expirado o inválido');
      } else {
        print('⚠️ Error API: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error consultando mensajes: $e');
    }
  }

  /// Mostrar notificación local nativa
  static Future<void> _showNotification(int unreadCount) async {
    try {
      // Inicializar notificaciones si no está inicializado
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notifications.initialize(initializationSettings);

      // Crear canal de notificación (Android 8+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'chat_messages_background', // id único
        'Mensajes de Chat', // nombre
        description: 'Notificaciones de mensajes nuevos en el chat',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Mostrar notificación
      await _notifications.show(
        0, // id (siempre 0 para agrupar)
        'Nuevos mensajes', // título
        unreadCount == 1
            ? 'Tienes 1 mensaje sin leer'
            : 'Tienes $unreadCount mensajes sin leer', // cuerpo
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            when: DateTime.now().millisecondsSinceEpoch,
            icon: '@mipmap/ic_launcher',
            // Sonido y vibración
            playSound: true,
            enableVibration: true,
            // Badge count
            number: unreadCount,
            // Agrupar notificaciones
            groupKey: 'chat_messages',
            setAsGroupSummary: true,
          ),
        ),
        payload: 'chat_messages', // Para deep linking
      );

      print('🔔 Notificación mostrada: $unreadCount mensajes');
    } catch (e) {
      print('❌ Error mostrando notificación: $e');
    }
  }
}
