import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:corralx/config/auth_utils.dart';
import 'package:corralx/auth/services/api_service.dart';
import 'package:corralx/chat/services/firebase_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();

// Configuración de GoogleSignIn con serverClientId para obtener idToken válido
// Client ID de Web: necesario para que el backend pueda validar el token
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['openid', 'profile', 'email'],
  serverClientId: '332023551639-2hpmjjs8j2jn70g7ppdhsfujeosfha7b.apps.googleusercontent.com', // Client ID de Web
);

final Logger logger = Logger();
final ApiService _apiService = ApiService();

class GoogleSignInService {
  // Método para iniciar sesión con Google
  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        logger.i('Inicio de sesión cancelado');
        return null; // Retorna null si el usuario cancela la autenticación
      }

      final googleAuth = await user.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      
      // Logs para verificar que se obtiene idToken con serverClientId
      logger.i('🔑 OAuth2 Tokens obtenidos:');
      logger.i('   - accessToken: ${accessToken != null ? "✅ Obtenido (${accessToken.substring(0, 20)}...)" : "❌ null"}');
      logger.i('   - idToken: ${idToken != null ? "✅ Obtenido (${idToken.substring(0, 20)}...)" : "❌ null"}');
      logger.i('   - serverClientId configurado: ✅ Sí');
      
      if (accessToken == null && idToken == null) {
        logger.e('Error: Tanto el accessToken como el idToken son null');
        return null; // Retorna null si no hay ni accessToken ni idToken
      }

      // Guardar tokens de Google
      if (accessToken != null) {
        await AuthUtils.saveToken(
            accessToken, 3600); // Ajusta el tiempo de expiración
        logger.i('💾 accessToken guardado temporalmente');
      }
      if (idToken != null) {
        await _storage.write(key: 'google_idToken', value: idToken);
        logger.i('💾 idToken guardado en secure storage');
      } else {
        logger.w('⚠️ idToken no disponible - Verificar configuración de serverClientId');
      }

      // Obtener datos del perfil del usuario utilizando el accessToken
      final profileResponse = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {
          'Authorization': 'Bearer ${accessToken ?? idToken}',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        logger.i('Datos del perfil de usuario: ${jsonEncode(profileData)}');

        // Enviar el token al backend
        final processedResult = jsonEncode({
          'token': accessToken ?? idToken,
          'profile': profileData,
        });

        final response = await _apiService.sendTokenToBackend(processedResult);

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          
          // Handle the nested response structure
          final data = responseData['data'] ?? responseData;
          final token = data['token'] ?? responseData['token'];
          final userRole = data['user']?['role'] ?? 'users';
          final expiresIn = data['expires_in'] ?? 3600;
          
          if (token != null) {
            await AuthUtils.saveToken(token, expiresIn);
            await _storage.write(key: 'role', value: userRole);
            logger.i('Token guardado correctamente con su expiración.');
            
            // 🔔 Re-registrar device token de FCM después del login exitoso
            try {
              await FirebaseService.registerDeviceToken();
              logger.i('✅ FCM token re-registrado después del login');
            } catch (e) {
              logger.w('⚠️ Error re-registrando FCM token: $e');
              // No bloquear el login si falla el registro de FCM token
            }
            
            return user; // Retorna el usuario autenticado
          } else {
            logger.e('Token no encontrado en la respuesta del backend');
            return null;
          }
        } else {
          logger
              .e('Error al enviar el token al backend: ${response.statusCode}');
          return null; // Retorna null si hay error al enviar el token al backend
        }
      } else {
        logger.e(
            'Error al obtener los datos del perfil: ${profileResponse.statusCode}');
        return null; // Retorna null si no se pueden obtener los datos del perfil
      }
    } catch (error) {
      logger.e('Error durante el inicio de sesión con Google: $error');
      return null; // Retorna null si hay una excepción
    }
  }

  // Método para obtener el usuario autenticado actualmente
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.signInSilently();
      if (user != null) {
        logger.i('Usuario actualmente autenticado: ${user.email}');
        return user; // Devuelve el usuario autenticado directamente
      } else {
        logger.i('No hay usuario autenticado actualmente.');
      }
    } catch (error) {
      logger.e('Error al intentar autenticar de forma silenciosa: $error');
      return null;
    }
    return null; // Devuelve null si no hay usuario autenticado
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _storage.deleteAll(); // Eliminar los tokens almacenados
      logger.i('Sesión cerrada exitosamente.');
    } catch (error) {
      logger.e('Error al cerrar sesión: $error');
    }
  }

  // Inicialización: Verifica si hay un usuario autenticado silenciosamente al iniciar la app
  Future<void> initAuth() async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      logger.i('Usuario autenticado automáticamente: ${currentUser.email}');
    } else {
      logger.i(
          'No se detectó ningún usuario autenticado. Requiere inicio de sesión.');
    }
  }
}
