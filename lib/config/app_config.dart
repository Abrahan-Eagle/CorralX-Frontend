import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Variables de entorno desde .env
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  // URLs de la API
  static String get apiUrlLocal =>
      dotenv.env['API_URL_LOCAL'] ?? 'http://192.168.27.12:8000';
  static String get apiUrlProd =>
      dotenv.env['API_URL_PROD'] ?? 'https://corralx.com';

  // URLs de WebSocket
  static String get wsUrlLocal =>
      dotenv.env['WS_URL_LOCAL'] ?? 'ws://192.168.27.12:6001';
  static String get wsUrlProd =>
      dotenv.env['WS_URL_PROD'] ?? 'wss://corralx.com';

  // Configuración de Firebase
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // Configuración de Google Maps
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Configuración de la app
  static String get appName => dotenv.env['APP_NAME'] ?? 'Corral X';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get appBuildNumber => dotenv.env['APP_BUILD_NUMBER'] ?? '1';

  // Configuración de paginación
  static int get defaultPageSize =>
      int.tryParse(dotenv.env['DEFAULT_PAGE_SIZE'] ?? '20') ?? 20;
  static int get maxPageSize =>
      int.tryParse(dotenv.env['MAX_PAGE_SIZE'] ?? '100') ?? 100;

  // Configuración de timeouts
  static int get connectionTimeout =>
      int.tryParse(dotenv.env['CONNECTION_TIMEOUT'] ?? '30000') ?? 30000;
  static int get receiveTimeout =>
      int.tryParse(dotenv.env['RECEIVE_TIMEOUT'] ?? '30000') ?? 30000;
  static int get requestTimeout =>
      int.tryParse(dotenv.env['REQUEST_TIMEOUT'] ?? '30000') ?? 30000;

  // Configuración de reintentos
  static int get maxRetryAttempts =>
      int.tryParse(dotenv.env['MAX_RETRY_ATTEMPTS'] ?? '3') ?? 3;
  static int get retryDelayMs =>
      int.tryParse(dotenv.env['RETRY_DELAY_MS'] ?? '1000') ?? 1000;

  // Configuración de WebSockets
  static String get echoAppId => dotenv.env['ECHO_APP_ID'] ?? 'corralx-app';
  static String get echoKey => dotenv.env['ECHO_KEY'] ?? 'corralx-key';
  static bool get enableWebSockets =>
      dotenv.env['ENABLE_WEBSOCKETS']?.toLowerCase() == 'true';

  // Getters dinámicos - Lógica simple: release = producción, debug = local
  static bool get isProduction {
    // Si está en modo --release, usar producción
    // Si NO está en modo release (debug), usar local
    return kReleaseMode || const bool.fromEnvironment('dart.vm.product');
  }

  static bool get isDevelopment => !isProduction;
  static String get apiUrl => isProduction ? apiUrlProd : apiUrlLocal;
  static String get wsUrl => isProduction ? wsUrlProd : wsUrlLocal;

  // URL completa de la API
  static String get apiBaseUrl => '$apiUrl/api';

  // Configuración de timeouts para HTTP
  static Duration get connectionTimeoutDuration =>
      Duration(milliseconds: connectionTimeout);
  static Duration get receiveTimeoutDuration =>
      Duration(milliseconds: receiveTimeout);
  static Duration get requestTimeoutDuration =>
      Duration(milliseconds: requestTimeout);
}
