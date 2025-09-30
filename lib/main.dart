// import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:zonix/features/auth/services/api_service.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:provider/provider.dart';
// import 'package:zonix/shared/utils/user_provider.dart';
// import 'package:flutter/services.dart';
// // import 'package:zonix/features/screens/settings/settings_page_2.dart';
// import 'package:zonix/features/auth/screens/sign_in_screen.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
// import 'package:zonix/features/screens/products/products_page.dart';
// import 'package:zonix/features/screens/cart/cart_page.dart';
// import 'package:zonix/features/screens/orders/orders_page.dart';
// import 'package:zonix/features/screens/restaurants/restaurants_page.dart';
// import 'package:zonix/features/services/cart_service.dart';
// import 'package:zonix/features/services/order_service.dart';
// import 'package:zonix/features/screens/orders/commerce_orders_page.dart';

// // final ApiService apiService = ApiService();

// final String baseUrl =
//     const bool.fromEnvironment('dart.vm.product')
//         ? dotenv.env['API_URL_PROD']!
//         : dotenv.env['API_URL_LOCAL']!;

// // Configuración del logger
// final logger = Logger();

// //  class MyHttpOverrides extends HttpOverrides{
// //   @override
// //   HttpClient createHttpClient(SecurityContext? context){
// //     return super.createHttpClient(context)
// //       ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
// //   }
// // }

// // void main() {
// Future<void> main() async {
//   WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
//   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
//   initialization();

//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   await dotenv.load();
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => UserProvider()),
//         ChangeNotifierProvider(create: (_) => CartService()),
//         ChangeNotifierProvider(create: (_) => OrderService()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// void initialization() async {
//   logger.i('Initializing...');
//   await Future.delayed(const Duration(seconds: 3));
//   FlutterNativeSplash.remove();
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Provider.of<UserProvider>(context, listen: false).checkAuthentication();

//     return MaterialApp(
//       title: 'ZONIX',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.light(),
//       darkTheme: ThemeData.dark(),
//       themeMode: ThemeMode.system,
//       home: Consumer<UserProvider>(
//         builder: (context, userProvider, child) {
//           logger.i('isAuthenticated:  [32m [1m [4m [7m${userProvider.isAuthenticated} [0m');
//           if (userProvider.isAuthenticated) {
//             if (userProvider.userRole == 'users') {
//               return const MainRouter();
//             } else if (userProvider.userRole == 'commerce') {
//               return const CommerceOrdersPage();
//             } else {
//               // Rol desconocido, fallback
//               return const MainRouter();
//             }
//           } else {
//             return const SignInScreen();
//           }
//         },
//       ),
//     );
//   }
// }

// class MainRouter extends StatefulWidget {
//   const MainRouter({super.key});

//   @override
//   MainRouterState createState() => MainRouterState();
// }

// class MainRouterState extends State<MainRouter> {
//   int _bottomNavIndex = 0;
//   dynamic _profile;

//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//     _loadLastPosition();
//   }

//   Future<void> _loadProfile() async {
//     try {
//       final userProvider = Provider.of<UserProvider>(context, listen: false);
//       final userDetails = await userProvider.getUserDetails();
//       final id = userDetails['userId'];
//       if (id == null || id is! int) {
//         throw Exception('El ID del usuario es inválido: $id');
//       }
//       _profile = await ProfileService().getProfileById(id);
//       setState(() {});
//     } catch (e) {
//       logger.e('Error obteniendo el ID del usuario: $e');
//     }
//   }

//   Future<void> _loadLastPosition() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _bottomNavIndex = prefs.getInt('bottomNavIndex') ?? 0;
//       logger.i('Loaded last position - bottomNavIndex: $_bottomNavIndex');
//     });
//   }

//   Future<void> _saveLastPosition() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('bottomNavIndex', _bottomNavIndex);
//     logger.i('Saved last position - bottomNavIndex: $_bottomNavIndex');
//   }

//   List<BottomNavigationBarItem> _getBottomNavItems() {
//     return [
//       const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Productos'),
//       const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
//       const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Órdenes'),
//       const BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurantes'),
//       const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
//     ];
//   }

