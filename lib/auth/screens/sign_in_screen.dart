import 'package:flutter/material.dart';
import 'package:zonix/auth/services/api_service.dart';
import 'package:zonix/main.dart';
import 'package:zonix/auth/services/google_sign_in_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix/config/auth_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zonix/onboarding/screens/onboarding_screen.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();
final ApiService apiService = ApiService();

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final GoogleSignInService googleSignInService = GoogleSignInService();
  bool isAuthenticated = false;
  GoogleSignInAccount? _currentUser;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _loginError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthentication();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Iniciar animaciones
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    isAuthenticated = await AuthUtils.isAuthenticated();
    if (isAuthenticated) {
      _currentUser = await GoogleSignInService.getCurrentUser();
      if (_currentUser != null) {
        debugPrint('Foto de usuario: ${_currentUser!.photoUrl}');
        await _storage.write(
            key: 'userPhotoUrl', value: _currentUser!.photoUrl);
        debugPrint('Nombre de usuario: ${_currentUser!.displayName}');
        await _storage.write(
            key: 'displayName', value: _currentUser!.displayName);
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _loginError = null;
      _isLoading = true;
    });

    try {
      await GoogleSignInService.signInWithGoogle();
      _currentUser = await GoogleSignInService.getCurrentUser();
      setState(() {
        _loginError = null;
      });

      if (_currentUser != null) {
        await AuthUtils.saveUserName(
            _currentUser!.displayName ?? 'Nombre no disponible');
        await AuthUtils.saveUserEmail(_currentUser!.email);
        await AuthUtils.saveUserPhotoUrl(
            _currentUser!.photoUrl ?? 'URL de foto no disponible');

        String? savedName = await _storage.read(key: 'userName');
        String? savedEmail = await _storage.read(key: 'userEmail');
        String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
        String? savedOnboardingString =
            await _storage.read(key: 'userCompletedOnboarding');

        debugPrint('Nombre guardado: $savedName');
        debugPrint('Correo guardado: $savedEmail');
        debugPrint('Foto guardada: $savedPhotoUrl');
        debugPrint('Onboarding guardada: $savedOnboardingString');

        bool onboardingCompleted = savedOnboardingString == '1';
        debugPrint('Conversión de completedOnboarding: $onboardingCompleted');

        if (!mounted) return;

        if (!onboardingCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainRouter()),
          );
        }
      } else {
        debugPrint('Inicio de sesión cancelado o fallido');
        if (!mounted) return;
        setState(() {
          _loginError = 'Inicio de sesión cancelado o fallido';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error durante el manejo del inicio de sesión: $e');
      if (!mounted) return;
      setState(() {
        _loginError = 'Error durante el inicio de sesión';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 48 : 24,
            vertical: isTablet ? 32 : 24,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo en la parte superior
                Column(
                  children: [
                    SizedBox(height: isTablet ? 40 : 30),
                    // Logo principal
                    SizedBox(
                      width: isTablet ? 300 : 200,
                      height: isTablet ? 300 : 200,
                      child: Image.asset(
                        'assets/splash/image_light_1024.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),

                // Contenido en la parte inferior
                Column(
                  children: [
                    SizedBox(height: isTablet ? 32 : 24),

                    // Título
                    Text(
                      'Bienvenido a CorralX',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 28 : 24,
                        color: colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isTablet ? 12 : 8),

                    // Subtítulo
                    Text(
                      'Marketplace Ganadero Profesional',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: isTablet ? 16 : 14,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isTablet ? 40 : 32),

                    // Mensaje de error
                    if (_loginError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: isTablet ? 32 : 24),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.error),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: colorScheme.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _loginError!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Botón de login
                    SizedBox(
                      width: double.infinity,
                      height: isTablet ? 64 : 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary),
                                ),
                              )
                            : Icon(
                                Icons.login,
                                size: isTablet ? 28 : 24,
                                color: colorScheme.onPrimary,
                              ),
                        label: _isLoading
                            ? const Text('Cargando...')
                            : Text(
                                'Continuar con Google',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet ? 20 : 16,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: isTablet ? 24 : 20),

                    // Términos y condiciones
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: isTablet ? 14 : 12,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Al continuar, aceptas nuestros ',
                            ),
                            TextSpan(
                              text: 'Términos de Servicio',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(
                              text: ' y ',
                            ),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
