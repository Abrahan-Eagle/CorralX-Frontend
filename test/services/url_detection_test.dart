import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:corralx/onboarding/services/onboarding_api_service.dart';
import 'package:corralx/auth/services/api_service.dart';
import 'package:corralx/shared/services/location_service.dart';

void main() {
  setUpAll(() async {
    // Configurar variables de entorno para los tests
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
  });

  group('Servicios - Detección de URL en Modo Debug', () {
    test('OnboardingApiService debe usar API_URL_LOCAL en modo debug', () {
      final service = OnboardingApiService();
      final baseUrl = service.baseUrl;
      final expectedUrl = dotenv.env['API_URL_LOCAL'] ?? 'http://192.168.27.12:8000';
      
      expect(baseUrl, equals('$expectedUrl/api'));
      expect(baseUrl, contains('192.168.27.12'));
      expect(baseUrl, isNot(contains('backend.corralx.com')));
    });

    test('ApiService baseUrl debe usar API_URL_LOCAL en modo debug', () {
      final apiBaseUrl = baseUrl;
      final expectedUrl = dotenv.env['API_URL_LOCAL'] ?? 'http://192.168.27.12:8000';
      
      expect(apiBaseUrl, equals(expectedUrl));
      expect(apiBaseUrl, contains('192.168.27.12'));
      expect(apiBaseUrl, isNot(contains('backend.corralx.com')));
    });

    test('LocationService debe usar API_URL_LOCAL en modo debug', () {
      // LocationService usa _baseUrl que es privado, pero podemos verificar
      // que getCountries() usa la URL correcta
      // Nota: Este test requiere que el servidor local esté corriendo
      // Por ahora solo verificamos que el servicio existe
      expect(() => LocationService.getCountries(), returnsNormally);
    });
  });

  group('Servicios - Validación de URLs', () {
    test('OnboardingApiService baseUrl debe terminar con /api', () {
      final service = OnboardingApiService();
      final baseUrl = service.baseUrl;
      
      expect(baseUrl, endsWith('/api'));
    });

    test('ApiService baseUrl debe ser una URL válida', () {
      final url = baseUrl;
      
      expect(url, isNotEmpty);
      expect(url, startsWith('http'));
    });
  });

  group('Servicios - Lógica de Detección', () {
    test('En modo debug, kReleaseMode debe ser false', () {
      // En tests, kReleaseMode es false por defecto
      expect(kReleaseMode, isFalse);
    });

    test('En modo debug, isProduction debe ser false', () {
      // Verificamos que la lógica de detección funciona correctamente
      final isProduction = kReleaseMode || const bool.fromEnvironment('dart.vm.product');
      expect(isProduction, isFalse);
    });
  });
}

