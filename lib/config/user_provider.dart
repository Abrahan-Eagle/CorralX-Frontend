import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:corralx/config/auth_utils.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:corralx/chat/services/firebase_service.dart';

final logger = Logger();
const FlutterSecureStorage _storage = FlutterSecureStorage();

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

class UserProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _profileCreated = false;
  bool _adresseCreated = false;
  bool _documentCreated = false;
  bool _gasCylindersCreated = false;
  bool _phoneCreated = false;
  bool _emailCreated = false;
  bool _isDeletingAccount = false;

  String _userName = '';
  String _userEmail = '';
  String _userPhotoUrl = '';
  int _userId = 0;
  String _userGoogleId = '';
  String _role = '';

  // Getters para obtener la información del usuario
  bool get isAuthenticated => _isAuthenticated;
  bool get profileCreated => _profileCreated;
  bool get adresseCreated => _adresseCreated;
  bool get documentCreated => _documentCreated;
  bool get gasCylindersCreated => _gasCylindersCreated;
  bool get phoneCreated => _phoneCreated;
  bool get emailCreated => _emailCreated;
  bool get isDeletingAccount => _isDeletingAccount;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhotoUrl => _userPhotoUrl;
  int get userId => _userId;
  String get userGoogleId => _userGoogleId;
  String get userRole => _role;

  // Getter para obtener el usuario completo
  Map<String, dynamic> get user => {
        'id': _userId,
        'name': _userName,
        'email': _userEmail,
        'photo_url': _userPhotoUrl,
        'google_id': _userGoogleId,
        'role': _role,
      };

  // Setter para actualizar el estado de creación de perfil
  void setProfileCreated(bool value) {
    _profileCreated = value;
    _storage.write(key: 'profileCreated', value: value.toString());
    notifyListeners();
  }

  void setAdresseCreated(bool value) {
    _adresseCreated = value;
    _storage.write(key: 'adresseCreated', value: value.toString());
    notifyListeners();
  }

  void setDocumentCreated(bool value) {
    _documentCreated = value;
    _storage.write(key: 'documentCreated', value: value.toString());
    notifyListeners();
  }

  void setGasCylindersCreated(bool value) {
    _gasCylindersCreated = value;
    _storage.write(key: 'gasCylindersCreated', value: value.toString());
    notifyListeners();
  }

  void setPhoneCreated(bool value) {
    _phoneCreated = value;
    _storage.write(key: 'phoneCreated', value: value.toString());
    notifyListeners();
  }

  void setEmailCreated(bool value) {
    _emailCreated = value;
    _storage.write(key: 'emailCreated', value: value.toString());
    notifyListeners();
  }

  // Verifica si el usuario está autenticado y carga los datos si es necesario
  Future<void> checkAuthentication() async {
    try {
      _isAuthenticated = await AuthUtils.isAuthenticated();
      if (_isAuthenticated) {
        await getUserDetails();
        await _loadUserData();
        logger.i('Final userId: $_userId');
        
        // 🔔 Registrar FCM token después de verificar autenticación (auto-login)
        try {
          await FirebaseService.registerDeviceToken();
          logger.i('✅ FCM token registrado después de auto-login');
        } catch (e) {
          logger.w('⚠️ Error registrando FCM token después de auto-login: $e');
          // No bloquear si falla
        }
      }
    } catch (e) {
      debugPrint('Error al verificar autenticación: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadUserData() async {
    try {
      _userName = await AuthUtils.getUserName() ?? '';
      _userEmail = await AuthUtils.getUserEmail() ?? '';
      _userPhotoUrl = await AuthUtils.getUserPhotoUrl() ?? '';
      _role = await AuthUtils.getUserRole() ?? '';
      _userId = await AuthUtils.getUserId() ?? 0;
      _userGoogleId = await AuthUtils.getUserGoogleId() ?? '';
      _profileCreated = (await _storage.read(key: 'profileCreated')) == 'true';
      _adresseCreated = (await _storage.read(key: 'adresseCreated')) == 'true';
      _documentCreated =
          (await _storage.read(key: 'documentCreated')) == 'true';
      _gasCylindersCreated =
          (await _storage.read(key: 'gasCylindersCreated')) == 'true';
      _phoneCreated = (await _storage.read(key: 'phoneCreated')) == 'true';
      _emailCreated = (await _storage.read(key: 'emailCreated')) == 'true';
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
    }
  }

  Future<Map<String, dynamic>> getUserDetails() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado. El usuario no está autenticado.');
      }

      logger.i('Retrieved token: $token');
      final response = await http.get(
        // Uri.parse('${AppConfig.apiUrl}/api/auth/user'),
        Uri.parse('$baseUrl/api/auth/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Manejar el formato de respuesta del backend {success: true, data: {...}}
        Map<String, dynamic> userDetails;
        if (responseData.containsKey('success') &&
            responseData.containsKey('data')) {
          if (responseData['success'] == true) {
            userDetails = responseData['data'];
          } else {
            throw Exception(responseData['message'] ??
                'Error al obtener detalles del usuario');
          }
        } else {
          // Fallback para respuestas sin formato estándar
          userDetails = responseData;
        }

        _userGoogleId = userDetails['google_id'] ?? '';
        _userId = userDetails['id'] ?? 0;
        _role = userDetails['role'] ?? '';
        
        // Actualizar email si viene en la respuesta
        if (userDetails['email'] != null) {
          _userEmail = userDetails['email'] ?? '';
          await AuthUtils.saveUserEmail(_userEmail);
          logger.i('✅ Email actualizado desde backend: $_userEmail');
        }

        logger.i('User details: $userDetails');
        logger.i('User role: $_role');
        return {
          'users': userDetails,
          'role': _role,
          'userId': _userId,
          'userGoogleId': _userGoogleId
        };
      } else {
        logger.e('Error: ${response.statusCode} - ${response.body}');
        throw Exception('Error al obtener detalles del usuario');
      }
    } catch (e) {
      logger.e('Exception: $e');
      rethrow;
    }
  }

  // Guarda los datos del usuario autenticado y actualiza el estado
  Future<void> setUserData(GoogleSignInAccount googleUser) async {
    try {
      _updateUserInfo(
        name: googleUser.displayName ?? '',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl ?? '',
      );

      await AuthUtils.saveUserName(_userName);
      await AuthUtils.saveUserEmail(_userEmail);
      await AuthUtils.saveUserPhotoUrl(_userPhotoUrl);
      await AuthUtils.saveUserId(_userId);
      await AuthUtils.saveUserGoogleId(_userGoogleId);

      _isAuthenticated = true;
    } catch (e) {
      debugPrint('Error al guardar datos del usuario: $e');
    } finally {
      notifyListeners();
    }
  }

  // Actualiza la información del usuario en memoria
  void _updateUserInfo(
      {required String name, required String email, required String photoUrl}) {
    _userName = name;
    _userEmail = email;
    _userPhotoUrl = photoUrl;
  }

  /// Recargar el email del backend (útil después de actualizar el perfil)
  Future<void> refreshUserEmail() async {
    try {
      logger.i('🔄 Refrescando email del usuario desde backend...');
      await getUserDetails();
      
      // El email ya se actualizó en getUserDetails() si venía en la respuesta
      // Pero también actualizamos desde storage por si acaso
      await _loadUserData();
      
      logger.i('✅ Email refrescado: $_userEmail');
      notifyListeners();
    } catch (e) {
      logger.w('⚠️ Error al refrescar email: $e');
      // No lanzar error, solo loguear
    }
  }

  Future<void> logout() async {
    try {
      // Intentar cerrar sesión en el backend (no crítico si falla)
      try {
        await AuthUtils.logout();
      } catch (e) {
        logger.w(
            'Error al cerrar sesión en backend (continuando limpieza local): $e');
      }

      // Cerrar sesión de Google (no crítico si falla)
      try {
        await GoogleSignIn().signOut();
      } catch (e) {
        logger.w(
            'Error al cerrar sesión de Google (continuando limpieza local): $e');
      }

      // Siempre limpiar datos locales, incluso si falló el backend
      await _clearUserData();

      logger.i('Logout completado exitosamente');
    } catch (e) {
      logger.e('Error crítico al cerrar sesión: $e');
      // Aún así intentar limpiar datos locales
      try {
        await _clearUserData();
      } catch (clearError) {
        logger.e('Error al limpiar datos locales: $clearError');
      }
      rethrow; // Re-lanzar para que el UI pueda manejarlo
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isDeletingAccount = true;
    notifyListeners();

    try {
      await AuthUtils.deleteAccount();

      try {
        await GoogleSignIn().signOut();
      } catch (e) {
        logger.w('Error al cerrar sesión de Google tras eliminar cuenta: $e');
      }

      await _clearUserData();
      logger.i('Cuenta eliminada exitosamente');
    } catch (e) {
      logger.e('Error al eliminar cuenta: $e');
      rethrow;
    } finally {
      _isDeletingAccount = false;
      notifyListeners();
    }
  }

  // Limpia la información del usuario
  Future<void> _clearUserData() async {
    // Limpiar estado en memoria
    _isAuthenticated = false;
    _profileCreated = false;
    _adresseCreated = false;
    _documentCreated = false;
    _gasCylindersCreated = false;
    _phoneCreated = false;
    _emailCreated = false;
    _userName = '';
    _userEmail = '';
    _userPhotoUrl = '';
    _userId = 0;
    _userGoogleId = '';

    // Limpiar en el almacenamiento seguro (todos los campos relacionados)
    try {
      await _storage.delete(key: 'profileCreated');
      await _storage.delete(key: 'adresseCreated');
      await _storage.delete(key: 'documentCreated');
      await _storage.delete(key: 'gasCylindersCreated');
      await _storage.delete(key: 'phoneCreated');
      await _storage.delete(key: 'emailCreated');
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'userId');
      await _storage.delete(key: 'userName');
      await _storage.delete(key: 'userEmail');
      await _storage.delete(key: 'userPhotoUrl');
      await _storage.delete(key: 'userGoogleId');
      await _storage.delete(key: 'role');
      await _storage.delete(key: 'expiryDate');
      await _storage.delete(key: 'google_idToken');
      // Limpiar estado de onboarding para permitir nuevo registro
      await _storage.delete(key: 'userCompletedOnboarding');
      // Limpiar drafts del onboarding si existen
      await _storage.delete(key: 'onboarding_personal_draft');
      await _storage.delete(key: 'onboarding_ranch_draft');
      logger.i(
          'Datos de usuario limpiados correctamente, incluyendo estado de onboarding');
    } catch (e) {
      logger.e('Error al limpiar almacenamiento seguro: $e');
      // Si falla la limpieza individual, intentar limpiar todo
      try {
        await _storage.deleteAll();
        logger.i('Limpieza completa del almacenamiento ejecutada');
      } catch (deleteAllError) {
        logger.e('Error crítico al limpiar almacenamiento: $deleteAllError');
      }
    }
  }

  // Bypass de login para tests de integración
  void setAuthenticatedForTest({String role = 'commerce'}) {
    _isAuthenticated = true;
    _role = role;
    _userId = 9999;
    _userName = 'Test Commerce';
    _userEmail = 'test@commerce.com';
    _userPhotoUrl = '';
    notifyListeners();
  }
}
