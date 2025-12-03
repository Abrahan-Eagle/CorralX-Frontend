import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corralx/profiles/models/profile.dart';
import 'package:corralx/profiles/models/ranch.dart' as ProfileModels;
import 'package:corralx/profiles/services/profile_service.dart';
import 'package:corralx/products/models/product.dart';
import 'package:corralx/config/user_provider.dart';

/// Provider para gestionar el estado de perfiles
class ProfileProvider extends ChangeNotifier {
  // ========== PERFIL PROPIO ==========
  Profile? _myProfile;
  bool _isLoadingMyProfile = false;
  String? _myProfileError;

  Profile? get myProfile => _myProfile;
  bool get isLoadingMyProfile => _isLoadingMyProfile;
  String? get myProfileError => _myProfileError;

  // ========== PERFIL PÚBLICO ==========
  Profile? _publicProfile;
  bool _isLoadingPublicProfile = false;
  String? _publicProfileError;
  int? _publicProfileUserId; // Para trackear qué perfil está cargado

  Profile? get publicProfile => _publicProfile;
  bool get isLoadingPublicProfile => _isLoadingPublicProfile;
  String? get publicProfileError => _publicProfileError;

  // ========== PRODUCTOS DEL PERFIL ==========
  List<Product> _myProducts = [];
  bool _isLoadingMyProducts = false;
  String? _myProductsError;
  int _myProductsTotal = 0;
  int _myProductsCurrentPage = 1;

  List<Product> get myProducts => _myProducts;
  bool get isLoadingMyProducts => _isLoadingMyProducts;
  String? get myProductsError => _myProductsError;
  int get myProductsTotal => _myProductsTotal;
  int get myProductsCurrentPage => _myProductsCurrentPage;

  // ========== RANCHES DEL PERFIL ==========
  List<ProfileModels.Ranch> _myRanches = [];
  bool _isLoadingMyRanches = false;
  String? _myRanchesError;

  List<ProfileModels.Ranch> get myRanches => _myRanches;
  bool get isLoadingMyRanches => _isLoadingMyRanches;
  String? get myRanchesError => _myRanchesError;

  // ========== MÉTRICAS ==========
  Map<String, dynamic>? _metrics;
  bool _isLoadingMetrics = false;
  String? _metricsError;

  Map<String, dynamic>? get metrics => _metrics;
  bool get isLoadingMetrics => _isLoadingMetrics;
  String? get metricsError => _metricsError;

  // ========== ESTADO DE EDICIÓN ==========
  bool _isUpdating = false;
  String? _updateError;
  Map<String, dynamic>? _validationErrors;

  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;
  Map<String, dynamic>? get validationErrors => _validationErrors;

  // ========== MÉTODOS: PERFIL PROPIO ==========

  /// Cargar perfil propio desde el backend
  Future<void> fetchMyProfile({bool forceRefresh = false}) async {
    // Si ya está cargado y no es force refresh, no volver a cargar
    if (_myProfile != null && !forceRefresh) {
      print('✅ ProfileProvider: Perfil ya cargado en caché');
      return;
    }

    print('🔍 ProfileProvider.fetchMyProfile iniciado');
    _isLoadingMyProfile = true;
    _myProfileError = null;
    notifyListeners();

    try {
      final response = await ProfileService.getMyProfile();

      if (response['success'] == true) {
        _myProfile = Profile.fromJson(response['profile']);
        _myProfileError = null;
        print('✅ ProfileProvider: Perfil cargado exitosamente');
      } else {
        _myProfileError = 'Error al cargar perfil';
        print('❌ ProfileProvider: Error en respuesta');
      }
    } catch (e) {
      _myProfileError = e.toString();
      print('❌ ProfileProvider: Error al cargar perfil: $e');
    } finally {
      _isLoadingMyProfile = false;
      notifyListeners();
    }
  }

