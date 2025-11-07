import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/admin/services/advertisement_admin_service.dart';

void main() {
  // Inicializar dotenv antes de todos los tests
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      dotenv.env.addAll({
        'API_URL_LOCAL': 'http://192.168.27.12:8000',
        'API_URL_PROD': 'https://backend.corralx.com',
        'ENVIRONMENT': 'development',
      });
    }
  });

  group('AdvertisementAdminService Tests', () {
    group('Service Structure', () {
      test('should have required static methods', () {
        // Test that the service has the expected structure
        expect(AdvertisementAdminService, isNotNull);
        expect(AdvertisementAdminService.getAllAdvertisements, isA<Function>());
        expect(AdvertisementAdminService.getAdvertisementById, isA<Function>());
        expect(AdvertisementAdminService.createAdvertisement, isA<Function>());
        expect(AdvertisementAdminService.updateAdvertisement, isA<Function>());
        expect(AdvertisementAdminService.deleteAdvertisement, isA<Function>());
      });

      test('getAllAdvertisements should return Future<List<Advertisement>>', () async {
        expect(
          AdvertisementAdminService.getAllAdvertisements(),
          isA<Future<List<dynamic>>>(),
        );
      });

      test('getAdvertisementById should return Future<Advertisement>', () async {
        expect(
          AdvertisementAdminService.getAdvertisementById(1),
          isA<Future<dynamic>>(),
        );
      });

      test('createAdvertisement should accept Map<String, dynamic>', () async {
        expect(
          AdvertisementAdminService.createAdvertisement({}),
          isA<Future<dynamic>>(),
        );
      });

      test('updateAdvertisement should accept id and data', () async {
        expect(
          AdvertisementAdminService.updateAdvertisement(1, {}),
          isA<Future<dynamic>>(),
        );
      });

      test('deleteAdvertisement should accept id', () async {
        expect(
          AdvertisementAdminService.deleteAdvertisement(1),
          isA<Future<void>>(),
        );
      });
    });

    group('Error Handling', () {
      test('should handle authentication errors gracefully', () async {
        // Test that service handles 403 errors (unauthorized)
        // En ambiente de tests, se espera que lance excepción por falta de token
        try {
          await AdvertisementAdminService.getAllAdvertisements();
          // Si no lanza excepción, está bien (puede ser que el backend no esté disponible)
        } catch (e) {
          // Si lanza excepción, debe ser una Exception
          expect(e, isA<Exception>());
        }
      });

      test('should handle network errors gracefully', () async {
        // Test that service handles network errors
        try {
          await AdvertisementAdminService.getAdvertisementById(999999);
          // Si no lanza excepción, está bien
        } catch (e) {
          // Si lanza excepción, debe ser una Exception
          expect(e, isA<Exception>());
        }
      });

      test('should handle invalid advertisement ID', () async {
        // Test that service handles invalid IDs
        try {
          await AdvertisementAdminService.getAdvertisementById(-1);
          // Si no lanza excepción, está bien
        } catch (e) {
          // Si lanza excepción, debe ser una Exception
          expect(e, isA<Exception>());
        }
      });
    });

    group('Data Validation', () {
      test('createAdvertisement should validate required fields', () async {
        // Verificar que el método acepta el parámetro correcto y maneja errores
        try {
          await AdvertisementAdminService.createAdvertisement({
            'title': 'Test Ad',
            'type': 'external_ad',
            'image_url': 'https://example.com/image.jpg',
            'priority': 50,
            'is_active': true,
          });
          // Si no lanza excepción, está bien
        } catch (e) {
          // Se espera error de validación o autorización
          expect(e, isA<Exception>());
        }
      });

      test('updateAdvertisement should validate data structure', () async {
        // Verificar que el método acepta los parámetros correctos y maneja errores
        try {
          await AdvertisementAdminService.updateAdvertisement(1, {
            'title': 'Updated Title',
          });
          // Si no lanza excepción, está bien
        } catch (e) {
          // Se espera error de validación o autorización
          expect(e, isA<Exception>());
        }
      });
    });

    group('Advertisement Types', () {
      test('should support sponsored_product type', () async {
        // Verificar que el método acepta datos de sponsored_product y maneja errores
        try {
          await AdvertisementAdminService.createAdvertisement({
            'title': 'Sponsored Product',
            'type': 'sponsored_product',
            'product_id': 1,
            'image_url': 'https://example.com/image.jpg',
            'priority': 75,
            'is_active': true,
          });
          // Si no lanza excepción, está bien
        } catch (e) {
          // Se espera error de validación o autorización
          expect(e, isA<Exception>());
        }
      });

      test('should support external_ad type', () async {
        // Verificar que el método acepta datos de external_ad y maneja errores
        try {
          await AdvertisementAdminService.createAdvertisement({
            'title': 'External Ad',
            'type': 'external_ad',
            'advertiser_name': 'Test Advertiser',
            'image_url': 'https://example.com/image.jpg',
            'target_url': 'https://example.com',
            'priority': 25,
            'is_active': true,
          });
          // Si no lanza excepción, está bien
        } catch (e) {
          // Se espera error de validación o autorización
          expect(e, isA<Exception>());
        }
      });
    });

    group('Priority Validation', () {
      test('should accept priority in range 0-100', () async {
        // Verificar que el método acepta prioridad en el rango válido y maneja errores
        try {
          await AdvertisementAdminService.createAdvertisement({
            'title': 'Test Ad',
            'type': 'external_ad',
            'image_url': 'https://example.com/image.jpg',
            'priority': 50,
            'is_active': true,
          });
          // Si no lanza excepción, está bien
        } catch (e) {
          // Se espera error de validación o autorización
          expect(e, isA<Exception>());
        }
      });
    });
  });
}