//   void _onBottomNavTapped(int index) {
//     logger.i('Bottom navigation tapped: $index');
//     if (index == 4) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => const SettingsPage2()),
//       );
//     } else {
//       setState(() {
//         _bottomNavIndex = index;
//         _saveLastPosition();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         elevation: 4.0,
//         title: RichText(
//           text: TextSpan(
//             children: [
//               TextSpan(
//                 text: 'ZONI',
//                 style: TextStyle(
//                   fontFamily: 'system-ui',
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//               TextSpan(
//                 text: 'X',
//                 style: TextStyle(
//                   fontFamily: 'system-ui',
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).brightness == Brightness.dark ? Colors.blueAccent[700] : Colors.orange,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         centerTitle: false,
//         actions: [
//           Consumer<UserProvider>(
//             builder: (context, userProvider, child) {
//               return GestureDetector(
//                 onTap: () {
//                   showMenu(
//                     context: context,
//                     position: const RelativeRect.fromLTRB(200, 80, 0, 0),
//                     items: [
//                       PopupMenuItem(
//                         child: const Text('Mi QR'),
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const ProfilePage1(),
//                           ),
//                         ),
//                       ),
//                       PopupMenuItem(
//                         child: const Text('Configuración'),
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const SettingsPage2(),
//                           ),
//                         ),
//                       ),
//                       PopupMenuItem(
//                         child: const Text('Cerrar sesión'),
//                         onTap: () async {
//                           await userProvider.logout();
//                           if (!mounted) return;
//                           Navigator.of(context).pushAndRemoveUntil(
//                             MaterialPageRoute(builder: (context) => const SignInScreen()),
//                             (Route<dynamic> route) => false,
//                           );
//                         },
//                       ),
//                     ],
//                   );
//                 },
//                 child: FutureBuilder<String?>(
//                   future: _storage.read(key: 'userPhotoUrl'),
//                   builder: (
//                     BuildContext context,
//                     AsyncSnapshot<String?> snapshot,
//                   ) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const CircleAvatar(radius: 20);
//                     } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
//                       return const CircleAvatar(
//                         radius: 20,
//                         child: Icon(Icons.person),
//                       );
//                     } else {
//                       return Padding(
//                         padding: const EdgeInsets.only(right: 16.0),
//                         child: CircleAvatar(
//                           radius: 20,
//                           backgroundImage: _getProfileImage(
//                             _profile?.photo,
//                             snapshot.data!,
//                           ),
//                           child: (_profile?.photo == null && snapshot.data == null)
//                               ? const Icon(Icons.person, color: Colors.white)
//                               : null,
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Builder(
//         builder: (context) {
//           switch (_bottomNavIndex) {
//             case 0:
//               return const ProductsPage();
//             case 1:
//               return const CartPage();
//             case 2:
//               return const OrdersPage();
//             case 3:
//               return const RestaurantsPage();
//             default:
//               return const Center(child: Text('Página no encontrada'));
//           }
//         },
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: _getBottomNavItems(),
//         currentIndex: _bottomNavIndex,
//         selectedItemColor: Colors.blueAccent,
//         unselectedItemColor: Colors.grey,
//         onTap: _onBottomNavTapped,
//       ),
//     );
//   }
// }

// ImageProvider<Object> _getProfileImage(String? profilePhoto, String? googlePhotoUrl) {
//   if (profilePhoto != null && profilePhoto.isNotEmpty) {
//     logger.i('Usando foto del perfil: $profilePhoto');
//     return NetworkImage(profilePhoto); // Imagen del perfil del usuario
//   }
//   if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
//     logger.i('Usando foto de Google: $googlePhotoUrl');
//     return NetworkImage(googlePhotoUrl); // Imagen de Google
//   }
//   logger.w('Usando imagen predeterminada');
//   return const AssetImage('assets/default_avatar.png'); // Imagen predeterminada
// }

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:logger/logger.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/auth/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:zonix/config/user_provider.dart';
import 'package:zonix/products/providers/product_provider.dart';
import 'package:flutter/services.dart';

// import 'dart:io';
// import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:zonix/auth/screens/sign_in_screen.dart';

import 'package:zonix/products/screens/marketplace_screen.dart';
import 'package:zonix/favorites/screens/favorites_screen.dart';
import 'package:zonix/products/screens/create_screen.dart';
import 'package:zonix/chat/screens/messages_screen.dart';
import 'package:zonix/profiles/screens/profile_screen.dart';

/*
 * ZONIX EATS - Aplicación Multi-Rol
 * 
 * Niveles de usuario:
 * 0 - Comprador: Productos, Carrito, Mis Órdenes, Restaurantes
 * 1 - Tiendas/Comercio: Dashboard, Inventario, Órdenes, Reportes
 * 2 - Delivery: Entregas, Historial, Rutas, Ganancias
 * 3 - Agencia de Transporte: Flota, Conductores, Rutas, Métricas
 * 4 - Afiliado a Delivery: Afiliaciones, Comisiones, Soporte, Estadísticas
 * 5 - Administrador: Panel Admin, Usuarios, Seguridad, Sistema
 */

final ApiService apiService = ApiService();

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

// Configuración del logger
final logger = Logger();

//  class MyHttpOverrides extends HttpOverrides{
//   @override
//   HttpClient createHttpClient(SecurityContext? context){
//     return super.createHttpClient(context)
//       ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
//   }
// }

// void main() {
Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  initialization();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load();

  // Bypass de login para tests de integración
  final bool isIntegrationTest =
      const String.fromEnvironment('INTEGRATION_TEST', defaultValue: 'false') ==
          'true';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MyApp(isIntegrationTest: isIntegrationTest),
    ),
  );
}

