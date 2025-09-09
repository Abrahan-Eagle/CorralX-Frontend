// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:logger/logger.dart';
// import 'package:zonix/features/services/auth/api_service.dart';
// import 'package:zonix/main.dart';
// import 'package:zonix/features/services/auth/google_sign_in_service.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:zonix/features/utils/auth_utils.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';

// const FlutterSecureStorage _storage = FlutterSecureStorage();
// final ApiService apiService = ApiService();
// final logger = Logger();

// class SignInScreen extends StatefulWidget {
//   const SignInScreen({super.key});

//   @override
//   SignInScreenState createState() => SignInScreenState();
// }

// class SignInScreenState extends State<SignInScreen>
//     with TickerProviderStateMixin {
//   final GoogleSignInService googleSignInService = GoogleSignInService();
//   bool isAuthenticated = false;
//   GoogleSignInAccount? _currentUser;
//   late AnimationController _pulseController;
//   late AnimationController _rotateController;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _rotateAnimation;
//   String? _loginError;

//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//     _checkAuthentication();
//   }

//   void _setupAnimations() {
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);

//     _rotateController = AnimationController(
//       duration: const Duration(seconds: 20),
//       vsync: this,
//     )..repeat();

//     _pulseAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));

//     _rotateAnimation = Tween<double>(
//       begin: 0,
//       end: 1,
//     ).animate(_rotateController);
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _rotateController.dispose();
//     super.dispose();
//   }

//   Future<void> _checkAuthentication() async {
//     isAuthenticated = await AuthUtils.isAuthenticated();
//     if (isAuthenticated) {
//       _currentUser = await GoogleSignInService.getCurrentUser();
//       if (_currentUser != null) {
//         logger.i('Foto de usuario: ${_currentUser!.photoUrl}');
//         await _storage.write(
//             key: 'userPhotoUrl', value: _currentUser!.photoUrl);
//         logger.i('Nombre de usuario: ${_currentUser!.displayName}');
//         await _storage.write(
//             key: 'displayName', value: _currentUser!.displayName);
//       }
//     }
//     if (!mounted) return;
//     setState(() {});
//   }

//   Future<void> _handleSignIn() async {
//     try {
//       await GoogleSignInService.signInWithGoogle();
//       _currentUser = await GoogleSignInService.getCurrentUser();
//       setState(() {
//         _loginError = null;
//       });

//       if (_currentUser != null) {
//         await AuthUtils.saveUserName(
//             _currentUser!.displayName ?? 'Nombre no disponible');
//         await AuthUtils.saveUserEmail(
//             _currentUser!.email ?? 'Email no disponible');
//         await AuthUtils.saveUserPhotoUrl(
//             _currentUser!.photoUrl ?? 'URL de foto no disponible');

//         String? savedName = await _storage.read(key: 'userName');
//         String? savedEmail = await _storage.read(key: 'userEmail');
//         String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
//         String? savedOnboardingString =
//             await _storage.read(key: 'userCompletedOnboarding');

//         logger.i('Nombre guardado: $savedName');
//         logger.i('Correo guardado: $savedEmail');
//         logger.i('Foto guardada: $savedPhotoUrl');
//         logger.i('Onboarding guardada: $savedOnboardingString');

//         bool onboardingCompleted = savedOnboardingString == '1';
//         logger.i('Conversión de completedOnboarding: $onboardingCompleted');

//         if (!mounted) return;

//         if (!onboardingCompleted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const OnboardingScreen()),
//           );
//         } else {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const MainRouter()),
//           );
//         }
//       } else {
//         logger.i('Inicio de sesión cancelado o fallido');
//         if (!mounted) return;
//         setState(() {
//           _loginError = 'Inicio de sesión cancelado o fallido';
//         });
//       }
//     } catch (e) {
//       logger.e('Error durante el manejo del inicio de sesión: $e');
//       if (!mounted) return;
//       setState(() {
//         _loginError = 'Error durante el inicio de sesión';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;
//     final isLargeScreen = screenWidth > 600;
//     final isVerySmallScreen = screenHeight < 600;

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Fondo con patrón geométrico
//           _buildGeometricBackground(),

