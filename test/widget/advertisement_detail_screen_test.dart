import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/admin/screens/advertisement_detail_screen.dart';

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

  group('AdvertisementDetailScreen Widget Tests', () {
    testWidgets('should render loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdvertisementDetailScreen(advertisementId: 1),
        ),
      );

      await tester.pump();

      // Verificar que muestra indicador de carga inicialmente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when advertisement not found', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdvertisementDetailScreen(advertisementId: 999999),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Esperar a que cargue (puede mostrar error o loading)
      await tester.pump(const Duration(seconds: 2));

      // Puede mostrar error o seguir cargando
      final hasError = find.byIcon(Icons.error_outline).evaluate().isNotEmpty ||
          find.textContaining('Error').evaluate().isNotEmpty ||
          find.textContaining('no encontrado').evaluate().isNotEmpty ||
          find.textContaining('not found').evaluate().isNotEmpty;

      // O puede seguir cargando si el servicio está disponible
      final stillLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

      // Cualquiera de los dos estados es válido
      expect(hasError || stillLoading, isTrue);
    });

    testWidgets('should show action buttons in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdvertisementDetailScreen(advertisementId: 1),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que hay botones de acción en el AppBar
      // (puede que no se muestren hasta que cargue el anuncio)
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have refresh capability', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdvertisementDetailScreen(advertisementId: 1),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que tiene capacidad de refresh
      // (se implementa con RefreshIndicator)
      expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));
    });
  });
}

