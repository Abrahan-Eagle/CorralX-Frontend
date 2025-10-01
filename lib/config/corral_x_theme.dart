import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño moderno para CorralX basado en Material Design 3
/// Aplicando tendencias de diseño 2025: colores vibrantes, tipografías expresivas,
/// neumorfismo sutil, glassmorphism y modo oscuro optimizado
class CorralXTheme {
  // Colores ganaderos inspirados en la naturaleza y la agricultura
  static const Color primarySeed =
      Color(0xFF386A20); // Verde principal ganadero
  static const Color secondarySeed = Color(0xFF55624C); // Verde secundario
  static const Color accentSeed = Color(0xFFB7F399); // Verde claro para acentos

  // Paleta de colores ganadera profesional
  static const Color primaryGreen = Color(0xFF386A20); // Verde principal
  static const Color primaryContainer =
      Color(0xFFB7F399); // Verde claro contenedor
  static const Color onPrimaryContainer =
      Color(0xFF082100); // Verde oscuro sobre contenedor
  static const Color secondaryGreen = Color(0xFF55624C); // Verde secundario
  static const Color secondaryContainer =
      Color(0xFFD9E7CA); // Verde claro secundario
  static const Color successGreen = Color(0xFF00A651); // Verde éxito
  static const Color warningOrange = Color(0xFFFF6F00); // Naranja advertencia
  static const Color neutralGray = Color(0xFF74796D); // Gris neutral
  static const Color darkGray = Color(0xFF43483E); // Gris oscuro
  static const Color lightGray = Color(0xFFE0E4D7); // Gris claro

  /// Tema claro moderno con Material Design 3
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      primary: const Color(0xFF386A20),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFFB7F399),
      onPrimaryContainer: const Color(0xFF082100),
      secondary: const Color(0xFF55624C),
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFFD9E7CA),
      onSecondaryContainer: const Color(0xFF131F0D),
      error: const Color(0xFFBA1A1A),
      onError: const Color(0xFFFFFFFF),
      background: const Color(0xFFFCFDF7),
      onBackground: const Color(0xFF1A1C18),
      surface: const Color(0xFFFCFDF7),
      onSurface: const Color(0xFF1A1C18),
      surfaceVariant: const Color(0xFFE0E4D7),
      onSurfaceVariant: const Color(0xFF43483E),
      outline: const Color(0xFF74796D),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Tipografía expresiva y moderna
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.25,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Componentes Material 3 personalizados
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 2,
          shadowColor: colorScheme.shadow.withOpacity(0.1),
        ),
      ),

      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 3,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        color: colorScheme.surface,
      ),

      // AppBar moderno
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // Bottom Navigation moderno
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 8,
        shadowColor: colorScheme.shadow.withOpacity(0.15),
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }

  /// Tema oscuro optimizado para 2025
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
      primary: const Color(0xFF9CDA7F),
      onPrimary: const Color(0xFF082100),
      primaryContainer: const Color(0xFF1F3314),
      onPrimaryContainer: const Color(0xFFB7F399),
      secondary: const Color(0xFFBCCAB0),
      onSecondary: const Color(0xFF263420),
      secondaryContainer: const Color(0xFF3A4A2F),
      onSecondaryContainer: const Color(0xFFD9E7CA),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      background: const Color(0xFF1A1C18),
      onBackground: const Color(0xFFE0E4D7),
      surface: const Color(0xFF2B2D28),
      onSurface: const Color(0xFFE0E4D7),
      surfaceVariant: const Color(0xFF43483E),
      onSurfaceVariant: const Color(0xFFC4C8BB),
      outline: const Color(0xFF8E9388),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Tipografía optimizada para modo oscuro
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.25,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Componentes optimizados para modo oscuro
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      ),

      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.3),
        color: colorScheme.surface,
      ),

      // AppBar para modo oscuro
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // Bottom Navigation para modo oscuro
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.4),
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }

  /// Colores sólidos ganaderos (sin degradados)
  static const Color primarySolid =
      Color(0xFF386A20); // Verde principal ganadero
  static const Color secondarySolid = Color(0xFF55624C); // Verde secundario
  static const Color accentSolid = Color(0xFFB7F399); // Verde claro acento
  static const Color successSolid = Color(0xFF00A651); // Verde éxito
  static const Color neutralSolid = Color(0xFF74796D); // Gris neutral

  /// Sombras neumórficas sutiles
  static List<BoxShadow> get neumorphicLight => [
        BoxShadow(
          color: Colors.white.withOpacity(0.7),
          offset: const Offset(-4, -4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get neumorphicDark => [
        BoxShadow(
          color: Colors.white.withOpacity(0.05),
          offset: const Offset(-4, -4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  /// Efectos glassmorphism
  static BoxDecoration get glassmorphismLight => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      );

  static BoxDecoration get glassmorphismDark => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      );
}

/// Extensión para facilitar el acceso al tema
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
