import 'package:flutter/material.dart';
import '../../config/corral_x_theme.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _mainController.forward();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF8F9FA), // Backgrounds del HTML
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono grande (igual al HTML: documento/lista de 3 barras horizontales)
                  Icon(
                    Icons
                        .view_headline, // 3 líneas horizontales como en el HTML
                    size: 80,
                    color: CorralXTheme.primarySolid,
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    '¡Bienvenido a Corral X!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[200] : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    'Antes de empezar, necesitamos algunos datos para configurar tu perfil. Es un proceso rápido que nos ayudará a personalizar tu experiencia.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
