import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Variables de entorno desde .env
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  // URLs de la API (3 entornos)
  static String get apiUrlLocal =>
      dotenv.env['API_URL_LOCAL'] ?? 'http://192.168.27.12:8000';
  static String get apiUrlTest =>
      dotenv.env['API_URL_TEST'] ?? 'https://test.corralx.com';
  static String get apiUrlProd =>
      dotenv.env['API_URL_PROD'] ?? 'https://corralx.com';

  // URLs de WebSocket (3 entornos)
  static String get wsUrlLocal =>
      dotenv.env['WS_URL_LOCAL'] ?? 'ws://192.168.27.12:6001';
  static String get wsUrlTest =>
      dotenv.env['WS_URL_TEST'] ?? 'wss://test.corralx.com';
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

  // Dominio de la app (para deep links y compartir)
  static String get appDomain =>
      dotenv.env['APP_DOMAIN'] ?? 'corralx.com';
  static String get appDomainLocal =>
      dotenv.env['APP_DOMAIN_LOCAL'] ?? '192.168.27.12';
  static String get currentAppDomain {
    switch (buildType) {
      case 'local':
        return appDomainLocal;
      case 'test':
        // Extraer dominio de API_URL_TEST (sin https://)
        final testUrl = apiUrlTest.replaceFirst(RegExp(r'https?://'), '');
        return testUrl.split('/').first; // Obtener solo el dominio
      case 'production':
        return appDomain;
      default:
        return appDomainLocal;
    }
  }

  // Información de contacto
  static String get contactEmail =>
      dotenv.env['CONTACT_EMAIL'] ?? 'contact@corralx.com';

  // Detección del entorno según tipo de compilación
  // 
  // Lógica de detección:
  // 1. Si se pasa BUILD_TYPE como --dart-define, usarlo (tiene prioridad)
  // 2. Si no, detectar automáticamente:
  //    - Debug (kDebugMode) → 'local' → http://192.168.27.12:8000
  //    - Release sin BUILD_TYPE → 'test' → https://test.corralx.com
  //    - Release con BUILD_TYPE=production → 'production' → https://corralx.com
  static String get buildType {
    // Prioridad 1: --dart-define=BUILD_TYPE=... (tiene máxima prioridad)
    const buildTypeEnv = String.fromEnvironment('BUILD_TYPE', defaultValue: '');
    if (buildTypeEnv.isNotEmpty) {
      return buildTypeEnv;
    }
    
    // Prioridad 2: Detección automática
    if (kDebugMode) {
      // Debug → siempre local
      return 'local';
    }
    
    // Release sin --dart-define → por defecto es 'test' (APK release local)
    // Para AAB de Play Store, se DEBE pasar: --dart-define=BUILD_TYPE=production
    return 'test';
  }

  // Getters de entorno
  static bool get isLocal => buildType == 'local';
  static bool get isTest => buildType == 'test';
  static bool get isProduction => buildType == 'production';
  static bool get isDevelopment => isLocal;

  // URLs dinámicas según el entorno detectado
  static String get apiUrl {
    switch (buildType) {
      case 'local':
        return apiUrlLocal;
      case 'test':
        return apiUrlTest;
      case 'production':
        return apiUrlProd;
      default:
        return apiUrlLocal;
    }
  }

  static String get wsUrl {
    switch (buildType) {
      case 'local':
        return wsUrlLocal;
      case 'test':
        return wsUrlTest;
      case 'production':
        return wsUrlProd;
      default:
        return wsUrlLocal;
    }
  }

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
