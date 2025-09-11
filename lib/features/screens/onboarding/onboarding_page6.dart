import 'package:flutter/material.dart';

class CorralXColors {
  // White mode
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1F2937); // Gray 800
  static const Color lightTextSecondary = Color(0xFF4B5563); // Gray 600
  static const Color lightPrimary = Color(0xFF3B7A57); // Verde campo
  static const Color lightSecondary = Color(0xFF8B5E3C); // Marrón tierra
  static const Color lightSuccess = Color(0xFF4CAF50);
  static const Color lightWarning = Color(0xFFFBBF24);

  // Dark mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkPrimary = Color(0xFF4CAF50); // Verde vivo
  static const Color darkSecondary = Color(0xFFA47148); // Marrón cálido
  static const Color darkSuccess = Color(0xFF6EE7B7);
  static const Color darkWarning = Color(0xFFEAB308);
}

class OnboardingPage6 extends StatefulWidget {
  const OnboardingPage6({super.key});

  @override
  State<OnboardingPage6> createState() => _OnboardingPage6State();
}

class _OnboardingPage6State extends State<OnboardingPage6>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

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
          Image.asset(
            'assets/onboarding/cowboy_hero6.png',
            fit: BoxFit.cover,
          ),
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
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _slideAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          Text(
                            'Tu Perfil',
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
                              'Aquí manejas tu información, ves tus publicaciones y te aseguras de que todo esté al día. ¡Listo el pollo!',
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
                          _buildProfileFeatures(),
                          const Spacer(flex: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swipe_right_alt,
                                  color: Colors.white.withOpacity(0.8)),
                              const SizedBox(width: 8),
                              Text(
                                'Gestiona tu cuenta',
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

  Widget _buildProfileFeatures() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildProfileFeature('👤', 'Información\npersonal'),
          _buildProfileFeature('📝', 'Mis\npublicaciones'),
          _buildProfileFeature('⚙️', 'Ajustes\nde cuenta'),
        ],
      ),
    );
  }

  Widget _buildProfileFeature(String emoji, String text) {
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
