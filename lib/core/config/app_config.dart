class AppConfig {
  // Variables de entorno
  static const String environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  // URLs de la API
  static const String apiUrlLocal = String.fromEnvironment('API_URL_LOCAL',
      defaultValue: 'http://localhost:8000');
  static const String apiUrlProd = String.fromEnvironment('API_URL_PROD',
      defaultValue: 'https://backend.corralx.com');

  // URLs de WebSocket
  static const String wsUrlLocal = String.fromEnvironment('WS_URL_LOCAL',
      defaultValue: 'ws://localhost:6001');
  static const String wsUrlProd = String.fromEnvironment('WS_URL_PROD',
      defaultValue: 'wss://backend.corralx.com');

  // Configuración de Firebase
  static const String firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String firebaseAppId =
      String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');

  // Configuración de Google Maps
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  // Configuración de la app
  static const String appName =
      String.fromEnvironment('APP_NAME', defaultValue: 'Corral X');
  static const String appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  static const String appBuildNumber =
      String.fromEnvironment('APP_BUILD_NUMBER', defaultValue: '1');

  // Configuración de paginación
  static const int defaultPageSize =
      int.fromEnvironment('DEFAULT_PAGE_SIZE', defaultValue: 20);
  static const int maxPageSize =
      int.fromEnvironment('MAX_PAGE_SIZE', defaultValue: 100);

  // Configuración de timeouts
  static const int connectionTimeout =
      int.fromEnvironment('CONNECTION_TIMEOUT', defaultValue: 30000);
  static const int receiveTimeout =
      int.fromEnvironment('RECEIVE_TIMEOUT', defaultValue: 30000);
  static const int requestTimeout =
      int.fromEnvironment('REQUEST_TIMEOUT', defaultValue: 30000);

  // Configuración de reintentos
  static const int maxRetryAttempts =
      int.fromEnvironment('MAX_RETRY_ATTEMPTS', defaultValue: 3);
  static const int retryDelayMs =
      int.fromEnvironment('RETRY_DELAY_MS', defaultValue: 1000);

  // Configuración de WebSockets
  static const String echoAppId =
      String.fromEnvironment('ECHO_APP_ID', defaultValue: 'corralx-app');
  static const String echoKey =
      String.fromEnvironment('ECHO_KEY', defaultValue: 'corralx-key');
  static const bool enableWebSockets =
      bool.fromEnvironment('ENABLE_WEBSOCKETS', defaultValue: true);

  // Getters dinámicos
  static String get apiUrl => isProduction ? apiUrlProd : apiUrlLocal;
  static String get wsUrl => isProduction ? wsUrlProd : wsUrlLocal;
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

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