  /// Actualizar perfil propio
  Future<bool> updateProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? secondLastName,
    String? bio,
    DateTime? dateOfBirth,
    String? maritalStatus,
    String? sex,
    String? ciNumber,
    bool? acceptsCalls,
    bool? acceptsWhatsapp,
    bool? acceptsEmails,
    String? whatsappNumber,
    BuildContext? context, // Contexto opcional para refrescar email
  }) async {
    print('🔍 ProfileProvider.updateProfile iniciado');
    _isUpdating = true;
    _updateError = null;
    _validationErrors = null;
    notifyListeners();

    try {
      final response = await ProfileService.updateProfile(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        secondLastName: secondLastName,
        bio: bio,
        dateOfBirth: dateOfBirth,
        maritalStatus: maritalStatus,
        sex: sex,
        ciNumber: ciNumber,
        acceptsCalls: acceptsCalls,
        acceptsWhatsapp: acceptsWhatsapp,
        acceptsEmails: acceptsEmails,
        whatsappNumber: whatsappNumber,
      );

      if (response['success'] == true) {
        // Actualizar el perfil en caché
        _myProfile = Profile.fromJson(response['profile']);
        _updateError = null;
        _validationErrors = null;
        print('✅ ProfileProvider: Perfil actualizado exitosamente');
        
        // Recargar el email en UserProvider para que se actualice en tiempo real
        // Esto es necesario porque el email puede cambiar en el backend
        if (context != null) {
          try {
            // Obtener UserProvider antes del await para evitar usar context después de async gap
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            await userProvider.refreshUserEmail();
            print('✅ Email refrescado en UserProvider');
          } catch (e) {
            print('⚠️ Error al refrescar email: $e');
            // No bloquear si falla
          }
        }
        
        notifyListeners();
        return true;
      } else {
        // Error de validación (422)
        _updateError = response['message'] ?? 'Error de validación';
        _validationErrors = response['errors'];
        print('❌ ProfileProvider: Error de validación: $_updateError');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _updateError = e.toString();
      print('❌ ProfileProvider: Error al actualizar perfil: $e');
      notifyListeners();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Subir foto de perfil
  Future<bool> uploadPhoto(File photo) async {
    print('🔍 ProfileProvider.uploadPhoto iniciado');
    _isUpdating = true;
    _updateError = null;
    _validationErrors = null;
    notifyListeners();

    try {
      final response = await ProfileService.uploadProfilePhoto(photo);

      if (response['success'] == true) {
        // Actualizar el perfil en caché con la nueva foto
        _myProfile = Profile.fromJson(response['profile']);
        _updateError = null;
        _validationErrors = null;
        print('✅ ProfileProvider: Foto actualizada exitosamente');
        notifyListeners();
        return true;
      } else {
        _updateError = response['message'] ?? 'Error al subir foto';
        _validationErrors = response['errors'];
        print('❌ ProfileProvider: Error de validación: $_updateError');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _updateError = e.toString();
      print('❌ ProfileProvider: Error al subir foto: $e');
      notifyListeners();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS: PERFIL PÚBLICO ==========

  /// Cargar perfil público de otro usuario
  Future<void> fetchPublicProfile(int userId,
      {bool forceRefresh = false}) async {
    // Si ya está cargado el mismo perfil y no es force refresh, no volver a cargar
    if (_publicProfile != null &&
        _publicProfileUserId == userId &&
        !forceRefresh) {
      print('✅ ProfileProvider: Perfil público ya cargado en caché');
      return;
    }

    print('🔍 ProfileProvider.fetchPublicProfile iniciado - userId: $userId');
    _isLoadingPublicProfile = true;
    _publicProfileError = null;
    _publicProfileUserId = userId;
    notifyListeners();

    try {
      final response = await ProfileService.getPublicProfile(userId);

      if (response['success'] == true) {
        _publicProfile = Profile.fromJson(response['profile']);
        _publicProfileError = null;
        print('✅ ProfileProvider: Perfil público cargado exitosamente');
      } else {
        _publicProfileError = 'Error al cargar perfil';
        print('❌ ProfileProvider: Error en respuesta');
      }
    } catch (e) {
      _publicProfileError = e.toString();
      print('❌ ProfileProvider: Error al cargar perfil público: $e');
    } finally {
      _isLoadingPublicProfile = false;
      notifyListeners();
    }
  }

  /// Limpiar perfil público (al salir de la vista)
  void clearPublicProfile() {
    _publicProfile = null;
    _publicProfileUserId = null;
    _publicProfileError = null;
    print('🧹 ProfileProvider: Perfil público limpiado');
    notifyListeners();
  }

  // ========== MÉTODOS: PRODUCTOS ==========

  /// Cargar productos del perfil (mis publicaciones)
  Future<void> fetchMyProducts({int page = 1, bool refresh = false}) async {
    print('🔍 ProfileProvider.fetchMyProducts iniciado - page: $page');

    if (refresh) {
      _myProducts = [];
      _myProductsCurrentPage = 1;
    }

    _isLoadingMyProducts = true;
    _myProductsError = null;
    notifyListeners();

    try {
      final response = await ProfileService.getProfileProducts(
        page: page,
        perPage: 20,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> productList = data['data'] ?? [];

        final products =
            productList.map((json) => Product.fromJson(json)).toList();

        if (refresh) {
          _myProducts = products;
        } else {
          _myProducts.addAll(products);
        }

        _myProductsTotal = data['total'] ?? 0;
        _myProductsCurrentPage = page;
        _myProductsError = null;

        print('✅ ProfileProvider: ${products.length} productos cargados');
      } else {
        _myProductsError = 'Error al cargar productos';
        print('❌ ProfileProvider: Error en respuesta');
      }
    } catch (e) {
      _myProductsError = e.toString();
      print('❌ ProfileProvider: Error al cargar productos: $e');
    } finally {
      _isLoadingMyProducts = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS: RANCHES ==========

  /// Cargar haciendas del perfil
  Future<void> fetchMyRanches({bool forceRefresh = false}) async {
    if (_myRanches.isNotEmpty && !forceRefresh) {
      print('✅ ProfileProvider: Ranches ya cargados en caché');
      return;
    }

    print('🔍 ProfileProvider.fetchMyRanches iniciado');
    _isLoadingMyRanches = true;
    _myRanchesError = null;
    notifyListeners();

    try {
      final ranches = await ProfileService.getProfileRanches();

      _myRanches = ranches;
      _myRanchesError = null;
      print('✅ ProfileProvider: ${ranches.length} ranches cargados');
    } catch (e) {
      _myRanchesError = e.toString();
      print('❌ ProfileProvider: Error al cargar ranches: $e');
    } finally {
      _isLoadingMyRanches = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS: MÉTRICAS ==========

  /// Cargar métricas del perfil
  Future<void> fetchMetrics({bool forceRefresh = false}) async {
    if (_metrics != null && !forceRefresh) {
      print('✅ ProfileProvider: Métricas ya cargadas en caché');
      return;
    }

    print('🔍 ProfileProvider.fetchMetrics iniciado');
    _isLoadingMetrics = true;
    _metricsError = null;
    notifyListeners();

    try {
      final response = await ProfileService.getProfileMetrics();

      if (response['success'] == true) {
        _metrics = response['metrics'];
        _metricsError = null;
        print('✅ ProfileProvider: Métricas cargadas exitosamente');
      } else {
        _metricsError = 'Error al cargar métricas';
        print('❌ ProfileProvider: Error en respuesta');
      }
    } catch (e) {
      _metricsError = e.toString();
      print('❌ ProfileProvider: Error al cargar métricas: $e');
    } finally {
      _isLoadingMetrics = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS: UTILIDADES ==========

  /// Limpiar errores
  void clearErrors() {
    _myProfileError = null;
    _publicProfileError = null;
    _myProductsError = null;
    _myRanchesError = null;
    _metricsError = null;
    _updateError = null;
    _validationErrors = null;
    notifyListeners();
  }

  /// Refrescar todo el perfil (perfil + productos + ranches + métricas)
  Future<void> refreshAll() async {
    print('🔄 ProfileProvider: Refrescando todos los datos...');
    await Future.wait([
      fetchMyProfile(forceRefresh: true),
      fetchMyProducts(refresh: true),
      fetchMyRanches(forceRefresh: true),
      fetchMetrics(forceRefresh: true),
    ]);
    print('✅ ProfileProvider: Todos los datos refrescados');
  }
}
