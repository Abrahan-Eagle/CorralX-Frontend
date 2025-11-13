import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:corralx/config/app_config.dart';

void main() {
  setUpAll(() async {
    // Configurar variables de entorno para los tests
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
  });

  group('AppConfig - Detección de Producción', () {
    test('isProduction debe detectar correctamente en modo debug', () {
      // En modo debug, isProduction debe ser false
      // Nota: En tests, kReleaseMode es false por defecto
      final isProduction = AppConfig.isProduction;
      final isDevelopment = AppConfig.isDevelopment;
      
      expect(isProduction, isFalse);
      expect(isDevelopment, isTrue);
    });

    test('apiUrl debe usar API_URL_LOCAL en modo debug', () {
      // En modo debug, debe usar API_URL_LOCAL
      final apiUrl = AppConfig.apiUrl;
      final expectedUrl = dotenv.env['API_URL_LOCAL'] ?? 'http://192.168.27.12:8000';
      
      expect(apiUrl, equals(expectedUrl));
    });

    test('apiUrlProd debe leer correctamente de .env', () {
      final apiUrlProd = AppConfig.apiUrlProd;
      final expectedUrl = dotenv.env['API_URL_PROD'] ?? 'https://backend.corralx.com';
      
      expect(apiUrlProd, equals(expectedUrl));
    });

    test('apiUrlLocal debe leer correctamente de .env', () {
      final apiUrlLocal = AppConfig.apiUrlLocal;
      final expectedUrl = dotenv.env['API_URL_LOCAL'] ?? 'http://192.168.27.12:8000';
      
      expect(apiUrlLocal, equals(expectedUrl));
    });

    test('apiBaseUrl debe incluir /api al final', () {
      final apiBaseUrl = AppConfig.apiBaseUrl;
      final apiUrl = AppConfig.apiUrl;
      
      expect(apiBaseUrl, equals('$apiUrl/api'));
    });

    test('wsUrl debe usar WS_URL_LOCAL en modo debug', () {
      // En modo debug, debe usar WS_URL_LOCAL
      final wsUrl = AppConfig.wsUrl;
      final expectedUrl = dotenv.env['WS_URL_LOCAL'] ?? 'ws://192.168.27.12:6001';
      
      expect(wsUrl, equals(expectedUrl));
    });
  });

  group('AppConfig - Validación de Variables', () {
    test('apiUrlProd no debe estar vacío', () {
      final apiUrlProd = AppConfig.apiUrlProd;
      expect(apiUrlProd, isNotEmpty);
      expect(apiUrlProd, startsWith('http'));
    });

    test('apiUrlLocal no debe estar vacío', () {
      final apiUrlLocal = AppConfig.apiUrlLocal;
      expect(apiUrlLocal, isNotEmpty);
      expect(apiUrlLocal, startsWith('http'));
    });

    test('apiUrl no debe estar vacío', () {
      final apiUrl = AppConfig.apiUrl;
      expect(apiUrl, isNotEmpty);
      expect(apiUrl, startsWith('http'));
    });

    test('apiBaseUrl debe terminar con /api', () {
      final apiBaseUrl = AppConfig.apiBaseUrl;
      expect(apiBaseUrl, endsWith('/api'));
    });
  });
}

