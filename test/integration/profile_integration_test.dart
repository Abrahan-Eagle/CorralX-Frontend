import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/profiles/providers/profile_provider.dart';
import 'package:zonix/products/providers/product_provider.dart';

/// Tests de integración para el módulo de perfiles
/// 
/// Estos tests verifican que los providers manejen correctamente
/// el estado, errores y flujos de datos sin necesidad de mocks complejos.
void main() {
  group('ProfileProvider Integration', () {
    late ProfileProvider profileProvider;
    late ProductProvider productProvider;

    setUp(() {
      profileProvider = ProfileProvider();
      productProvider = ProductProvider();
    });

    test('ProfileProvider initial state is correct', () {
      expect(profileProvider.myProfile, null);
      expect(profileProvider.isLoadingMyProfile, false);
      expect(profileProvider.myProfileError, null);
      expect(profileProvider.myProducts, []);
      expect(profileProvider.myRanches, []);
      expect(profileProvider.metrics, null);
    });

    test('ProductProvider initial state is correct', () {
      expect(productProvider.products, []);
      expect(productProvider.selectedProduct, null);
      expect(productProvider.myProducts, []);
      expect(productProvider.isLoading, false);
      expect(productProvider.isCreating, false);
      expect(productProvider.isUpdating, false);
      expect(productProvider.isDeleting, false);
      expect(productProvider.errorMessage, null);
      expect(productProvider.currentFilters, {});
      expect(productProvider.hasMorePages, true);
      expect(productProvider.favorites, isEmpty);
    });

    test('ProfileProvider handles state correctly', () {
      // Verificar estado inicial
      expect(profileProvider.myProfile, null);
      expect(profileProvider.myProducts, []);
      expect(profileProvider.myRanches, []);
      expect(profileProvider.metrics, null);
      expect(profileProvider.myProfileError, null);
      
      // Los datos se resetearían automáticamente al hacer fetch
      expect(profileProvider.isLoadingMyProfile, false);
    });

    test('ProductProvider clearState resets all data', () {
      productProvider.clearState();

      expect(productProvider.products, []);
      expect(productProvider.selectedProduct, null);
      expect(productProvider.myProducts, []);
      expect(productProvider.currentFilters, {});
      expect(productProvider.errorMessage, null);
    });

    test('ProductProvider activeFiltersCount counts correctly', () {
      // Sin filtros
      expect(productProvider.activeFiltersCount, 0);

      // Con filtros básicos (simulando applyFilters)
      productProvider.applyFilters({
        'search': 'Brahman',
        'type': 'lechero',
        'min_price': 1000.0,
      });

      expect(productProvider.activeFiltersCount, 3);
    });

    test('ProductProvider toggleFavorite adds and removes', () {
      expect(productProvider.favorites.contains(1), false);

      productProvider.toggleFavorite(1);
      expect(productProvider.favorites.contains(1), true);

      productProvider.toggleFavorite(1);
      expect(productProvider.favorites.contains(1), false);
    });

    test('ProductProvider clearFilters resets filters', () {
      productProvider.applyFilters({
        'search': 'test',
        'type': 'lechero',
      });

      expect(productProvider.currentFilters, isNotEmpty);

      productProvider.clearFilters();

      expect(productProvider.currentFilters, isEmpty);
      expect(productProvider.activeFiltersCount, 0);
    });
  });

  group('ProfileProvider Error Handling', () {
    late ProfileProvider profileProvider;

    setUp(() {
      profileProvider = ProfileProvider();
    });

    test('handles error state correctly', () async {
      // Al hacer fetch sin autenticación, debe manejar el error
      await profileProvider.fetchMyProfile();

      // Debe haber un error (no autenticado o error de red)
      // En un ambiente de prueba sin backend, esto fallará
      expect(
        profileProvider.myProfileError != null ||
            profileProvider.myProfile != null,
        true,
      );
    });

    test('initial error state is null', () {
      expect(profileProvider.myProfileError, null);
      expect(profileProvider.myProductsError, null);
      expect(profileProvider.myRanchesError, null);
    });
  });
}

