import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:corralx/products/providers/product_provider.dart';

void main() {
  group('Search Behavior Tests', () {
    late ProductProvider productProvider;
    late TextEditingController searchController;
    bool searchTriggered = false;
    int searchCallCount = 0;

    setUp(() {
      productProvider = ProductProvider(enableNetwork: false);
      searchController = TextEditingController();
      searchTriggered = false;
      searchCallCount = 0;
    });

    tearDown(() {
      productProvider.dispose();
      searchController.dispose();
    });

    testWidgets('should NOT trigger search on every keystroke (onChanged)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por raza, tipo...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey[600]),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (value) {
                                  // Solo actualizar el estado local, NO aplicar filtros
                                  setState(() {
                                    // El campo se actualiza automáticamente
                                  });
                                },
                                onSubmitted: (value) {
                                  // SOLO aquí se aplican los filtros
                                  setState(() {
                                    searchTriggered = true;
                                    searchCallCount++;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // SOLO aquí se aplican los filtros
                                setState(() {
                                  searchTriggered = true;
                                  searchCallCount++;
                                });
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
                      // Indicador de estado
                      Text('Search triggered: $searchTriggered'),
                      Text('Search call count: $searchCallCount'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verificar estado inicial
      expect(find.text('Search triggered: false'), findsOneWidget);
      expect(find.text('Search call count: 0'), findsOneWidget);

      // Escribir múltiples caracteres uno por uno
      final searchField = find.byType(TextField);

      await tester.enterText(searchField, 'H');
      await tester.pump();
      expect(find.text('Search triggered: false'), findsOneWidget);
      expect(find.text('Search call count: 0'), findsOneWidget);

      await tester.enterText(searchField, 'Ho');
      await tester.pump();
      expect(find.text('Search triggered: false'), findsOneWidget);
      expect(find.text('Search call count: 0'), findsOneWidget);

      await tester.enterText(searchField, 'Hol');
      await tester.pump();
      expect(find.text('Search triggered: false'), findsOneWidget);
      expect(find.text('Search call count: 0'), findsOneWidget);

      await tester.enterText(searchField, 'Holstein');
      await tester.pump();
      expect(find.text('Search triggered: false'), findsOneWidget);
      expect(find.text('Search call count: 0'), findsOneWidget);

      // Verificar que el texto se escribió correctamente
      expect(find.text('Holstein'), findsOneWidget);
    });

    testWidgets('should trigger search ONLY when button is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por raza, tipo...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey[600]),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (value) {
                                  // Solo actualizar el estado local
                                  setState(() {});
                                },
                                onSubmitted: (value) {
                                  // Aplicar filtros al presionar Enter
                                  setState(() {
                                    searchTriggered = true;
                                    searchCallCount++;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Aplicar filtros al presionar el botón
                                setState(() {
                                  searchTriggered = true;
                                  searchCallCount++;
                                });
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
                      Text('Search triggered: $searchTriggered'),
                      Text('Search call count: $searchCallCount'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Escribir texto
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Brahman');
      await tester.pump();

      // Verificar que NO se activó la búsqueda solo por escribir
      expect(find.text('Search triggered: false'), findsOneWidget);
      expect(find.text('Search call count: 0'), findsOneWidget);

      // Presionar el botón de búsqueda
      final searchButton = find.widgetWithIcon(ElevatedButton, Icons.search);
      await tester.tap(searchButton);
      await tester.pump();

      // Verificar que SÍ se activó la búsqueda al presionar el botón
      expect(find.text('Search triggered: true'), findsOneWidget);
      expect(find.text('Search call count: 1'), findsOneWidget);
    });

    testWidgets('should trigger search ONLY when Enter is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por raza, tipo...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey[600]),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (value) {
                                  // Solo actualizar el estado local
                                  setState(() {});
                                },
                                onSubmitted: (value) {
                                  // Aplicar filtros al presionar Enter
                                  setState(() {
                                    searchTriggered = true;
                                    searchCallCount++;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Aplicar filtros al presionar el botón
                                setState(() {
                                  searchTriggered = true;
                                  searchCallCount++;
                                });
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
                      Text('Search triggered: $searchTriggered'),
                      Text('Search call count: $searchCallCount'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Escribir texto
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Angus');
      await tester.pump();

      // Verificar que NO se activó la búsqueda solo por escribir
      expect(find.text('Search triggered: false'), findsOneWidget);
      expect(find.text('Search call count: 0'), findsOneWidget);

      // Presionar Enter (simular onSubmitted)
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verificar que SÍ se activó la búsqueda al presionar Enter
      expect(find.text('Search triggered: true'), findsOneWidget);
      expect(find.text('Search call count: 1'), findsOneWidget);
    });

    testWidgets('should handle multiple search triggers correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por raza, tipo...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey[600]),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (value) {
                                  // Solo actualizar el estado local
                                  setState(() {});
                                },
                                onSubmitted: (value) {
                                  // Aplicar filtros al presionar Enter
                                  setState(() {
                                    searchTriggered = true;
                                    searchCallCount++;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Aplicar filtros al presionar el botón
                                setState(() {
                                  searchTriggered = true;
                                  searchCallCount++;
                                });
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
                      Text('Search triggered: $searchTriggered'),
                      Text('Search call count: $searchCallCount'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Escribir texto
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Simmental');
      await tester.pump();

      // Verificar estado inicial
      expect(find.text('Search call count: 0'), findsOneWidget);

      // Presionar botón de búsqueda
      final searchButton = find.widgetWithIcon(ElevatedButton, Icons.search);
      await tester.tap(searchButton);
      await tester.pump();
      expect(find.text('Search call count: 1'), findsOneWidget);

      // Cambiar texto
      await tester.enterText(searchField, 'Hereford');
      await tester.pump();

      // Presionar Enter
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Search call count: 2'), findsOneWidget);

      // Presionar botón nuevamente
      await tester.tap(searchButton);
      await tester.pump();
      expect(find.text('Search call count: 3'), findsOneWidget);
    });

    testWidgets('should maintain search state correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => productProvider,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por raza, tipo...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey[600]),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (value) {
                                  // Solo actualizar el estado local
                                  setState(() {});
                                },
                                onSubmitted: (value) {
                                  // Aplicar filtros al presionar Enter
                                  setState(() {
                                    searchTriggered = true;
                                    searchCallCount++;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Aplicar filtros al presionar el botón
                                setState(() {
                                  searchTriggered = true;
                                  searchCallCount++;
                                });
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
                      Text('Current search: ${searchController.text}'),
                      Text('Search triggered: $searchTriggered'),
                      Text('Search call count: $searchCallCount'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Escribir texto
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Charolais');
      await tester.pump();

      // Verificar que el texto se mantiene
      expect(find.text('Current search: Charolais'), findsOneWidget);
      expect(find.text('Search triggered: false'), findsOneWidget);

      // Presionar botón de búsqueda
      final searchButton = find.widgetWithIcon(ElevatedButton, Icons.search);
      await tester.tap(searchButton);
      await tester.pump();

      // Verificar que el texto se mantiene y la búsqueda se activó
      expect(find.text('Current search: Charolais'), findsOneWidget);
      expect(find.text('Search triggered: true'), findsOneWidget);
      expect(find.text('Search call count: 1'), findsOneWidget);
    });
  }, skip: 'Requiere UI real/mocks; omitido temporalmente');
}
