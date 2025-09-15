import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'welcome_page.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';
import 'onboarding_page4.dart';
import 'onboarding_page5.dart';
import 'onboarding_page6.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:provider/provider.dart';
import 'onboarding_service.dart';
import 'package:zonix/main.dart';
import '../../../core/theme/corral_x_theme.dart';
import '../../../core/widgets/amazon_widgets.dart';

final OnboardingService _onboardingService = OnboardingService();

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
      OnboardingPage6(),
    ];
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _onboardingService.completeOnboarding(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainRouter()),
      );
    } catch (e) {
      debugPrint("Error al completar el onboarding: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al completar el onboarding'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleNext() {
    if (_isLoading) return;

    if (_currentPage == onboardingPages.length - 1) {
      _completeOnboarding();
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
    final colorScheme = theme.colorScheme;

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
                HapticFeedback.lightImpact();
              },
              children: onboardingPages,
            ),

            // Barra de navegación inferior simple
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicador de progreso Amazon
                        AmazonProgressIndicator(
                          currentPage: _currentPage,
                          totalPages: onboardingPages.length,
                        ),

                        const SizedBox(height: 24),

                        // Botones de navegación simples
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Botón Atrás/Saltar
                            if (_currentPage > 0)
                              AmazonButton(
                                text: 'Atrás',
                                onPressed: _handleBack,
                                isSecondary: true,
                                width: 80,
                                icon: Icons.arrow_back,
                              )
                            else
                              AmazonButton(
                                text: 'Saltar',
                                onPressed: () async {
                                  await _completeOnboarding();
                                },
                                isSecondary: true,
                                width: 80,
                                icon: Icons.skip_next,
                              ),

                            // Botón Siguiente/Finalizar
                            AmazonButton(
                              text: _currentPage == onboardingPages.length - 1
                                  ? 'Comenzar'
                                  : 'Siguiente',
                              onPressed: _handleNext,
                              isLoading: _isLoading,
                              width: 120,
                              icon: _currentPage == onboardingPages.length - 1
                                  ? Icons.play_arrow
                                  : Icons.arrow_forward,
                            ),
                          ],
                        ),
                      ],
                    ),
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
