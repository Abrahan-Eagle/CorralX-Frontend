import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de notificaciones en background usando Workmanager
/// 
/// Realiza polling HTTP cada 15 minutos cuando la app está cerrada
/// y muestra notificaciones locales si hay mensajes nuevos.
/// 
/// 100% Nativo - Sin Firebase, sin Pusher, sin servicios externos.
class BackgroundNotificationService {
  static const String taskName = 'chat-background-polling';
  static const String uniqueName = 'chat-polling-task';

  /// Inicializar workmanager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // true para debugging
    );

    print('🔔 BackgroundNotificationService: Inicializado');
  }

  /// Registrar tarea periódica de polling
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: const Duration(minutes: 15), // Mínimo permitido por Android
      constraints: Constraints(
        networkType: NetworkType.connected, // Solo con internet
        requiresBatteryNotLow: false, // Ejecutar aunque batería baja
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );

    print('✅ Background polling registrado: cada 15 minutos');
  }

  /// Cancelar tarea periódica
  static Future<void> cancelPeriodicTask() async {
    await Workmanager().cancelByUniqueName(uniqueName);
    print('🛑 Background polling cancelado');
  }

  /// Cancelar todas las tareas
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    print('🛑 Todas las tareas background canceladas');
  }
}

/// Callback dispatcher (DEBE ser función top-level)
/// 
/// Esta función se ejecuta en un isolate separado en background.
/// NO tiene acceso al contexto de la app principal.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔍 Background task ejecutándose: $task');

    try {
      // 1. Obtener token guardado
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        print('⚠️ No hay token, cancelando polling');
        return Future.value(true);
      }

      // 2. Consultar API de conversaciones
      final apiUrl = await storage.read(key: 'api_base_url') ?? 
                     'http://192.168.27.12:8000'; // Fallback
      
      final response = await http.get(
        Uri.parse('$apiUrl/api/chat/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        
        // 3. Calcular mensajes no leídos
        int totalUnread = 0;
        for (var conv in data) {
          totalUnread += (conv['unread_count'] as int?) ?? 0;
        }

        print('📬 Mensajes no leídos: $totalUnread');

        // 4. Mostrar notificación si hay mensajes nuevos
        if (totalUnread > 0) {
          await _showNotification(totalUnread);
        }
      } else {
        print('⚠️ Error API: ${response.statusCode}');
      }

      return Future.value(true);
    } catch (e) {
      print('❌ Error en background task: $e');
      return Future.value(false);
    }
  });
}

/// Mostrar notificación local
Future<void> _showNotification(int unreadCount) async {
  final FlutterLocalNotificationsPlugin notifications = 
      FlutterLocalNotificationsPlugin();

  // Configurar notificación
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await notifications.initialize(initializationSettings);

  // Crear canal de notificación (Android 8+)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages', // id
    'Mensajes de Chat', // name
    description: 'Notificaciones de mensajes nuevos en el chat',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Mostrar notificación
  await notifications.show(
    0, // id
    'Nuevos mensajes', // título
    unreadCount == 1
        ? 'Tienes 1 mensaje sin leer'
        : 'Tienes $unreadCount mensajes sin leer', // body
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        // Sonido y vibración
        playSound: true,
        enableVibration: true,
        // Badge count
        number: unreadCount,
      ),
    ),
    payload: 'chat_messages', // Para deep linking
  );

  print('🔔 Notificación mostrada: $unreadCount mensajes');
}

