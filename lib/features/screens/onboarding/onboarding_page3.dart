import 'package:flutter/material.dart';

/// Paletas de color mínimas para esta vista (modo dark)
class CorralXColors {
  static const Color darkBackground = Color(0xFF121212);
}

class OnboardingPage3 extends StatefulWidget {
  const OnboardingPage3({super.key});

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: CorralXColors.darkBackground),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen hero del vaquero con lazo a pantalla completa
          Image.asset(
            'assets/onboarding/cowboy_hero3.png',
            fit: BoxFit.cover,
          ),

          // Overlay cálido para legibilidad
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  const Color(0xFF8B5E3C).withOpacity(0.25),
                  Colors.black.withOpacity(0.6),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),

                          // Título
                          Text(
                            'Publica tu Ganado',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 36,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 8),

                          // Descripción
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.15)),
                            ),
                            child: Text(
                              'Cuando quieras vender, le das a este botón. Montar un anuncio es facilito y rápido.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.92),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Pasos para publicar
                          _buildPublishSteps(),

                          const Spacer(flex: 2),

                          // Indicador de gesto
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swipe_right_alt,
                                  color: Colors.white.withOpacity(0.8)),
                              const SizedBox(width: 8),
                              Text(
                                'Lista tu anuncio en minutos',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishSteps() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStep('📸', 'Fotos\nclaras'),
          _buildStep('🏷️', 'Precio\njusto'),
          _buildStep('📍', 'Ubicación\nprecisa'),
        ],
      ),
    );
  }

  Widget _buildStep(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
