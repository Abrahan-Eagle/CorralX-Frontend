import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zonix/main.dart';
import 'package:zonix/features/utils/user_provider.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('should complete full app initialization flow',
        (WidgetTester tester) async {
      // Arrange
      final userProvider = UserProvider();

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => userProvider),
          ],
          child: const MyApp(),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle profile creation flow',
        (WidgetTester tester) async {
      // Arrange
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => userProvider),
          ],
          child: const MyApp(),
        ),
      );

      // Act - Simulate profile creation steps
      userProvider.setProfileCreated(true);
      userProvider.setAdresseCreated(true);
      userProvider.setDocumentCreated(true);
      userProvider.setGasCylindersCreated(true);
      userProvider.setPhoneCreated(true);
      userProvider.setEmailCreated(true);

      await tester.pump();

      // Assert
      expect(userProvider.profileCreated, isTrue);
      expect(userProvider.adresseCreated, isTrue);
      expect(userProvider.documentCreated, isTrue);
      expect(userProvider.gasCylindersCreated, isTrue);
      expect(userProvider.phoneCreated, isTrue);
      expect(userProvider.emailCreated, isTrue);
    });

    testWidgets('should handle user provider state management',
        (WidgetTester tester) async {
      // Arrange
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => userProvider),
          ],
          child: const MyApp(),
        ),
      );

      // Act - Test state changes
      userProvider.setProfileCreated(true);
      await tester.pump();

      userProvider.setProfileCreated(false);
      await tester.pump();

      // Assert
      expect(userProvider.profileCreated, isFalse);
    });
  });
}
