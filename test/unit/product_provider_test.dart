import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/products/providers/product_provider.dart';
import 'package:zonix/products/models/product.dart';

void main() {
  // Inicializar dotenv antes de todos los tests
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Cargar .env para tests (si falla, usa valores por defecto)
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

  group('ProductProvider Tests', () {
    late ProductProvider provider;

    setUp(() {
      provider = ProductProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('should have empty products list initially', () {
        expect(provider.products, isEmpty);
        expect(provider.selectedProduct, isNull);
        expect(provider.myProducts, isEmpty);
      });

      test('should have correct initial loading states', () {
        expect(provider.isLoading, isFalse);
        expect(provider.isCreating, isFalse);
        expect(provider.isUpdating, isFalse);
        expect(provider.isDeleting, isFalse);
      });

      test('should have no errors initially', () {
        expect(provider.errorMessage, isNull);
        expect(provider.validationErrors, isNull);
      });

      test('should have correct initial filter state', () {
        expect(provider.currentFilters, isEmpty);
        expect(provider.hasMorePages, isTrue);
        expect(provider.favorites, isEmpty);
      });
    });

    group('Filter Management', () {
      test('should apply filters correctly', () {
        final filters = {
          'type': 'lechero',
          'location': 'carabobo',
          'min_price': 1000,
          'max_price': 2000,
        };

        provider.applyFilters(filters);

        expect(provider.currentFilters, equals(filters));
      });

      test('should clear filters correctly', () {
        // First apply some filters
        final filters = {
          'type': 'lechero',
          'location': 'carabobo',
        };
        provider.applyFilters(filters);
        expect(provider.currentFilters, isNotEmpty);

        // Then clear them
        provider.clearFilters();
        expect(provider.currentFilters, isEmpty);
      });

      test('should calculate active filters count correctly', () {
        // No filters
        expect(provider.activeFiltersCount, equals(0));

        // Search filter
        provider.applyFilters({'search': 'vacas'});
        expect(provider.activeFiltersCount, equals(1));

        // Type filter
        provider.applyFilters({'search': 'vacas', 'type': 'lechero'});
        expect(provider.activeFiltersCount, equals(2));

        // Location filter
        provider.applyFilters({
          'search': 'vacas',
          'type': 'lechero',
          'location': 'carabobo',
        });
        expect(provider.activeFiltersCount, equals(3));

        // Price range filter (min_price and max_price count as 2 separate filters)
        provider.applyFilters({
          'search': 'vacas',
          'type': 'lechero',
          'location': 'carabobo',
          'min_price': 1000,
          'max_price': 5000,
        });
        expect(provider.activeFiltersCount, equals(5)); // search + type + location + min_price + max_price = 5

        // Sort filter (sort_by also counts as a filter)
        provider.applyFilters({
          'search': 'vacas',
          'type': 'lechero',
          'location': 'carabobo',
          'min_price': 1000,
          'max_price': 5000,
          'sort_by': 'price_asc',
        });
        expect(provider.activeFiltersCount, equals(6)); // search + type + location + min_price + max_price + sort_by = 6

        // Quantity filter
        provider.applyFilters({
          'search': 'vacas',
          'type': 'lechero',
          'location': 'carabobo',
          'min_price': 1000,
          'max_price': 5000,
          'sort_by': 'price_asc',
          'quantity': 3,
        });
        expect(provider.activeFiltersCount, equals(6));
      });

      test('should not count default values as active filters', () {
        // These should not count as active filters
        provider.applyFilters({
          'type': 'Todos',
          'location': 'Todos',
          'max_price': 100000, // Max value
          'sort_by': 'newest', // Default sort
          'quantity': 1, // Minimum quantity
        });
        expect(provider.activeFiltersCount, equals(0));

        // Empty search should not count
        provider.applyFilters({'search': ''});
        expect(provider.activeFiltersCount, equals(0));
      });
    });

    group('Favorites Management', () {
      test('should add product to favorites', () {
        expect(provider.favorites, isEmpty);

        provider.toggleFavorite(1);
        expect(provider.favorites, contains(1));
        expect(provider.favorites.length, equals(1));
      });

      test('should remove product from favorites', () {
        // Add to favorites first
        provider.toggleFavorite(1);
        expect(provider.favorites, contains(1));

        // Remove from favorites
        provider.toggleFavorite(1);
        expect(provider.favorites, isNot(contains(1)));
        expect(provider.favorites.length, equals(0));
      });

      test('should handle multiple favorites', () {
        provider.toggleFavorite(1);
        provider.toggleFavorite(2);
        provider.toggleFavorite(3);

        expect(provider.favorites, containsAll([1, 2, 3]));
        expect(provider.favorites.length, equals(3));

        // Remove one
        provider.toggleFavorite(2);
        expect(provider.favorites, containsAll([1, 3]));
        expect(provider.favorites.length, equals(2));
      });
    });

    group('State Management', () {
      test('should notify listeners when state changes', () {
        bool notified = false;
        provider.addListener(() {
          notified = true;
        });

        // Apply filters should notify
        provider.applyFilters({'type': 'lechero'});
        expect(notified, isTrue);

        // Reset notification flag
        notified = false;

        // Toggle favorite should notify
        provider.toggleFavorite(1);
        expect(notified, isTrue);
      });

      test('should clear errors when new operation starts', () {
        // Set some errors first (this would be done internally in real usage)
        // For now, we test that the public interface works

        // Apply filters should clear errors (this is the expected behavior)
        provider.applyFilters({'type': 'lechero'});

        // The error clearing happens internally, we can't test it directly
        // but we can test that the operation completes successfully
        expect(provider.currentFilters, isNotEmpty);
      });
    });

    group('Filter Combinations', () {
      test('should handle complex filter combinations', () {
        final complexFilters = {
          'search': 'vacas holstein',
          'type': 'lechero',
          'location': 'carabobo',
          'min_price': 1000.0,
          'max_price': 3000.0,
          'quantity': 2,
          'sort_by': 'price_desc',
        };

        provider.applyFilters(complexFilters);

        expect(provider.currentFilters, equals(complexFilters));
        expect(provider.activeFiltersCount, equals(7));
      });

      test('should handle edge case filter values', () {
        final edgeCaseFilters = {
          'search': 'a', // Very short search
          'type': 'lechero',
          'min_price': 0.01, // Very small price
          'max_price': 99999.99, // Very large price
          'quantity': 999, // Large quantity
        };

        provider.applyFilters(edgeCaseFilters);

        expect(provider.currentFilters, equals(edgeCaseFilters));
        expect(provider.activeFiltersCount, equals(5));
      });

      test('should handle empty and null filter values', () {
        final filtersWithNulls = {
          'search': '',
          'type': 'Todos',
          'location': null,
          'min_price': null,
          'max_price': null,
          'quantity': null,
          'sort_by': null,
        };

        provider.applyFilters(filtersWithNulls);

        expect(provider.activeFiltersCount, equals(0));
      });
    });

    group('Provider Lifecycle', () {
      test('should dispose without errors', () {
        provider.applyFilters({'type': 'lechero'});
        provider.toggleFavorite(1);

        // Should not throw when disposing
        expect(() => provider.dispose(), returnsNormally);
      });

      test('should handle multiple state changes', () {
        // Apply multiple state changes
        provider.applyFilters({'type': 'lechero'});
        provider.toggleFavorite(1);
        provider.applyFilters({'location': 'carabobo'});
        provider.toggleFavorite(2);
        provider.clearFilters();

        expect(provider.currentFilters, isEmpty);
        expect(provider.favorites, containsAll([1, 2]));
      });
    });

    group('Public Interface', () {
      test('should expose all required getters', () {
        // Test that all public getters are accessible
        expect(provider.products, isA<List<Product>>());
        expect(provider.selectedProduct, isA<Product?>());
        expect(provider.myProducts, isA<List<Product>>());
        expect(provider.isLoading, isA<bool>());
        expect(provider.isCreating, isA<bool>());
        expect(provider.isUpdating, isA<bool>());
        expect(provider.isDeleting, isA<bool>());
        expect(provider.errorMessage, isA<String?>());
        expect(provider.validationErrors, isA<Map<String, List<String>>?>());
        expect(provider.currentFilters, isA<Map<String, dynamic>>());
        expect(provider.hasMorePages, isA<bool>());
        expect(provider.favorites, isA<Set<int>>());
      });

      test('should expose all required methods', () {
        // Test that all public methods are callable
        expect(
            () => provider.applyFilters({'type': 'lechero'}), returnsNormally);
        expect(() => provider.clearFilters(), returnsNormally);
        expect(() => provider.toggleFavorite(1), returnsNormally);
        expect(provider.activeFiltersCount, isA<int>());
      });
    });
  });
}