//           // Contenido principal con SingleChildScrollView para evitar overflow
//           SafeArea(
//             child: SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(
//                   minHeight: MediaQuery.of(context).size.height -
//                       MediaQuery.of(context).padding.top -
//                       MediaQuery.of(context).padding.bottom,
//                 ),
//                 child: IntrinsicHeight(
//                   child: Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: isSmallScreen ? 16 : 24,
//                       vertical: isVerySmallScreen ? 8 : 16,
//                     ),
//                     child: Column(
//                       children: [
//                         // Header minimalista
//                         _buildMinimalHeader(isSmallScreen),

//                         if (_loginError != null) ...[
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(
//                               _loginError!,
//                               style: const TextStyle(
//                                   color: Colors.red,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         ],

//                         // Contenido central con Expanded
//                         Expanded(
//                           child: Column(
//                             children: [
//                               // Círculo central
//                               Expanded(
//                                 flex: 3,
//                                 child: _buildCentralCircle(
//                                     screenWidth,
//                                     isSmallScreen,
//                                     isLargeScreen,
//                                     isVerySmallScreen),
//                               ),

//                               // Contenido inferior
//                               Expanded(
//                                 flex: 2,
//                                 child: _buildBottomContent(
//                                     screenWidth,
//                                     isSmallScreen,
//                                     isLargeScreen,
//                                     isVerySmallScreen),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGeometricBackground() {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Color(0xFF1A1A2E),
//       ),
//       child: Stack(
//         children: [
//           // Círculos decorativos animados
//           Positioned(
//             top: -50,
//             right: -50,
//             child: RotationTransition(
//               turns: _rotateAnimation,
//               child: Container(
//                 width: 200,
//                 height: 200,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFFFF6B35).withOpacity(0.1),
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: -100,
//             left: -100,
//             child: RotationTransition(
//               turns: _rotateAnimation,
//               child: Container(
//                 width: 300,
//                 height: 300,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFFFFC93C).withOpacity(0.08),
//                 ),
//               ),
//             ),
//           ),
//           // Patrón de puntos
//           ...List.generate(20, (index) {
//             return Positioned(
//               top: ((index * 50.0) % 800).roundToDouble(),
//               left: ((index * 80.0) % 400).roundToDouble(),
//               child: Container(
//                 width: 4,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white.withOpacity(0.1),
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildMinimalHeader(bool isSmallScreen) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Transform.translate(
//           offset: const Offset(0, -25), // Ajusta este valor
//           child: Text(
//             TimeOfDay.now().format(context),
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: isSmallScreen ? 14 : 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//         Transform.translate(
//           offset: const Offset(0, -25),
//           child: Image.asset(
//             'assets/images/splash_logo.png',
//             width: isSmallScreen ? 90 : 90,
//             height: isSmallScreen ? 90 : 90,
//             fit: BoxFit.contain,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCentralCircle(double screenWidth, bool isSmallScreen,
//       bool isLargeScreen, bool isVerySmallScreen) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Círculo principal animado

//           ScaleTransition(
//             scale: _pulseAnimation,
//             child: Container(
//               width: isSmallScreen
//                   ? screenWidth * (isVerySmallScreen ? 0.5 : 0.6)
//                   : isLargeScreen
//                       ? screenWidth * 0.3
//                       : screenWidth * 0.5,
//               height: isSmallScreen
//                   ? screenWidth * (isVerySmallScreen ? 0.5 : 0.6)
//                   : isLargeScreen
//                       ? screenWidth * 0.3
//                       : screenWidth * 0.5,
//               // decoration: BoxDecoration(
//               //   shape: BoxShape.circle,
//               //   color: const Color(0xFFFF6B35),
//               //   boxShadow: [
//               //     BoxShadow(
//               //       color: const Color(0xFFFF6B35).withOpacity(0.4),
//               //       blurRadius: 40,
//               //       spreadRadius: 10,
//               //     ),
//               //   ],
//               // ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Logo principal (ajustado para evitar overflow)
//                   Flexible(
//                     child: Image.asset(
//                       'assets/images/splash_logo.png',
//                       width: isSmallScreen ? 400 : 500,
//                       height: isSmallScreen ? 146 : 183,
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           SizedBox(height: isVerySmallScreen ? 8 : 16),

//           // Texto de bienvenida
//           Text(
//             'Tu hambre, nuestra misión',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: isSmallScreen ? 14 : 18,
//               fontWeight: FontWeight.w300,
//               letterSpacing: 1,
//             ),
//           ),

//           SizedBox(height: isVerySmallScreen ? 4 : 6),

//           Container(
//             padding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12 : 16,
//                 vertical: isSmallScreen ? 4 : 6),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFC93C).withOpacity(0.2),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: Text(
//               '🍕 🍔 🍟 🌮 🍗 🍜',
//               style: TextStyle(fontSize: isSmallScreen ? 14 : 18),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomContent(double screenWidth, bool isSmallScreen,
//       bool isLargeScreen, bool isVerySmallScreen) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         // Mensaje motivacional
//         Text(
//           'Miles de restaurantes te esperan',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             color: Colors.white70,
//             fontSize: isSmallScreen ? 12 : 14,
//             fontWeight: FontWeight.w400,
//             height: 1.4,
//           ),
//         ),

//         SizedBox(height: isVerySmallScreen ? 8 : 16),

//         // Botón de Google con diseño futurista
//         Container(
//           width: isLargeScreen ? screenWidth * 0.6 : double.infinity,
//           height: isSmallScreen ? 52 : 60,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(30),
//             border: Border.all(
//               color: const Color(0xFFFFC93C),
//               width: 2,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFFFFC93C).withOpacity(0.3),
//                 blurRadius: 20,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: _handleSignIn,
//               borderRadius: BorderRadius.circular(30),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(28),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF8F9FA),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Image.asset(
//                         'assets/images/google_logo.png',
//                         height: isSmallScreen ? 24 : 28,
//                         width: isSmallScreen ? 24 : 28,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Icon(
//                             Icons.login,
//                             size: isSmallScreen ? 24 : 28,
//                             color: const Color(0xFF4285F4),
//                           );
//                         },
//                       ),
//                     ),
//                     SizedBox(width: isSmallScreen ? 10 : 12),
//                     Text(
//                       'EMPEZAR CON GOOGLE',
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 11 : 13,
//                         fontWeight: FontWeight.w800,
//                         color: const Color(0xFF1A1A2E),
//                         letterSpacing: 1,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),

//         SizedBox(height: isVerySmallScreen ? 8 : 12),

//         // Indicadores de tiempo
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _buildTimeIndicator('⚡', '5 min', 'Registro', isSmallScreen),
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10),
//               width: isSmallScreen ? 15 : 25,
//               height: 1,
//               color: Colors.white30,
//             ),
//             _buildTimeIndicator('🍕', '30 min', 'Tu comida', isSmallScreen),
//           ],
//         ),

//         SizedBox(height: isVerySmallScreen ? 6 : 10),

//         // Términos minimalistas
//         Text(
//           'Al continuar aceptas términos y condiciones',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.6),
//             fontSize: isSmallScreen ? 9 : 10,
//             height: 1.4,
//           ),
//         ),

//         // Pequeño padding inferior para evitar que se pegue al borde
//         SizedBox(height: isVerySmallScreen ? 4 : 8),
//       ],
//     );
//   }

//   Widget _buildTimeIndicator(
//       String emoji, String time, String label, bool isSmallScreen) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           emoji,
//           style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           time,
//           style: TextStyle(
//             color: const Color(0xFFFFC93C),
//             fontSize: isSmallScreen ? 10 : 12,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.7),
//             fontSize: isSmallScreen ? 8 : 9,
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'package:zonix/main.dart';
import 'package:zonix/features/services/auth/google_sign_in_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix/features/utils/auth_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';

// 🎨 PALETA CORRAL X - MODO CLARO
class CorralXColors {
  // Base clara
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF4B5563);

  // Colores agropecuarios principales
  static const Color primaryGreen =
      Color(0xFF3B7A57); // Verde campo - confianza
  static const Color secondaryBrown =
      Color(0xFF8B5E3C); // Marrón tierra - solidez
  static const Color accentGold = Color(0xFFFBBF24); // Dorado - premium
  static const Color successGreen = Color(0xFF4CAF50);

  // Base oscura (para modo dark futuro)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
}

