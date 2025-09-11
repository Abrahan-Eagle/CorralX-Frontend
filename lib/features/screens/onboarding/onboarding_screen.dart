import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';
import 'onboarding_page4.dart';
import 'onboarding_page5.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:provider/provider.dart';
import 'onboarding_service.dart';
import 'package:zonix/main.dart';

final OnboardingService _onboardingService = OnboardingService();

/// Paletas de color oficiales de Corral X para Light/Dark
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  List<Widget> get onboardingPages {
    return const [
      WelcomePage(),
      OnboardingPage1(),
      OnboardingPage2(),
      OnboardingPage3(),
      OnboardingPage4(),
      OnboardingPage5(),
    ];
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _onboardingService.completeOnboarding(context);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainRouter()),
      );
    } catch (e) {
      debugPrint("Error al completar el onboarding: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al completar el onboarding'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleNext() {
    if (_isLoading) return;

    if (_currentPage == onboardingPages.length - 1) {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId != null) {
        _completeOnboarding();
      }
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _handleBack() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          children: [
            // Contenido principal
            PageView(
              controller: _controller,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: onboardingPages,
            ),

            // Barra de navegación inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      // Indicador de progreso
                      SmoothPageIndicator(
                        controller: _controller,
                        count: onboardingPages.length,
                        effect: ExpandingDotsEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          activeDotColor: Colors.white,
                          dotColor: Colors.white.withOpacity(0.45),
                          spacing: 8,
                          expansionFactor: 3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botones de navegación
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botón Atrás/Saltar
                          if (_currentPage > 0)
                            TextButton(
                              onPressed: _handleBack,
                              child: const Text('Atrás'),
                            )
                          else
                            TextButton(
                              onPressed: () async {
                                final userId = userProvider.userId;
                                if (userId != null) {
                                  await _completeOnboarding();
                                }
                              },
                              child: const Text('Saltar'),
                            ),

                          // Botón Siguiente/Finalizar
                          FloatingActionButton(
                            onPressed: _handleNext,
                            backgroundColor: theme.brightness == Brightness.dark
                                ? CorralXColors.darkPrimary
                                : CorralXColors.lightPrimary,
                            elevation: 2,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : Icon(
                                    _currentPage == onboardingPages.length - 1
                                        ? Icons.check
                                        : Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: CorralXColors.darkBackground),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen hero a pantalla completa
          Image.asset(
            'assets/onboarding/cowboy_hero.png',
            fit: BoxFit.cover,
          ),

          // Overlay de gradientes cálidos para legibilidad y branding
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  const Color(0xFF8B5E3C).withOpacity(0.30), // Marrón cálido
                  Colors.black.withOpacity(0.55),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),

                  // Logotipo / Nombre
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Corral ',
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
                        TextSpan(
                          text: 'X',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 40,
                                color: CorralXColors.darkWarning,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Compra y venta de ganado con confianza',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.92),
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: 18),

                  // Chips de confianza
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTrustElement('✅', 'Vendedores\nverificados'),
                        _buildTrustElement('🛡️', 'Pagos\nseguros'),
                        _buildTrustElement('🤝', 'Trato\ndirecto'),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Mensaje de gesto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe_right_alt,
                          color: Colors.white.withOpacity(0.9)),
                      const SizedBox(width: 8),
                      Text(
                        'Desliza para continuar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustElement(String emoji, String text) {
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
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
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
