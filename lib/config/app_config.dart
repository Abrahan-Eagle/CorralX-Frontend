import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API URLs - Desde variables de entorno
  static String get apiUrlLocal => dotenv.env['API_URL_LOCAL'] ?? 'http://192.168.0.101:8000';
  static String get apiUrlProd => dotenv.env['API_URL_PROD'] ?? 'https://corralx.uniblockweb.com';
  
  static String get apiUrl {
    final environment = dotenv.env['ENVIRONMENT'] ?? 'development';
    return environment == 'production' ? apiUrlProd : apiUrlLocal;
  }
  
  // WebSocket Configuration - Laravel Echo Server
  static String get wsUrlLocal => dotenv.env['WS_URL_LOCAL'] ?? 'ws://192.168.0.101:6001';
  static String get wsUrlProd => dotenv.env['WS_URL_PROD'] ?? 'wss://corralx.uniblockweb.com';
  
  static String get wsUrl {
    final environment = dotenv.env['ENVIRONMENT'] ?? 'development';
    return environment == 'production' ? wsUrlProd : wsUrlLocal;
  }
  
  // Echo Server Configuration
  static String get echoAppId => dotenv.env['ECHO_APP_ID'] ?? 'corralx-app';
  static String get echoKey => dotenv.env['ECHO_KEY'] ?? 'corralx-key';
  static bool get enableWebsockets => dotenv.env['ENABLE_WEBSOCKETS']?.toLowerCase() == 'true';
  
  // Google Maps API Key
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'your_google_maps_api_key_here';
  
  // Firebase Configuration
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? 'your_firebase_project_id';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 'your_sender_id';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? 'your_app_id';
  
  // Configuración de la aplicación
  static String get appName => dotenv.env['APP_NAME'] ?? 'Corral X';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get appBuildNumber => dotenv.env['APP_BUILD_NUMBER'] ?? '1';
  
  // Configuración de paginación
  static int get defaultPageSize => int.tryParse(dotenv.env['DEFAULT_PAGE_SIZE'] ?? '20') ?? 20;
  static int get maxPageSize => int.tryParse(dotenv.env['MAX_PAGE_SIZE'] ?? '100') ?? 100;
  
  // Configuración de timeouts
  static int get connectionTimeout => int.tryParse(dotenv.env['CONNECTION_TIMEOUT'] ?? '30000') ?? 30000;
  static int get receiveTimeout => int.tryParse(dotenv.env['RECEIVE_TIMEOUT'] ?? '30000') ?? 30000;
  static int get requestTimeout => int.tryParse(dotenv.env['REQUEST_TIMEOUT'] ?? '30000') ?? 30000;
  
  // Configuración de reintentos
  static int get maxRetryAttempts => int.tryParse(dotenv.env['MAX_RETRY_ATTEMPTS'] ?? '3') ?? 3;
  static int get retryDelayMs => int.tryParse(dotenv.env['RETRY_DELAY_MS'] ?? '1000') ?? 1000;
  
  // Environment
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
} 