const FlutterSecureStorage _storage = FlutterSecureStorage();
final ApiService apiService = ApiService();
final logger = Logger();

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
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController
      _floatController; // Nueva animación para elementos flotantes
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _floatAnimation;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeDateFormatting();
    _checkAuthentication();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('es_ES', null);
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3), // Más lento y elegante
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 30), // Rotación más suave
      vsync: this,
    )..repeat();

    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotateController);

    _floatAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    isAuthenticated = await AuthUtils.isAuthenticated();
    if (isAuthenticated) {
      _currentUser = await GoogleSignInService.getCurrentUser();
      if (_currentUser != null) {
        logger.i('Foto de usuario: ${_currentUser!.photoUrl}');
        await _storage.write(
            key: 'userPhotoUrl', value: _currentUser!.photoUrl);
        logger.i('Nombre de usuario: ${_currentUser!.displayName}');
        await _storage.write(
            key: 'displayName', value: _currentUser!.displayName);
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleSignIn() async {
    try {
      await GoogleSignInService.signInWithGoogle();
      _currentUser = await GoogleSignInService.getCurrentUser();
      setState(() {
        _loginError = null;
      });

      if (_currentUser != null) {
        await AuthUtils.saveUserName(
            _currentUser!.displayName ?? 'Nombre no disponible');
        await AuthUtils.saveUserEmail(
            _currentUser!.email ?? 'Email no disponible');
        await AuthUtils.saveUserPhotoUrl(
            _currentUser!.photoUrl ?? 'URL de foto no disponible');

        String? savedName = await _storage.read(key: 'userName');
        String? savedEmail = await _storage.read(key: 'userEmail');
        String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
        String? savedOnboardingString =
            await _storage.read(key: 'userCompletedOnboarding');

        logger.i('Nombre guardado: $savedName');
        logger.i('Correo guardado: $savedEmail');
        logger.i('Foto guardada: $savedPhotoUrl');
        logger.i('Onboarding guardada: $savedOnboardingString');

        bool onboardingCompleted = savedOnboardingString == '1';
        logger.i('Conversión de completedOnboarding: $onboardingCompleted');

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
        logger.i('Inicio de sesión cancelado o fallido');
        if (!mounted) return;
        setState(() {
          _loginError = 'Inicio de sesión cancelado o fallido';
        });
      }
    } catch (e) {
      logger.e('Error durante el manejo del inicio de sesión: $e');
      if (!mounted) return;
      setState(() {
        _loginError = 'Error durante el inicio de sesión';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth >= 400 && screenWidth <= 600;
    final isLargeScreen = screenWidth > 600;
    final isVerySmallScreen = screenHeight < 600;
    final isTablet = screenWidth > 800;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo agropecuario con elementos visuales
          _buildAgrarianBackground(),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen
                          ? 16
                          : isMediumScreen
                              ? 24
                              : isTablet
                                  ? 48
                                  : 32,
                      vertical: isVerySmallScreen
                          ? 8
                          : isLandscape
                              ? 16
                              : 24,
                    ),
                    child: Column(
                      children: [
                        // Header con branding ganadero
                        _buildCorralHeader(
                            isSmallScreen, isTablet, isLandscape),

                        if (_loginError != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _loginError!,
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Contenido central
                        Expanded(
                          child: Column(
                            children: [
                              // Logo y marca principal
                              Expanded(
                                flex: isLandscape ? 2 : 3,
                                child: _buildCorralBranding(
                                    screenWidth,
                                    isSmallScreen,
                                    isMediumScreen,
                                    isLargeScreen,
                                    isVerySmallScreen,
                                    isTablet,
                                    isLandscape),
                              ),

                              // CTA y acciones
                              Expanded(
                                flex: isLandscape ? 1 : 2,
                                child: _buildActionSection(
                                    screenWidth,
                                    isSmallScreen,
                                    isMediumScreen,
                                    isLargeScreen,
                                    isVerySmallScreen,
                                    isTablet,
                                    isLandscape),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgrarianBackground() {
    return Container(
      decoration: BoxDecoration(
        // Gradiente que evoca el amanecer en el campo
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CorralXColors.backgroundLight,
            const Color(0xFFF8F9FA), // Gris muy suave
            CorralXColors.backgroundLight,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Elementos decorativos que evocan el campo
          Positioned(
            top: 60,
            right: -30,
            child: RotationTransition(
              turns: _rotateAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CorralXColors.primaryGreen.withOpacity(0.08),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -80,
            left: -60,
            child: RotationTransition(
              turns: _rotateAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CorralXColors.secondaryBrown.withOpacity(0.06),
                ),
              ),
            ),
          ),

          // Patrón sutil que simula hierba o textura del campo
          ...List.generate(15, (index) {
            return Positioned(
              top: ((index * 60.0) % 700).roundToDouble(),
              left: ((index * 90.0) % 350).roundToDouble(),
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CorralXColors.primaryGreen.withOpacity(0.12),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCorralHeader(
      bool isSmallScreen, bool isTablet, bool isLandscape) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hora con estilo más elegante
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              TimeOfDay.now().format(context),
              style: TextStyle(
                color: CorralXColors.textPrimaryLight,
                fontSize: isSmallScreen
                    ? 14
                    : isTablet
                        ? 20
                        : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              DateFormat('dd MMM, yyyy', 'es_ES').format(DateTime.now()),
              style: TextStyle(
                color: CorralXColors.textSecondaryLight,
                fontSize: isSmallScreen
                    ? 10
                    : isTablet
                        ? 14
                        : 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCorralBranding(
      double screenWidth,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen,
      bool isVerySmallScreen,
      bool isTablet,
      bool isLandscape) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo principal animado con identidad ganadera
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: isSmallScreen
                  ? screenWidth * 0.7
                  : isTablet
                      ? screenWidth * 0.3
                      : isLandscape
                          ? screenWidth * 0.25
                          : screenWidth * 0.5,
              height: isSmallScreen
                  ? screenWidth * 0.7
                  : isTablet
                      ? screenWidth * 0.3
                      : isLandscape
                          ? screenWidth * 0.25
                          : screenWidth * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CorralXColors.backgroundLight,
                boxShadow: [
                  BoxShadow(
                    color: CorralXColors.primaryGreen.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 8,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: CorralXColors.secondaryBrown.withOpacity(0.1),
                    blurRadius: 60,
                    spreadRadius: 15,
                  ),
                ],
                border: Border.all(
                  color: CorralXColors.primaryGreen.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre de la marca - más prominente como nombre de la app
                  Text(
                    'CORRAL X',
                    style: TextStyle(
                      color: CorralXColors.primaryGreen,
                      fontSize: isSmallScreen
                          ? 36
                          : isTablet
                              ? 64
                              : isLandscape
                                  ? 52
                                  : 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: isTablet ? 6 : 5,
                    ),
                  ),

                  SizedBox(
                      height: isSmallScreen
                          ? 4
                          : isTablet
                              ? 8
                              : isLandscape
                                  ? 6
                                  : 8),

                  // Subtítulo del logo
                  Text(
                    'GANADERÍA',
                    style: TextStyle(
                      color: CorralXColors.secondaryBrown,
                      fontSize: isSmallScreen
                          ? 12
                          : isTablet
                              ? 20
                              : isLandscape
                                  ? 16
                                  : 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: isTablet ? 2 : 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
              height: isVerySmallScreen
                  ? 12
                  : isLandscape
                      ? 16
                      : 24),

          // Mensaje reconectado con el mercado ganadero
          Text(
            'Tu ganado, nuestra plataforma',
            style: TextStyle(
              color: CorralXColors.textSecondaryLight,
              fontSize: isSmallScreen
                  ? 14
                  : isTablet
                      ? 24
                      : isLandscape
                          ? 18
                          : 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),

          SizedBox(
              height: isVerySmallScreen
                  ? 6
                  : isLandscape
                      ? 8
                      : 12),

          // Iconos ganaderos en lugar de emojis de comida
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen
                    ? 12
                    : isTablet
                        ? 32
                        : 20,
                vertical: isSmallScreen
                    ? 6
                    : isTablet
                        ? 16
                        : 12),
            decoration: BoxDecoration(
              color: CorralXColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: CorralXColors.primaryGreen.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimalIcon('🐄', isSmallScreen, isTablet),
                _buildAnimalIcon('🐖', isSmallScreen, isTablet),
                _buildAnimalIcon('🐑', isSmallScreen, isTablet),
                _buildAnimalIcon('🐔', isSmallScreen, isTablet),
                _buildAnimalIcon('🐐', isSmallScreen, isTablet),
                _buildAnimalIcon('🐴', isSmallScreen, isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalIcon(String emoji, bool isSmallScreen, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen
              ? 2
              : isTablet
                  ? 6
                  : 4),
      child: Text(
        emoji,
        style: TextStyle(
            fontSize: isSmallScreen
                ? 16
                : isTablet
                    ? 32
                    : 24),
      ),
    );
  }

  Widget _buildActionSection(
      double screenWidth,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen,
      bool isVerySmallScreen,
      bool isTablet,
      bool isLandscape) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Propuesta de valor para ganaderos
        Text(
          'Conectamos ganaderos y compradores\nen todo el país',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CorralXColors.textSecondaryLight,
            fontSize: isSmallScreen
                ? 12
                : isTablet
                    ? 20
                    : isLandscape
                        ? 16
                        : 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),

        SizedBox(
            height: isVerySmallScreen
                ? 12
                : isLandscape
                    ? 16
                    : 24),

        // Botón principal con diseño agropecuario premium
        Container(
          width: isTablet
              ? screenWidth * 0.5
              : isLandscape
                  ? screenWidth * 0.4
                  : isLargeScreen
                      ? screenWidth * 0.65
                      : double.infinity,
          height: isSmallScreen
              ? 50
              : isTablet
                  ? 80
                  : isLandscape
                      ? 60
                      : 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            gradient: LinearGradient(
              colors: [
                CorralXColors.primaryGreen,
                CorralXColors.primaryGreen.withBlue(120), // Variación tonal
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: CorralXColors.primaryGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleSignIn,
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen
                        ? 6
                        : isTablet
                            ? 14
                            : 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    ),
                    child: Image.asset(
                      'assets/images/google_logo.png',
                      height: isSmallScreen
                          ? 20
                          : isTablet
                              ? 36
                              : 28,
                      width: isSmallScreen
                          ? 20
                          : isTablet
                              ? 36
                              : 28,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.login,
                          size: isSmallScreen
                              ? 20
                              : isTablet
                                  ? 36
                                  : 28,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                  SizedBox(
                      width: isSmallScreen
                          ? 8
                          : isTablet
                              ? 20
                              : 16),
                  Text(
                    'INGRESAR CON GOOGLE',
                    style: TextStyle(
                      fontSize: isSmallScreen
                          ? 12
                          : isTablet
                              ? 20
                              : isLandscape
                                  ? 16
                                  : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: isTablet ? 1.5 : 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(
            height: isVerySmallScreen
                ? 12
                : isLandscape
                    ? 16
                    : 20),

        // Indicadores de proceso para ganaderos
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProcessStep(
                '📝', '2 min', 'Registro', isSmallScreen, isTablet),
            Container(
              margin: EdgeInsets.symmetric(
                  horizontal: isSmallScreen
                      ? 6
                      : isTablet
                          ? 16
                          : 12),
              width: isSmallScreen
                  ? 16
                  : isTablet
                      ? 40
                      : 30,
              height: 2,
              decoration: BoxDecoration(
                color: CorralXColors.primaryGreen.withOpacity(0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            _buildProcessStep(
                '🤝', '24/7', 'Negocios', isSmallScreen, isTablet),
          ],
        ),

        SizedBox(height: isVerySmallScreen ? 12 : 16),

        // Términos con enfoque profesional
        Text(
          'Al continuar aceptas nuestros términos y condiciones\nTus datos están protegidos',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CorralXColors.textSecondaryLight.withOpacity(0.8),
            fontSize: isSmallScreen
                ? 9
                : isTablet
                    ? 14
                    : 11,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),

        SizedBox(height: isVerySmallScreen ? 8 : 12),
      ],
    );
  }

  Widget _buildProcessStep(String emoji, String time, String label,
      bool isSmallScreen, bool isTablet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen
              ? 6
              : isTablet
                  ? 12
                  : 8),
          decoration: BoxDecoration(
            color: CorralXColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          ),
          child: Text(
            emoji,
            style: TextStyle(
                fontSize: isSmallScreen
                    ? 16
                    : isTablet
                        ? 28
                        : 20),
          ),
        ),
        SizedBox(
            height: isSmallScreen
                ? 2
                : isTablet
                    ? 6
                    : 4),
        Text(
          time,
          style: TextStyle(
            color: CorralXColors.primaryGreen,
            fontSize: isSmallScreen
                ? 10
                : isTablet
                    ? 18
                    : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: CorralXColors.textSecondaryLight,
            fontSize: isSmallScreen
                ? 8
                : isTablet
                    ? 14
                    : 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
