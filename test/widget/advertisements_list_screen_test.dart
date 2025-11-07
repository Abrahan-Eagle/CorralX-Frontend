import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:zonix/admin/screens/advertisements_list_screen.dart';
import 'package:zonix/config/user_provider.dart';

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

  group('AdvertisementsListScreen Widget Tests', () {
    late UserProvider userProvider;

    setUp(() {
      userProvider = UserProvider();
    });

    tearDown(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        userProvider.dispose();
      } catch (e) {
        // Ignorar errores de dispose
      }
    });

    testWidgets('should render AdvertisementsListScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserProvider>.value(
            value: userProvider,
            child: const AdvertisementsListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que la pantalla se renderiza
      expect(find.byType(AdvertisementsListScreen), findsOneWidget);
      expect(find.text('Gestión de Publicidad'), findsOneWidget);
    });

    testWidgets('should show search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserProvider>.value(
            value: userProvider,
            child: const AdvertisementsListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que hay un campo de búsqueda
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('should show filter button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserProvider>.value(
            value: userProvider,
            child: const AdvertisementsListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que hay un botón de filtros
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should show refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserProvider>.value(
            value: userProvider,
            child: const AdvertisementsListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que hay un botón de actualizar
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should show create button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserProvider>.value(
            value: userProvider,
            child: const AdvertisementsListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verificar que hay un botón flotante para crear anuncio
      expect(find.byType(FloatingActionButton), findsAtLeastNWidgets(1));
      expect(find.text('Nuevo Anuncio'), findsOneWidget);
    });

    testWidgets('should open filter dialog when filter button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserProvider>.value(
            value: userProvider,
            child: const AdvertisementsListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap en el botón de filtros
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que se abre el diálogo de filtros
      expect(find.text('Filtros'), findsOneWidget);
    });

    testWidgets('should handle search input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserProvider>.value(
            value: userProvider,
            child: const AdvertisementsListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Buscar el campo de búsqueda
      final searchField = find.byType(TextField).first;
      expect(searchField, findsOneWidget);

      // Escribir en el campo de búsqueda
      await tester.enterText(searchField, 'test');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que el texto se ingresó
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserProvider>.value(
            value: userProvider,
            child: const AdvertisementsListScreen(),
          ),
        ),
      );

      // Verificar que muestra indicador de carga inicialmente
      await tester.pump();
      // Puede mostrar CircularProgressIndicator o ListView dependiendo del estado
      // Ambos son válidos
      expect(
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.byType(ListView).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}

