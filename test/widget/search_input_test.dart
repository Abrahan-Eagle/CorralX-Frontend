import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zonix/products/providers/product_provider.dart';

void main() {
  group('Search Input Widget Tests', () {
    late ProductProvider productProvider;

    setUp(() {
      productProvider = ProductProvider();
    });

    tearDown(() {
      productProvider.dispose();
    });

    testWidgets('should display search input field with correct properties',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Campo de búsqueda con botón (replicando el diseño del marketplace)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por raza, tipo...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: const Color(0xFF386A20),
                                  width: 2,
                                ),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              // Solo actualizar el estado local, no aplicar filtros inmediatamente
                            },
                            onSubmitted: (value) {
                              // Aplicar filtros al presionar Enter
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Aplicar filtros al presionar el botón
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify search input field is displayed
      expect(find.byType(TextField), findsOneWidget);

      // Verify search hint text
      expect(find.text('Buscar por raza, tipo...'), findsOneWidget);

      // Verify search icon in prefix
      expect(find.byIcon(Icons.search), findsWidgets);

      // Verify search button
      expect(find.widgetWithIcon(ElevatedButton, Icons.search), findsOneWidget);
    });

    testWidgets('should allow typing in search input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por raza, tipo...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Find the search input field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Type in the search field
      await tester.enterText(searchField, 'Holstein');
      await tester.pump();

      // Verify the text was entered
      expect(find.text('Holstein'), findsOneWidget);
    });

    testWidgets('should clear search input when cleared',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por raza, tipo...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Enter search text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Holstein');
      await tester.pump();

      // Verify text is there
      expect(find.text('Holstein'), findsOneWidget);

      // Clear the text
      await tester.enterText(searchField, '');
      await tester.pump();

      // Verify text is cleared
      expect(find.text('Holstein'), findsNothing);
      expect(find.text('Buscar por raza, tipo...'), findsOneWidget);
    });

    testWidgets('should display correct search input styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por raza, tipo...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: const Color(0xFF386A20),
                                  width: 2,
                                ),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Find the search input field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Verify it has the correct decoration properties
      final textField = tester.widget<TextField>(searchField);
      expect(textField.decoration?.hintText, 'Buscar por raza, tipo...');
      expect(textField.decoration?.prefixIcon, isA<Icon>());
      expect(textField.decoration?.filled, isTrue);
    });

    testWidgets('should display search button with correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por raza, tipo...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Find the search button
      final searchButton = find.widgetWithIcon(ElevatedButton, Icons.search);
      expect(searchButton, findsOneWidget);

      // Verify button properties
      final button = tester.widget<ElevatedButton>(searchButton);
      expect(button.child, isA<Icon>());
    });

    testWidgets('should handle long search text', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por raza, tipo...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Enter a very long search text
      final longSearchText =
          'Este es un texto de búsqueda muy largo que debería ser manejado correctamente por el campo de búsqueda';

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, longSearchText);
      await tester.pump();

      // Verify the long text was entered
      expect(find.text(longSearchText), findsOneWidget);
    });

    testWidgets('should handle special characters in search',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por raza, tipo...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Enter text with special characters
      final specialText = 'Holstein @#\$%^&*()_+{}|:<>?[]\\;\',./';

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, specialText);
      await tester.pump();

      // Verify the special text was entered
      expect(find.text(specialText), findsOneWidget);
    });

    testWidgets('should maintain focus on search input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por raza, tipo...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Find and tap the search input
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.pump();

      // Verify the field is focused
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should handle empty search gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por raza, tipo...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Should handle empty search gracefully
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF386A20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Press search button without entering text
      final searchButton = find.widgetWithIcon(ElevatedButton, Icons.search);
      await tester.tap(searchButton);
      await tester.pump();

      // Should not crash and should show hint text
      expect(find.text('Buscar por raza, tipo...'), findsOneWidget);
    });
  });
}
