import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para manejar el estado del tema (claro/oscuro)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        // En modo sistema, no podemos determinar el estado actual sin BuildContext
        // Por defecto retornamos false, pero esto se manejará en la UI
        return false;
    }
  }

  /// Cambiar al tema claro
  void setLightMode() {
    _themeMode = ThemeMode.light;
    _saveThemePreference();
    notifyListeners();
  }

  /// Cambiar al tema oscuro
  void setDarkMode() {
    _themeMode = ThemeMode.dark;
    _saveThemePreference();
    notifyListeners();
  }

  /// Cambiar al modo del sistema
  void setSystemMode() {
    _themeMode = ThemeMode.system;
    _saveThemePreference();
    notifyListeners();
  }

  /// Alternar entre claro y oscuro
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setDarkMode();
    } else if (_themeMode == ThemeMode.dark) {
      setLightMode();
    } else {
      // Si está en modo sistema, cambiar a oscuro
      setDarkMode();
    }
  }

  /// Cargar preferencia de tema guardada
  Future<void> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Si no hay preferencia guardada, forzar modo sistema
      if (!prefs.containsKey(_themeKey)) {
        _themeMode = ThemeMode.system;
        await prefs.setString(_themeKey, 'system');
        notifyListeners();
        debugPrint('🎨 ThemeProvider: Modo sistema establecido por defecto');
        return;
      }

      final savedTheme = prefs.getString(_themeKey);
      debugPrint('🎨 ThemeProvider: Tema guardado encontrado: $savedTheme');

      switch (savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }
      debugPrint('🎨 ThemeProvider: ThemeMode aplicado: $_themeMode');
      notifyListeners();
    } catch (e) {
      debugPrint(
          '⚠️ ThemeProvider: Error al cargar tema, usando modo sistema: $e');
      // En caso de error, usar modo sistema por defecto
      _themeMode = ThemeMode.system;
    }
  }

  /// Guardar preferencia de tema
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeValue;

      switch (_themeMode) {
        case ThemeMode.light:
          themeValue = 'light';
          break;
        case ThemeMode.dark:
          themeValue = 'dark';
          break;
        case ThemeMode.system:
          themeValue = 'system';
          break;
      }

      await prefs.setString(_themeKey, themeValue);
    } catch (e) {
      // Error al guardar, pero no es crítico
      debugPrint('Error al guardar preferencia de tema: $e');
    }
  }

  /// Obtener el tema actual basado en el contexto
  bool isDarkModeInContext(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
}
