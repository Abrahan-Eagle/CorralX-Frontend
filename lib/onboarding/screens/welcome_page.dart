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
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.background, // Usar color del tema
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
                  // SVG exacto del HTML V2
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _DocumentIconPainter(
                      color: CorralXTheme.primarySolid,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    '¡Bienvenido a Corral X!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface, // Color del tema
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    'Antes de empezar, necesitamos algunos datos para configurar tu perfil. Es un proceso rápido que nos ayudará a personalizar tu experiencia.',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant, // Color del tema
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

/// CustomPainter para dibujar el SVG exacto del HTML V2
/// Path: "M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z"
class _DocumentIconPainter extends CustomPainter {
  final Color color;

  _DocumentIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 // Aumentado de 1.5 a 2.5 para líneas más gruesas
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    final path = Path();

    // Rectángulo superior redondeado (header del documento)
    // M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z
    path.moveTo(5.625 * scaleX, 4.5 * scaleY);
    path.lineTo(18.375 * scaleX, 4.5 * scaleY);
    path.arcToPoint(
      Offset(18.375 * scaleX, 8.25 * scaleY),
      radius: Radius.circular(1.875 * scaleX),
    );
    path.lineTo(5.625 * scaleX, 8.25 * scaleY);
    path.arcToPoint(
      Offset(5.625 * scaleX, 4.5 * scaleY),
      radius: Radius.circular(1.875 * scaleX),
    );

    // Línea 1: M3.75 12h16.5
    path.moveTo(3.75 * scaleX, 12 * scaleY);
    path.lineTo(20.25 * scaleX, 12 * scaleY);

    // Línea 2: m-16.5 3.75h16.5 (relativo)
    path.moveTo(3.75 * scaleX, 15.75 * scaleY);
    path.lineTo(20.25 * scaleX, 15.75 * scaleY);

    // Línea 3: M3.75 19.5h16.5
    path.moveTo(3.75 * scaleX, 19.5 * scaleY);
    path.lineTo(20.25 * scaleX, 19.5 * scaleY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
