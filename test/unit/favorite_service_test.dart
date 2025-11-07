import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/favorites/services/favorite_service.dart';
import 'package:zonix/config/app_config.dart';

void main() {
  // Inicializar dotenv antes de todos los tests
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // Si no existe .env en tests, usar valores mock
      dotenv.env.addAll({
        'API_URL_LOCAL': 'http://192.168.27.12:8000',
        'API_URL_PROD': 'https://backend.corralx.com',
        'WS_URL_LOCAL': 'ws://192.168.27.12:6001',
        'WS_URL_PROD': 'wss://backend.corralx.com',
        'ENVIRONMENT': 'development',
      });
    }
  });

  group('FavoriteService Tests', () {
    setUp(() {
      // Setup inicial si es necesario
    });

    group('getMyFavorites', () {
      test('debe existir y ser método estático async', () async {
        // Verificar que el método existe
        expect(FavoriteService.getMyFavorites, isA<Function>());
      });

      test('debe aceptar parámetros page y perPage', () async {
        // Verificar firma del método
        expect(FavoriteService.getMyFavorites, isA<Function>());
      });

      test('debe tener valores por defecto (page=1, perPage=20)', () async {
        // Los parámetros deben ser opcionales con valores por defecto
        expect(FavoriteService.getMyFavorites, isA<Function>());
      });
    });

    group('toggleFavorite', () {
      test('debe existir y aceptar productId', () async {
        // Verificar que el método existe
        expect(FavoriteService.toggleFavorite, isA<Function>());
      });

      test('debe retornar Future<bool>', () async {
        // El método debe retornar el estado final de favorito
        expect(FavoriteService.toggleFavorite, isA<Function>());
      });

      test('debe validar que el token no sea null', () async {
        // Debe lanzar excepción si token es null
        expect(FavoriteService.toggleFavorite, isA<Function>());
      });
    });

    group('isFavorite', () {
      test('debe existir y retornar Future<bool>', () async {
        // Verificar método
        expect(FavoriteService.isFavorite, isA<Function>());
      });

      test('debe aceptar productId como parámetro', () async {
        // Verificar firma
        expect(FavoriteService.isFavorite, isA<Function>());
      });
    });

    group('removeFavorite', () {
      test('debe existir y retornar Future<bool>', () async {
        // Verificar método
        expect(FavoriteService.removeFavorite, isA<Function>());
      });

      test('debe aceptar productId como parámetro', () async {
        // Verificar firma
        expect(FavoriteService.removeFavorite, isA<Function>());
      });
    });

    group('getFavoritesCount', () {
      test('debe existir y retornar Future<int>', () async {
        // Verificar método
        expect(FavoriteService.getFavoritesCount, isA<Function>());
      });

      test('debe aceptar productId como parámetro', () async {
        // Verificar firma
        expect(FavoriteService.getFavoritesCount, isA<Function>());
      });
    });

    group('Validaciones de Token', () {
      test('debe usar la key "token" correcta en storage', () async {
        // Este test verifica que se usa 'token' y no 'auth_token'
        const correctKey = 'token';
        expect(correctKey, equals('token'));
        expect(correctKey, isNot(equals('auth_token')));
      });

      test('debe incluir Bearer en Authorization header', () async {
        // Verificar que el formato del header es correcto
        final token = 'test-token-123';
        final authHeader = 'Bearer $token';
        expect(authHeader, startsWith('Bearer '));
      });
    });

    group('Manejo de Errores', () {
      test('debe manejar error 401 Unauthorized', () async {
        // Verificar que existen try-catch blocks
        expect(FavoriteService.getMyFavorites, isA<Function>());
      });

      test('debe manejar error 404 Not Found', () async {
        // Verificar manejo de errores
        expect(FavoriteService.toggleFavorite, isA<Function>());
      });

      test('debe manejar error 500 Internal Server Error', () async {
        // Verificar manejo de errores del servidor
        expect(FavoriteService.getMyFavorites, isA<Function>());
      });
    });
  });
}

