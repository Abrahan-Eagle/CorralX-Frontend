import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/shared/utils/user_provider.dart';

void main() {
  group('UserProvider Tests', () {
    late UserProvider userProvider;

    setUp(() {
      userProvider = UserProvider();
    });

    test('should initialize with default values', () {
      expect(userProvider.isAuthenticated, isFalse);
      expect(userProvider.userRole, equals(''));
      expect(userProvider.userName, equals(''));
      expect(userProvider.userEmail, equals(''));
      expect(userProvider.userPhotoUrl, equals(''));
      expect(userProvider.profileCreated, isFalse);
      expect(userProvider.userId, equals(0));
    });

    test('should have correct getters for user information', () {
      // These are read-only properties that should exist
      expect(userProvider.userName, isA<String>());
      expect(userProvider.userEmail, isA<String>());
      expect(userProvider.userPhotoUrl, isA<String>());
      expect(userProvider.userId, isA<int>());
      expect(userProvider.userGoogleId, isA<String>());
      expect(userProvider.userRole, isA<String>());
    });

    test('should have correct getters for profile status', () {
      // These are read-only properties that should exist
      expect(userProvider.profileCreated, isA<bool>());
      expect(userProvider.adresseCreated, isA<bool>());
      expect(userProvider.documentCreated, isA<bool>());
      expect(userProvider.gasCylindersCreated, isA<bool>());
      expect(userProvider.phoneCreated, isA<bool>());
      expect(userProvider.emailCreated, isA<bool>());
    });

    test('should validate business logic constants', () {
      // Validar constantes del negocio
      expect(userProvider.isAuthenticated, isFalse);
      expect(userProvider.profileCreated, isFalse);

      // Validar que los getters existen y funcionan
      expect(userProvider.userName, equals(''));
      expect(userProvider.userEmail, equals(''));
      expect(userProvider.userPhotoUrl, equals(''));
      expect(userProvider.userId, equals(0));
      expect(userProvider.userGoogleId, equals(''));
      expect(userProvider.userRole, equals(''));
    });
  });
}