void initialization() async {
  logger.i('Initializing...');
  await Future.delayed(const Duration(seconds: 3));
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  final bool isIntegrationTest;
  const MyApp({super.key, this.isIntegrationTest = false});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (isIntegrationTest) {
      // Forzar autenticación como comercio
      userProvider.setAuthenticatedForTest(role: 'commerce');
    } else {
      userProvider.checkAuthentication();
    }

    return MaterialApp(
      title: 'CorralX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF333333),
          elevation: 0,
          shadowColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: const Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF4CAF50),
          error: const Color(0xFFE53935),
          surface: Colors.white,
          onSurface: const Color(0xFF333333),
          onSurfaceVariant: const Color(0xFF666666),
        ),
        cardColor: Colors.white,
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFF2E7D32),
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF66BB6A),
          error: const Color(0xFFEF5350),
          surface: const Color(0xFF1E1E1E),
          onSurface: Colors.white,
          onSurfaceVariant: Colors.white70,
        ),
        cardColor: const Color(0xFF1E1E1E),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFF4CAF50),
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          logger.i('isAuthenticated: ${userProvider.isAuthenticated}');
          if (userProvider.isAuthenticated) {
            return const MainRouter();
          } else {
            return const SignInScreen();
          }
        },
      ),
      routes: {
        // Rutas básicas del MVP
      },
    );
  }
}

class MainRouter extends StatefulWidget {
  const MainRouter({super.key});

  @override
  MainRouterState createState() => MainRouterState();
}

