import 'dart:io';

/// Utilidades para detectar si la app se está ejecutando en entorno de tests.
class TestEnvironment {
  TestEnvironment._();

  /// Retorna true cuando los tests de Flutter/Dart están en ejecución.
  static bool get isRunningTests {
    // `bool.fromEnvironment` permite detectar cuando se define en compile-time.
    const bool fromEnv =
        bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
    if (fromEnv) {
      return true;
    }

    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }
}

