import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zonix/main.dart';
import 'package:zonix/features/utils/user_provider.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('should render app without crashing',
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

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should show loading indicator initially',
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

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle authentication state changes',
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

      // Act - Simulate authentication
      userProvider.setProfileCreated(true);
      await tester.pump();

      // Assert
      expect(userProvider.profileCreated, isTrue);
    });
  });
}
