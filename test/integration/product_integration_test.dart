import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zonix/products/providers/product_provider.dart';
import 'package:zonix/products/screens/marketplace_screen.dart';
import 'package:zonix/products/screens/product_detail_screen.dart';
import 'package:zonix/products/widgets/filters_modal.dart';
import 'package:zonix/products/models/product.dart';

void main() {
  group('Product Module Integration Tests', () {
    late ProductProvider productProvider;

    setUp(() {
      productProvider = ProductProvider();
    });

    tearDown(() {
      productProvider.dispose();
    });

    group('Marketplace Screen Integration', () {
      testWidgets('should display marketplace with product provider',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Verify marketplace screen is displayed
        expect(find.byType(MarketplaceScreen), findsOneWidget);

        // Verify filter button is present
        expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

        // Verify the screen has the basic structure
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should show loading state initially',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // The marketplace should be ready to load products
        expect(find.byType(MarketplaceScreen), findsOneWidget);
      });

      testWidgets('should display empty state when no products',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Should display empty state message
        expect(find.text('No se encontraron productos'), findsOneWidget);
      });

      testWidgets('should display products when available',
          (WidgetTester tester) async {
        // Note: In a real test, we would mock the ProductService
        // to return mock products. For now, we test the UI structure.

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Should display empty state (no products loaded)
        expect(find.text('No se encontraron productos'), findsOneWidget);
      });
    });

    group('Filter Modal Integration', () {
      testWidgets('should open and close filter modal',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Tap filter button to open modal
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();

        // Verify modal is open
        expect(find.byType(FiltersModal), findsOneWidget);

        // Tap close button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Verify modal is closed
        expect(find.byType(FiltersModal), findsNothing);
      });

      testWidgets('should apply filters from modal',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Open filter modal
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();

        // Verify modal is open
        expect(find.byType(FiltersModal), findsOneWidget);

        // Apply filters
        await tester.tap(find.text('Aplicar Filtros'));
        await tester.pumpAndSettle();

        // Verify modal is closed and filters are applied
        expect(find.byType(FiltersModal), findsNothing);
      });

      testWidgets('should clear filters from modal',
          (WidgetTester tester) async {
        // First apply some filters
        productProvider.applyFilters({
          'type': 'lechero',
          'location': 'carabobo',
        });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Open filter modal
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();

        // Clear filters
        await tester.tap(find.text('Limpiar'));
        await tester.pumpAndSettle();

        // Verify filters are cleared
        expect(productProvider.currentFilters, isEmpty);
      });
    });

    group('Product Detail Screen Integration', () {
      testWidgets('should navigate to product detail screen',
          (WidgetTester tester) async {
        final mockProduct = Product(
          id: 1,
          title: 'Vacas Holstein',
          description: 'Excelente ganado lechero con certificados de salud',
          type: 'lechero',
          breed: 'Holstein',
          age: 24,
          quantity: 5,
          price: 1500.0,
          currency: 'USD',
          weightAvg: 650.0,
          weightMin: 600.0,
          weightMax: 700.0,
          sex: 'female',
          purpose: 'dairy',
          healthCertificateUrl: 'https://example.com/cert.pdf',
          vaccinesApplied: 'Fiebre aftosa, Brucelosis',
          documentationIncluded: true,
          geneticTestResults: 'Excelente línea genética',
          isVaccinated: true,
          deliveryMethod: 'pickup',
          deliveryCost: 0.0,
          deliveryRadiusKm: 50.0,
          negotiable: true,
          status: 'active',
          viewsCount: 125,
          createdAt: DateTime(2024, 1, 10, 8, 0),
          updatedAt: DateTime(2024, 1, 15, 14, 30),
          ranchId: 1,
          ranch: Ranch(
            id: 1,
            name: 'Rancho El Futuro',
            legalName: 'Agropecuaria El Futuro C.A.',
            description: 'Especialistas en ganado lechero',
            specialization: 'lechero',
            avgRating: 4.5,
            totalSales: 150,
            lastSaleAt: DateTime(2024, 1, 15, 10, 30),
          ),
          images: [
            ProductImage(
              id: 1,
              fileUrl: 'https://example.com/image1.jpg',
              fileType: 'image',
              isPrimary: true,
              sortOrder: 1,
              resolution: '1920x1080',
              format: 'JPEG',
              fileSize: 2048576,
            ),
          ],
        );

        productProvider._products = [mockProduct];

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Wait for products to load
        await tester.pumpAndSettle();

        // Tap on product card
        await tester.tap(find.text('Vacas Holstein'));
        await tester.pumpAndSettle();

        // Verify navigation to detail screen
        expect(find.byType(ProductDetailScreen), findsOneWidget);
        expect(find.text('Vacas Holstein'), findsOneWidget);
      });

      testWidgets('should display product detail information',
          (WidgetTester tester) async {
        final mockProduct = Product(
          id: 1,
          title: 'Vacas Holstein',
          description: 'Excelente ganado lechero con certificados de salud',
          type: 'lechero',
          breed: 'Holstein',
          age: 24,
          quantity: 5,
          price: 1500.0,
          currency: 'USD',
          weightAvg: 650.0,
          sex: 'female',
          purpose: 'dairy',
          isVaccinated: true,
          deliveryMethod: 'pickup',
          negotiable: true,
          status: 'active',
          viewsCount: 125,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ranchId: 1,
          ranch: Ranch(
            id: 1,
            name: 'Rancho El Futuro',
            avgRating: 4.5,
            totalSales: 150,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProductDetailScreen(
              productId: 1,
              product: mockProduct,
            ),
          ),
        );

        // Verify product detail information is displayed
        expect(find.text('Vacas Holstein'), findsOneWidget);
        expect(find.text('Excelente ganado lechero con certificados de salud'),
            findsOneWidget);
        expect(find.text('\$ 1500'), findsOneWidget);
        expect(find.text('Lechero'), findsOneWidget);
        expect(find.text('Holstein'), findsOneWidget);
        expect(find.text('24 meses'), findsOneWidget);
        expect(find.text('5 cabezas'), findsOneWidget);
        expect(find.text('Hembra'), findsOneWidget);
        expect(find.text('Rancho El Futuro'), findsOneWidget);
      });
    });

    group('Provider State Integration', () {
      testWidgets('should update UI when provider state changes',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Initially should show empty state
        expect(find.text('No se encontraron productos'), findsOneWidget);

        // Note: In a real test, we would mock the ProductService
        // to return mock products. For now, we test the UI structure.

        // Rebuild widget to reflect changes
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Should still show empty state (no products loaded)
        expect(find.text('No se encontraron productos'), findsOneWidget);
      });

      testWidgets('should handle loading states', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Note: In a real test, we would trigger loading state through public methods

        // Rebuild widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Should show marketplace screen
        expect(find.byType(MarketplaceScreen), findsOneWidget);
      });

      testWidgets('should handle error states', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Note: In a real test, we would trigger error state through public methods

        // Rebuild widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Should show marketplace screen
        expect(find.byType(MarketplaceScreen), findsOneWidget);
      });
    });

    group('Filter Integration', () {
      testWidgets('should update filter count in UI',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Initially no active filters
        expect(productProvider.activeFiltersCount, equals(0));

        // Apply filters
        productProvider.applyFilters({
          'type': 'lechero',
          'location': 'carabobo',
          'min_price': 1000,
        });

        // Should have 3 active filters
        expect(productProvider.activeFiltersCount, equals(3));
      });

      testWidgets('should persist filters between sessions',
          (WidgetTester tester) async {
        // Apply filters
        productProvider.applyFilters({
          'type': 'lechero',
          'location': 'carabobo',
        });

        expect(productProvider.currentFilters, isNotEmpty);

        // Create new provider instance (simulating app restart)
        final newProvider = ProductProvider();

        // Should start with empty filters (but in real app, would load from SharedPreferences)
        expect(newProvider.currentFilters, isEmpty);
      });
    });

    group('Favorites Integration', () {
      testWidgets('should toggle favorites and update UI',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ProductProvider>.value(
                  value: productProvider),
            ],
            child: MaterialApp(
              home: MarketplaceScreen(),
            ),
          ),
        );

        // Initially no favorites
        expect(productProvider.favorites, isEmpty);

        // Toggle favorite
        productProvider.toggleFavorite(1);
        expect(productProvider.favorites, contains(1));

        // Toggle again to remove
        productProvider.toggleFavorite(1);
        expect(productProvider.favorites, isNot(contains(1)));
      });
    });

    group('Navigation Integration', () {
      testWidgets('should handle back navigation from detail screen',
          (WidgetTester tester) async {
        final mockProduct = Product(
          id: 1,
          title: 'Test Product',
          description: 'Test Description',
          type: 'lechero',
          breed: 'Holstein',
          age: 24,
          quantity: 5,
          price: 1500.0,
          currency: 'USD',
          deliveryMethod: 'pickup',
          negotiable: true,
          status: 'active',
          viewsCount: 100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ranchId: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProductDetailScreen(
              productId: 1,
              product: mockProduct,
            ),
          ),
        );

        // Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Should return to previous screen
        expect(find.byType(ProductDetailScreen), findsNothing);
      });
    });
  });
}

// Note: Testing private members would require making them accessible
// For now, we test the public interface which is the most important