class MainRouterState extends State<MainRouter> {
  int _selectedLevel = 0;
  int _bottomNavIndex = 0;
  dynamic _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLastPosition();
  }

  Future<void> _loadProfile() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Obtén los detalles del usuario y verifica su contenido
      final userDetails = await userProvider.getUserDetails();

      // Extrae y valida el ID del usuario
      final id = userDetails['userId'];
      if (id == null || id is! int) {
        throw Exception('El ID del usuario es inválido: $id');
      }
      // Perfil simplificado para MVP
      // _profile = await ProfileService().getProfileById(id);

      setState(() {});
    } catch (e) {
      logger.e('Error obteniendo el ID del usuario: $e');
    }
  }

  Future<void> _loadLastPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLevel = prefs.getInt('selectedLevel') ?? 0;
      _bottomNavIndex = prefs.getInt('bottomNavIndex') ?? 0;
      logger.i(
        'Loaded last position - selectedLevel: $_selectedLevel, bottomNavIndex: $_bottomNavIndex',
      );
    });
  }

  Future<void> _saveLastPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedLevel', _selectedLevel);
    await prefs.setInt('bottomNavIndex', _bottomNavIndex);
    logger.i(
      'Saved last position - selectedLevel: $_selectedLevel, bottomNavIndex: $_bottomNavIndex',
    );
  }

  // Función para obtener los items del BottomNavigationBar (solo 2 niveles)
  List<BottomNavigationBarItem> _getBottomNavItems(int level, String role) {
    List<BottomNavigationBarItem> items = [];

    switch (level) {
      case 0: // Users (compra y vende)
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Mercado',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Publicar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mensajes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ];
        break;
      case 1: // Admin
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Panel Admin',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Usuarios',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Seguridad',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_system_daydream),
            label: 'Sistema',
          ),
        ];
        break;
      default:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
        ];
    }

    return items;
  }

  // Función para manejar el tap en el BottomNavigationBar
  void _onBottomNavTapped(int index, int itemCount) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    logger.i('Bottom navigation tapped: $index, Total items: $itemCount');

    // Verifica si el índice seleccionado es el último item
    if (index == itemCount - 1) {
      Navigator.push(
        context,
        // MaterialPageRoute(builder: (context) => const SettingsPage2()),
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    } else {
      setState(() {
        _bottomNavIndex = index; // Actualiza el índice seleccionado
        logger.i('Bottom nav index changed to: $_bottomNavIndex');
        _saveLastPosition();
      });
    }
  }

  // Dentro de tu widget donde tienes el BottomNavigationBar

  void _onLevelSelected(int level) {
    setState(() {
      _selectedLevel = level;
      _bottomNavIndex = 0;
      _saveLastPosition();
    });
  }

  Widget _createLevelButton(int level, IconData icon, String tooltip) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FloatingActionButton.small(
      heroTag: 'level$level',
      backgroundColor: _selectedLevel == level
          ? const Color(0xFF2E7D32)
          : isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
      child: Icon(
        icon,
        color: _selectedLevel == level
            ? Colors.white
            : isDark
                ? Colors.white.withOpacity(0.7)
                : Colors.grey[600],
        size: 20,
      ),
      onPressed: () => _onLevelSelected(level),
    );
  }

  Widget _buildComingSoonScreen(String title) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C18),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Próximamente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta funcionalidad estará disponible en futuras versiones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        leading: null,
        title: Image.asset(
          isDark
              ? 'assets/splash/branding_dark_2048x1024.png'
              : 'assets/splash/branding_light_2048x1024.png',
          height: 90,
          fit: BoxFit.contain,
        ),
        centerTitle: false,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return FutureBuilder<Map<String, dynamic>>(
            future: userProvider.getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                logger.e('Error fetching user details: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              } // Dentro del FutureBuilder
              else {
                final role = userProvider.userRole;
                logger.i('Role fetched: $role');

                // if (_selectedLevel == 0) {
                //   if (_bottomNavIndex == 0) return const HelpAndFAQPage();
                //   if (_bottomNavIndex == 1) return const HelpAndFAQPage();
                //   if (_bottomNavIndex == 2 && role == 'sales_admin') return const TicketScannerScreen();
                //   if (_bottomNavIndex == 3 && role == 'sales_admin') return const CheckScannerScreen();
                //   if (_bottomNavIndex == 2 && role == 'dispatcher') return const DispatcherScreen();
                // }

                // Nivel 0: Users (compra y vende)
                if (_selectedLevel == 0) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return const MarketplaceScreen();
                    case 1:
                      return const FavoritesScreen();
                    case 2:
                      return const CreateScreen();
                    case 3:
                      return const MessagesScreen();
                    case 4:
                      return const ProfileScreen();
                    default:
                      return const MarketplaceScreen();
                  }
                }

                // Nivel 1: Admin
                if (_selectedLevel == 1) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return _buildComingSoonScreen('Panel Admin');
                    case 1:
                      return _buildComingSoonScreen('Gestión de Usuarios');
                    case 2:
                      return _buildComingSoonScreen('Seguridad');
                    case 3:
                      return _buildComingSoonScreen('Sistema');
                    default:
                      return _buildComingSoonScreen('Panel Admin');
                  }
                }

                // Si no se cumplen ninguna de las condiciones anteriores, puedes manejar un caso por defecto.
                return const Center(
                  child: Text('Rol no reconocido o página no encontrada'),
                );
              }
            },
          );
        },
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 80,
        type: ExpandableFabType.up,
        children: [
          _createLevelButton(0, Icons.shopping_bag, 'Users (Compra y Vende)'),
          _createLevelButton(1, Icons.admin_panel_settings, 'Admin'),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          items: _getBottomNavItems(_selectedLevel, userProvider.userRole),
          currentIndex: _bottomNavIndex,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            // Obtener el itemCount llamando a _getBottomNavItems antes de la navegación
            List<BottomNavigationBarItem> items = _getBottomNavItems(
              _selectedLevel,
              userProvider.userRole,
            );
            int itemCount = items.length;

            // Llamar a la función _onBottomNavTapped con el index y el itemCount
            _onBottomNavTapped(index, itemCount);
          },
        ),
      ),
    );
  }
}

ImageProvider<Object> _getProfileImage(
    String? profilePhoto, String? googlePhotoUrl) {
  if (profilePhoto != null && profilePhoto.isNotEmpty) {
    // Detectar URLs de placeholder y evitarlas
    if (profilePhoto.contains('via.placeholder.com') ||
        profilePhoto.contains('placeholder.com') ||
        profilePhoto.contains('placehold.it')) {
      logger.w(
          'Detectada URL de placeholder en perfil, usando imagen local: $profilePhoto');
      return const AssetImage('assets/default_avatar.png');
    }

    logger.i('Usando foto del perfil: $profilePhoto');
    return NetworkImage(profilePhoto); // Imagen del perfil del usuario
  }
  if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
    logger.i('Usando foto de Google: $googlePhotoUrl');
    return NetworkImage(googlePhotoUrl); // Imagen de Google
  }
  logger.w('Usando imagen predeterminada');
  return const AssetImage('assets/default_avatar.png'); // Imagen predeterminada
}
