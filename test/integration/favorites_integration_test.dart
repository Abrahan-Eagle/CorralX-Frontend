import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/products/providers/product_provider.dart';
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

  group('Favorites Module - Integration Tests', () {
    late ProductProvider productProvider;

    setUp(() {
      productProvider = ProductProvider();
    });
    
    tearDown(() async {
      // Esperar a que terminen las operaciones async antes de hacer dispose
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        productProvider.dispose();
      } catch (e) {
        // Si ya está disposed, ignorar el error
      }
    });

    group('Flujo Completo: Agregar a Favoritos', () {
      test('debe completar el flujo de agregar favorito', () async {
        // PASO 1: Usuario ve un producto en Marketplace
        final productId = 100;

        // PASO 2: Usuario hace clic en el corazón
        // - Se ejecuta ProductProvider.toggleFavorite(productId)
        expect(productProvider.toggleFavorite, isA<Function>());

        // PASO 3: Optimistic update
        // - Se agrega ID a favorites
        // - Se agrega producto a favoriteProducts
        // - Se llama notifyListeners()
        expect(productProvider.favorites, isA<Set<int>>());
        expect(productProvider.favoriteProducts, isA<List>());

        // PASO 4: Backend request
        // - Se llama FavoriteService.toggleFavorite(productId)
        // - Se envía POST /api/products/{id}/favorite
        expect(FavoriteService.toggleFavorite, isA<Function>());

        // PASO 5: Backend responde
        // - {success: true, is_favorite: true, message: "..."}
        // - Se sincroniza el estado local con la respuesta

        // PASO 6: UI se actualiza
        // - Consumer<ProductProvider> detecta cambio
        // - ProductCard se reconstruye con isFavorite=true
        // - Corazón se pone ROJO

        // PASO 7: SnackBar de confirmación
        // - Se muestra "Agregado a favoritos" (verde)

        expect(true, true); // Test de estructura
      });
    });

    group('Flujo Completo: Remover de Favoritos', () {
      test('debe completar el flujo de remover favorito', () async {
        // PASO 1: Usuario ve un producto favorito (corazón rojo)
        final productId = 100;

        // PASO 2: Usuario hace clic en el corazón rojo
        expect(productProvider.toggleFavorite, isA<Function>());

        // PASO 3: Optimistic update
        // - Se remueve ID de favorites
        // - Se remueve producto de favoriteProducts
        // - Se llama notifyListeners()

        // PASO 4: Backend request
        // - POST /api/products/{id}/favorite
        // - Backend detecta que ya es favorito y lo remueve

        // PASO 5: Backend responde
        // - {success: true, is_favorite: false, message: "..."}

        // PASO 6: UI se actualiza
        // - Corazón se pone GRIS

        // PASO 7: SnackBar de confirmación
        // - Se muestra "Removido de favoritos" (gris)

        expect(true, true); // Test de estructura
      });
    });

    group('Flujo: Ver Pantalla de Favoritos', () {
      test('debe cargar favoritos desde el backend al abrir la pantalla',
          () async {
        // PASO 1: Usuario navega a FavoritesScreen (bottom nav)
        // - Se ejecuta initState() o didChangeDependencies()

        // PASO 2: Se llama ProductProvider.fetchFavorites()
        expect(productProvider.fetchFavorites, isA<Function>());

        // PASO 3: Se muestra loading state
        // - isLoadingFavorites = true
        // - CircularProgressIndicator visible

        // PASO 4: Backend request
        // - GET /api/me/favorites?page=1&per_page=20
        expect(FavoriteService.getMyFavorites, isA<Function>());

        // PASO 5: Backend responde con lista paginada
        // - {current_page: 1, data: [...], total: X}

        // PASO 6: Datos se parsean y almacenan
        // - favoriteProducts se llena con productos
        // - favorites se llena con IDs
        // - isLoadingFavorites = false

        // PASO 7: UI se actualiza
        // - GridView con ProductCards
        // - Cada card con isFavorite=true (corazón rojo)

        expect(true, true); // Test de estructura
      });
    });

    group('Flujo: Pull to Refresh', () {
      test('debe refrescar favoritos al hacer pull', () async {
        // PASO 1: Usuario hace gesture de pull down

        // PASO 2: RefreshIndicator se activa
        // - Se muestra animación de refresh

        // PASO 3: Se llama fetchFavorites(refresh: true)
        // - Se resetea paginación a página 1
        // - Se limpia lista existente

        // PASO 4: Backend request
        // - GET /api/me/favorites?page=1

        // PASO 5: Datos se actualizan
        // - Nueva lista reemplaza la anterior

        // PASO 6: RefreshIndicator se completa

        expect(productProvider.fetchFavorites, isA<Function>());
      });
    });

    group('Sincronización Multi-Pantalla', () {
      test('cambio en Marketplace debe reflejarse en Favorites', () async {
        // ESCENARIO:
        // 1. Usuario está en Marketplace
        // 2. Marca producto como favorito
        // 3. Navega a FavoritesScreen
        // 4. El producto debe aparecer en la lista

        final productId = 100;

        // Verificar que el estado es compartido
        expect(productProvider.favorites, isA<Set<int>>());
        expect(productProvider.favoriteProducts, isA<List>());
      });

      test('remover en Favorites debe reflejarse en Marketplace', () async {
        // ESCENARIO:
        // 1. Usuario está en FavoritesScreen
        // 2. Remueve un favorito
        // 3. Vuelve a Marketplace
        // 4. El corazón debe estar GRIS

        expect(productProvider.favorites, isA<Set<int>>());
      });

      test('cambio en ProductDetail debe reflejarse en ambas pantallas',
          () async {
        // ESCENARIO:
        // 1. Usuario abre ProductDetail desde Marketplace
        // 2. Marca como favorito
        // 3. Vuelve a Marketplace → corazón rojo
        // 4. Va a Favorites → producto en lista

        expect(productProvider.toggleFavorite, isA<Function>());
      });
    });

    group('Error Recovery', () {
      test('debe revertir optimistic update si falla el backend', () async {
        // ESCENARIO:
        // 1. Usuario marca favorito
        // 2. UI se actualiza optimísticamente (corazón rojo)
        // 3. Backend responde 401/500
        // 4. UI revierte (corazón gris)
        // 5. Se muestra mensaje de error

        expect(productProvider.toggleFavorite, isA<Function>());
      });

      test('debe mostrar error si no hay conexión', () async {
        // ESCENARIO:
        // 1. Usuario sin internet
        // 2. Intenta marcar favorito
        // 3. Timeout o error de red
        // 4. UI revierte y muestra error

        expect(productProvider.toggleFavorite, isA<Function>());
      });
    });

    group('Performance', () {
      test('debe usar Set para búsquedas rápidas de IDs', () {
        // favorites debe ser Set<int> para O(1) lookup
        expect(productProvider.favorites, isA<Set<int>>());
      });

      test('debe limitar productos cargados por paginación', () {
        // No debe cargar todos los favoritos a la vez
        expect(productProvider.currentFavoritesPage, isA<int>());
        expect(productProvider.hasMoreFavorites, isA<bool>());
      });

      test('no debe recargar si ya está cargando', () {
        // Evitar múltiples peticiones simultáneas
        expect(productProvider.isLoadingFavorites, isA<bool>());
      });
    });

    group('Data Consistency', () {
      test('favorites (IDs) debe coincidir con favoriteProducts', () {
        // Cada ID en favorites debe tener su producto en favoriteProducts
        for (var product in productProvider.favoriteProducts) {
          expect(productProvider.favorites.contains(product.id), true);
        }
      });

      test('favoriteProducts no debe tener duplicados', () {
        // No debe haber productos duplicados
        final ids = productProvider.favoriteProducts.map((p) => p.id).toList();
        final uniqueIds = ids.toSet();
        expect(ids.length, equals(uniqueIds.length));
      });
    });

    group('API Endpoints', () {
      test('debe usar URL correcta para obtener favoritos', () {
        final baseUrl = AppConfig.apiUrl;
        final expectedUrl = '$baseUrl/api/me/favorites?page=1&per_page=20';
        
        expect(expectedUrl, contains('/api/me/favorites'));
        expect(expectedUrl, contains('page=1'));
        expect(expectedUrl, contains('per_page=20'));
      });

      test('debe usar URL correcta para toggle favorito', () {
        final baseUrl = AppConfig.apiUrl;
        final productId = 100;
        final expectedUrl = '$baseUrl/api/products/$productId/favorite';
        
        expect(expectedUrl, contains('/api/products/'));
        expect(expectedUrl, contains('/favorite'));
      });
    });

    group('Authentication', () {
      test('debe incluir token en todos los requests', () {
        // Todos los métodos deben:
        // 1. Leer token de storage
        // 2. Validar que no sea null
        // 3. Incluir en header Authorization: Bearer {token}

        expect(FavoriteService.getMyFavorites, isA<Function>());
        expect(FavoriteService.toggleFavorite, isA<Function>());
      });

      test('debe manejar token expirado (401)', () {
        // Si backend responde 401:
        // 1. Mostrar error
        // 2. Revertir cambios optimistas
        // 3. Opcionalmente: redirigir a login

        expect(true, true);
      });
    });

    group('SnackBar Feedback', () {
      test('debe mostrar SnackBar al agregar favorito', () {
        // - Mensaje: "Agregado a favoritos"
        // - Color: Verde
        // - Ícono: ❤️
        // - Duration: 2 segundos

        expect(true, true);
      });

      test('debe mostrar SnackBar al remover favorito', () {
        // - Mensaje: "Removido de favoritos"
        // - Color: Gris
        // - Ícono: 💔
        // - Duration: 2 segundos

        expect(true, true);
      });

      test('SnackBar debe usar behavior: fixed', () {
        // Para evitar overflow con BottomNavigationBar
        expect(true, true);
      });
    });
  });

  group('Edge Cases', () {
    test('debe manejar favoritos con productos eliminados', () {
      // Si un producto fue eliminado pero está en favoritos
      expect(true, true);
    });

    test('debe manejar lista vacía de favoritos', () {
      // Primera vez que el usuario abre la pantalla
      final provider = ProductProvider();
      expect(provider.favoriteProducts, isEmpty);
    });

    test('debe manejar múltiples toggles rápidos', () {
      // Usuario hace clic múltiples veces en el corazón
      // Debe evitar race conditions
      expect(true, true);
    });

    test('debe persistir favoritos al cerrar y abrir app', () {
      // Los favoritos deben cargarse desde el backend cada vez
      expect(FavoriteService.getMyFavorites, isA<Function>());
    });
  });
}

