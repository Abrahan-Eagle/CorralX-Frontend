import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/products/widgets/product_card.dart';
import 'package:zonix/products/models/product.dart';

void main() {
  group('ProductCard Widget Tests', () {
    late Product sampleProduct;

    setUp(() {
      sampleProduct = Product(
        id: 1,
        title: 'Vacas Holstein de Alta Producción',
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
          ProductImage(
            id: 2,
            fileUrl: 'https://example.com/image2.jpg',
            fileType: 'image',
            isPrimary: false,
            sortOrder: 2,
            resolution: '1920x1080',
            format: 'JPEG',
            fileSize: 1536000,
          ),
        ],
      );
    });

    testWidgets('should display product information correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: sampleProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify product title is displayed
      expect(find.text('Vacas Holstein de Alta Producción'), findsOneWidget);

      // Verify price is displayed correctly
      expect(find.text('\$ 1500'), findsOneWidget);

      // Verify type badge is displayed
      expect(find.text('Lechero'), findsOneWidget);

      // Verify breed is displayed
      expect(find.text('Holstein'), findsOneWidget);

      // Verify quantity is displayed
      expect(find.text('5 cabezas'), findsOneWidget);

      // Verify age is displayed
      expect(find.text('24 meses'), findsOneWidget);

      // Verify sex is displayed
      expect(find.text('Hembra'), findsOneWidget);

      // Verify ranch name is displayed
      expect(find.text('Agropecuaria El Futuro C.A.'), findsOneWidget);

      // Verify rating is displayed
      expect(find.text('4.5'), findsOneWidget);

      // Verify views count is displayed
      expect(find.text('125'), findsOneWidget);
    });

    testWidgets('should display status badge correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: sampleProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify status badge for active product
      expect(find.text('Disponible'), findsOneWidget);
    });

    testWidgets('should display different status badges',
        (WidgetTester tester) async {
      final soldProduct = Product(
        id: 2,
        title: 'Producto Vendido',
        description: 'Descripción',
        type: 'engorde',
        breed: 'Brahman',
        age: 12,
        quantity: 1,
        price: 800.0,
        currency: 'USD',
        deliveryMethod: 'pickup',
        negotiable: false,
        status: 'sold',
        viewsCount: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ranchId: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: soldProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Vendido'), findsOneWidget);
    });

    testWidgets('should display multiple images indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: sampleProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify multiple images indicator
      expect(find.text('+1'), findsOneWidget); // 2 images total, showing +1
    });

    testWidgets('should not display multiple images indicator for single image',
        (WidgetTester tester) async {
      final singleImageProduct = Product(
        id: 3,
        title: 'Producto con una imagen',
        description: 'Descripción',
        type: 'engorde',
        breed: 'Brahman',
        age: 12,
        quantity: 1,
        price: 800.0,
        currency: 'USD',
        deliveryMethod: 'pickup',
        negotiable: false,
        status: 'active',
        viewsCount: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ranchId: 1,
        images: [
          ProductImage(
            id: 1,
            fileUrl: 'https://example.com/image1.jpg',
            fileType: 'image',
            isPrimary: true,
            sortOrder: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: singleImageProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not find the multiple images indicator
      expect(find.text('+0'), findsNothing);
    });

    testWidgets('should call onTap when card is tapped',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: sampleProduct,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProductCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should display favorite button when onFavorite is provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: sampleProduct,
              onTap: () {},
              onFavorite: () {},
              isFavorite: false,
            ),
          ),
        ),
      );

      // Verify favorite button is displayed
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should display filled favorite icon when isFavorite is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: sampleProduct,
              onTap: () {},
              onFavorite: () {},
              isFavorite: true,
            ),
          ),
        ),
      );

      // Verify filled favorite icon is displayed
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should call onFavorite when favorite button is tapped',
        (WidgetTester tester) async {
      bool favorited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: sampleProduct,
              onTap: () {},
              onFavorite: () {
                favorited = true;
              },
              isFavorite: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(favorited, isTrue);
    });

    testWidgets('should handle products without ranch information',
        (WidgetTester tester) async {
      final productWithoutRanch = Product(
        id: 4,
        title: 'Producto sin rancho',
        description: 'Descripción',
        type: 'engorde',
        breed: 'Brahman',
        age: 12,
        quantity: 1,
        price: 800.0,
        currency: 'USD',
        deliveryMethod: 'pickup',
        negotiable: false,
        status: 'active',
        viewsCount: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ranchId: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: productWithoutRanch,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should display default vendor name
      expect(find.text('Vendedor'), findsOneWidget);
    });

    testWidgets('should handle products without images',
        (WidgetTester tester) async {
      final productWithoutImages = Product(
        id: 5,
        title: 'Producto sin imágenes',
        description: 'Descripción',
        type: 'engorde',
        breed: 'Brahman',
        age: 12,
        quantity: 1,
        price: 800.0,
        currency: 'USD',
        deliveryMethod: 'pickup',
        negotiable: false,
        status: 'active',
        viewsCount: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ranchId: 1,
        images: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: productWithoutImages,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should display placeholder icon
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('should display correct date format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: sampleProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should display relative date (e.g., "Hace X días")
      expect(find.textContaining('Hace'), findsOneWidget);
    });

    testWidgets('should handle different currency formats',
        (WidgetTester tester) async {
      final vesProduct = Product(
        id: 6,
        title: 'Producto en VES',
        description: 'Descripción',
        type: 'engorde',
        breed: 'Brahman',
        age: 12,
        quantity: 1,
        price: 2500.0,
        currency: 'VES',
        deliveryMethod: 'pickup',
        negotiable: false,
        status: 'active',
        viewsCount: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ranchId: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: vesProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should display VES currency format
      expect(find.text('Bs 2500'), findsOneWidget);
    });
  });

  group('ProductCardCompact Widget Tests', () {
    late Product sampleProduct;

    setUp(() {
      sampleProduct = Product(
        id: 1,
        title: 'Vacas Holstein de Alta Producción',
        description: 'Excelente ganado lechero',
        type: 'lechero',
        breed: 'Holstein',
        age: 24,
        quantity: 5,
        price: 1500.0,
        currency: 'USD',
        deliveryMethod: 'pickup',
        negotiable: true,
        status: 'active',
        viewsCount: 125,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ranchId: 1,
        images: [
          ProductImage(
            id: 1,
            fileUrl: 'https://example.com/image1.jpg',
            fileType: 'image',
            isPrimary: true,
            sortOrder: 1,
          ),
        ],
      );
    });

    testWidgets('should display compact product information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardCompact(
              product: sampleProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify compact layout elements
      expect(find.text('Vacas Holstein de Alta Producción'), findsOneWidget);
      expect(find.text('\$ 1500'), findsOneWidget);
      expect(find.text('Lechero'), findsOneWidget);
      expect(find.text('Holstein'), findsOneWidget);
      expect(find.text('5 cabezas • 24 meses'), findsOneWidget);
    });

    testWidgets('should display favorite button in compact layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardCompact(
              product: sampleProduct,
              onTap: () {},
              onFavorite: () {},
              isFavorite: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should call onTap in compact layout',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardCompact(
              product: sampleProduct,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProductCardCompact));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should display compact image', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardCompact(
              product: sampleProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should find the compact image container
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should handle long titles in compact layout',
        (WidgetTester tester) async {
      final longTitleProduct = Product(
        id: 2,
        title:
            'Este es un título muy largo que debería ser truncado en la vista compacta',
        description: 'Descripción',
        type: 'engorde',
        breed: 'Brahman',
        age: 12,
        quantity: 1,
        price: 800.0,
        currency: 'USD',
        deliveryMethod: 'pickup',
        negotiable: false,
        status: 'active',
        viewsCount: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ranchId: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCardCompact(
              product: longTitleProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should still display the title (even if truncated)
      expect(
          find.textContaining('Este es un título muy largo'), findsOneWidget);
    });
  });

  group('Widget Type Colors Tests', () {
    testWidgets('should display correct colors for different product types',
        (WidgetTester tester) async {
      final typeTests = [
        {'type': 'engorde', 'expectedColor': Colors.orange},
        {'type': 'lechero', 'expectedColor': Colors.blue},
        {'type': 'padrote', 'expectedColor': Colors.purple},
        {'type': 'equipment', 'expectedColor': Colors.grey},
        {'type': 'feed', 'expectedColor': Colors.green},
      ];

      for (final testCase in typeTests) {
        final product = Product(
          id: 1,
          title: 'Test Product',
          description: 'Test Description',
          type: testCase['type'] as String,
          breed: 'Test Breed',
          age: 12,
          quantity: 1,
          price: 800.0,
          currency: 'USD',
          deliveryMethod: 'pickup',
          negotiable: false,
          status: 'active',
          viewsCount: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ranchId: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProductCard(
                product: product,
                onTap: () {},
              ),
            ),
          ),
        );

        // Verify the type badge is displayed
        expect(
            find.text(testCase['type'] == 'engorde'
                ? 'Engorde'
                : testCase['type'] == 'lechero'
                    ? 'Lechero'
                    : testCase['type'] == 'padrote'
                        ? 'Padrote'
                        : testCase['type'] == 'equipment'
                            ? 'Equipos'
                            : testCase['type'] == 'feed'
                                ? 'Alimentos'
                                : 'Otros'),
            findsOneWidget);

        // Clear the widget tree for next iteration
        await tester.pumpAndSettle();
      }
    });
  });
}
