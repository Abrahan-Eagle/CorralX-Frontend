import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'welcome_page.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';
// import 'onboarding_page4.dart';
// import 'onboarding_page5.dart';
// import 'onboarding_page6.dart';
import 'package:provider/provider.dart';
import 'package:zonix/config/user_provider.dart';
import 'onboarding_service.dart';
import 'package:zonix/main.dart';
import '../../shared/widgets/amazon_widgets.dart';

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

  // GlobalKeys para acceder a los métodos de las páginas
  final GlobalKey _page1Key = GlobalKey();
  final GlobalKey _page2Key = GlobalKey();

  late final List<Widget> onboardingPages;

  @override
  void initState() {
    super.initState();

    onboardingPages = [
      const WelcomePage(),
      OnboardingPage1(key: _page1Key),
      OnboardingPage2(key: _page2Key),
      const OnboardingPage3(),
      // OnboardingPage4(),
      // OnboardingPage5(),
      // OnboardingPage6(),
    ];
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    debugPrint("🚀 _completeOnboarding: INICIANDO...");

    // Resetear el estado de carga para permitir la ejecución
    setState(() => _isLoading = false);
    debugPrint("✅ _completeOnboarding: Estado de carga reseteado");

    setState(() => _isLoading = true);
    debugPrint("✅ _completeOnboarding: Estado de carga activado");

    try {
//ojoooooooooooooooooooooo
      // Obtener el userId del UserProvider
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Asegurar que tenemos los detalles más recientes del usuario
      final userDetails = await userProvider.getUserDetails();
      final userId = userDetails['userId'];

      if (userId == null || userId == 0) {
        throw Exception("ID de usuario no encontrado");
      }

      await _onboardingService.completeOnboarding(userId);
      if (!mounted) return;

      // await _onboardingService.completeOnboarding(context);

//ojoooooooooooooooooooooo
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

  Future<void> _handleNext() async {
    debugPrint(
        '🎯 ONBOARDING SCREEN: _handleNext() llamado para página $_currentPage');

    if (_isLoading) {
      debugPrint('⏳ ONBOARDING SCREEN: Ya está cargando, ignorando llamada');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PRIMERO: Guardar datos de la página actual ANTES de navegar
      debugPrint(
          '💾 ONBOARDING SCREEN: Guardando datos de la página $_currentPage...');
      bool saveSuccessful = await _saveCurrentPageData();

      if (!saveSuccessful) {
        debugPrint(
            '❌ ONBOARDING SCREEN: Error al guardar datos, cancelando navegación');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Complete todos los campos correctamente para continuar'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      debugPrint(
          '✅ ONBOARDING SCREEN: Datos guardados exitosamente, procediendo con navegación...');

      // SEGUNDO: Navegar solo si el guardado fue exitoso
      if (_currentPage == onboardingPages.length - 1) {
        debugPrint(
            '🏁 ONBOARDING SCREEN: Última página, completando onboarding...');
        await _completeOnboarding(context);
      } else {
        debugPrint('➡️ ONBOARDING SCREEN: Avanzando a la siguiente página...');
        _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      debugPrint('❌ ONBOARDING SCREEN: Error en _handleNext: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Verificar si el formulario actual es válido
  bool get _isCurrentPageValid {
    switch (_currentPage) {
      case 0: // WelcomePage - siempre válida
        return true;
      case 1: // OnboardingPage1 - verificar formulario
        final page1State = _page1Key.currentState;
        return (page1State as dynamic)?.isFormValid ?? false;
      case 2: // OnboardingPage2 - verificar formulario
        final page2State = _page2Key.currentState;
        return (page2State as dynamic)?.isFormValid ?? false;
      case 3: // OnboardingPage3 - siempre válida
        return true;
      default:
        return true;
    }
  }

  // Método para que las páginas puedan notificar cambios en el formulario
  void notifyFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Verificar si se puede navegar a una página específica
  bool _canNavigateToPage(int targetPage) {
    // NO permitir navegación hacia atrás después de completar formularios
    if (targetPage < _currentPage) {
      // Solo permitir retroceder si no se han completado formularios
      // Si estamos en página 2 o superior, no permitir retroceder
      return _currentPage <= 1;
    }

    // Permitir navegación hacia adelante solo si la página actual es válida
    if (targetPage > _currentPage) {
      return _isCurrentPageValid;
    }

    // Si es la misma página, permitir
    return true;
  }

  Future<bool> _saveCurrentPageData() async {
    try {
      debugPrint(
          '🚀 ONBOARDING SCREEN: _saveCurrentPageData() llamado para página $_currentPage');

      switch (_currentPage) {
        case 0: // WelcomePage - no necesita guardado
          debugPrint(
              '✅ ONBOARDING SCREEN: Página 0 (Welcome) - no necesita guardado');
          return true;
        case 1: // OnboardingPage1 - Datos Personales
          debugPrint(
              '📝 ONBOARDING SCREEN: Procesando página 1 (Datos Personales)');
          final page1State = _page1Key.currentState;
          if (page1State == null) {
            debugPrint(
                '❌ ONBOARDING SCREEN: Error: No se pudo acceder al estado de la página 1');
            return false;
          }

          debugPrint('✅ ONBOARDING SCREEN: Estado de página 1 encontrado');

          // Verificar si el formulario es válido
          final isFormValid = (page1State as dynamic).isFormValid;
          debugPrint('🔍 ONBOARDING SCREEN: isFormValid = $isFormValid');

          if (!isFormValid) {
            debugPrint(
                '❌ ONBOARDING SCREEN: Formulario página 1 no válido - campos incompletos');
            return false;
          }

          // Guardar datos reales
          debugPrint(
              '✅ ONBOARDING SCREEN: Formulario válido, llamando saveData()...');
          await (page1State as dynamic).saveData();
          debugPrint(
              '✅ ONBOARDING SCREEN: Datos de la página 1 guardados exitosamente');
          return true;

        case 2: // OnboardingPage2 - Datos de Hacienda
          final page2State = _page2Key.currentState;
          if (page2State == null) {
            debugPrint('Error: No se pudo acceder al estado de la página 2');
            return false;
          }

          // Verificar si el formulario es válido
          if (!(page2State as dynamic).isFormValid) {
            debugPrint('Formulario página 2 no válido - campos incompletos');
            return false;
          }

          // Guardar datos reales
          debugPrint('Guardando datos de la página 2...');
          await (page2State as dynamic).saveData();
          debugPrint('Datos de la página 2 guardados exitosamente');
          return true;

        case 3: // OnboardingPage3 - Página final
          return true;
        default:
          return true;
      }
    } catch (e) {
      debugPrint("Error guardando datos de página $_currentPage: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                debugPrint(
                    '🔄 ONBOARDING SCREEN: onPageChanged llamado - de $_currentPage a $index');

                // Solo actualizar la página actual
                // El guardado se maneja en _handleNext()
                if (_canNavigateToPage(index)) {
                  setState(() => _currentPage = index);
                  HapticFeedback.lightImpact();
                  debugPrint(
                      '✅ ONBOARDING SCREEN: Navegación permitida a página $index');
                } else {
                  debugPrint(
                      '❌ ONBOARDING SCREEN: Navegación rechazada a página $index');
                  // Rechazar el cambio - volver a la página actual
                  Future.microtask(() {
                    _controller.animateToPage(
                      _currentPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                  HapticFeedback.heavyImpact();
                }
              },
              children: onboardingPages,
            ),

            // Barra de navegación inferior simple
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
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

                      // Botón de navegación unidireccional
                      Center(
                        child: AmazonButton(
                          text: _currentPage == onboardingPages.length - 1
                              ? 'Comenzar'
                              : 'Siguiente',
                          onPressed: _isLoading ? null : _handleNext,
                          isLoading: _isLoading,
                          width: 200,
                          icon: _currentPage == onboardingPages.length - 1
                              ? Icons.play_arrow
                              : Icons.arrow_forward,
                        ),
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
