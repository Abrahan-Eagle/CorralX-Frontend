import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:corralx/shared/utils/test_environment.dart';
import '../../products/models/advertisement.dart';

/// Servicio para operaciones de administración de anuncios (CRUD completo)
/// Solo accesible para usuarios con rol admin
class AdvertisementAdminService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static bool get _isTestMode => TestEnvironment.isRunningTests;

  // URL base desde .env
  static String get _baseUrl {
    // Lógica simple: release = producción, debug = local
    final bool isProduction =
        kReleaseMode || const bool.fromEnvironment('dart.vm.product');

    return isProduction
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;
  }

  // Headers con token de autenticación (requerido para admin)
  static Future<Map<String, String>> _getHeaders() async {
    String? token;
    try {
      token = await _storage.read(key: 'token');
    } catch (e) {
      debugPrint('⚠️ Error al obtener token: $e');
      if (_isTestMode) {
        token = 'test-admin-token';
      } else {
        throw Exception('No autorizado: token no disponible');
      }
    }
    token ??= _isTestMode ? 'test-admin-token' : null;
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/advertisements - Listar todos los anuncios (admin)
  static Future<List<Advertisement>> getAllAdvertisements() async {
    if (_isTestMode) {
      return List.generate(3, (index) => Advertisement.fromJson(_mockAdJson(index + 1)));
    }
    try {
      debugPrint('📢 AdvertisementAdminService.getAllAdvertisements iniciado');

      final uri = Uri.parse('$_baseUrl/api/advertisements');
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> adsData = decoded['data'] ?? [];

        return adsData.map((json) => Advertisement.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('No autorizado: Solo administradores pueden acceder');
      } else {
        throw Exception('Error al obtener anuncios: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en getAllAdvertisements: $e');
      rethrow;
    }
  }

  /// GET /api/advertisements/{id} - Obtener detalle de un anuncio (admin)
  static Future<Advertisement> getAdvertisementById(int id) async {
    if (_isTestMode) {
      return Advertisement.fromJson(_mockAdJson(id));
    }
    try {
      debugPrint('📢 AdvertisementAdminService.getAdvertisementById - ID: $id');

      final uri = Uri.parse('$_baseUrl/api/advertisements/$id');
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return Advertisement.fromJson(decoded['data'] ?? decoded);
      } else if (response.statusCode == 404) {
        throw Exception('Anuncio no encontrado');
      } else if (response.statusCode == 403) {
        throw Exception('No autorizado: Solo administradores pueden acceder');
      } else {
        throw Exception('Error al obtener anuncio: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en getAdvertisementById: $e');
      rethrow;
    }
  }

  /// POST /api/advertisements - Crear nuevo anuncio (admin)
  static Future<Advertisement> createAdvertisement(
      Map<String, dynamic> data) async {
    if (_isTestMode) {
      final mock = Map<String, dynamic>.from(_mockAdJson(999));
      mock.addAll(data);
      mock['id'] = 999;
      return Advertisement.fromJson(mock);
    }
    try {
      debugPrint('📢 AdvertisementAdminService.createAdvertisement');

      final uri = Uri.parse('$_baseUrl/api/advertisements');
      final response = await http
          .post(
            uri,
            headers: await _getHeaders(),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return Advertisement.fromJson(decoded['data'] ?? decoded);
      } else if (response.statusCode == 403) {
        throw Exception(
            'No autorizado: Solo administradores pueden crear anuncios');
      } else if (response.statusCode == 422) {
        final decoded = json.decode(response.body);
        final errors = decoded['errors'] ?? {};
        throw Exception('Error de validación: ${errors.toString()}');
      } else {
        throw Exception('Error al crear anuncio: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en createAdvertisement: $e');
      rethrow;
    }
  }

  /// PUT /api/advertisements/{id} - Actualizar anuncio (admin)
  static Future<Advertisement> updateAdvertisement(
      int id, Map<String, dynamic> data) async {
    if (_isTestMode) {
      final mock = Map<String, dynamic>.from(_mockAdJson(id));
      mock.addAll(data);
      return Advertisement.fromJson(mock);
    }
    try {
      debugPrint('📢 AdvertisementAdminService.updateAdvertisement - ID: $id');

      final uri = Uri.parse('$_baseUrl/api/advertisements/$id');
      final response = await http
          .put(
            uri,
            headers: await _getHeaders(),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return Advertisement.fromJson(decoded['data'] ?? decoded);
      } else if (response.statusCode == 404) {
        throw Exception('Anuncio no encontrado');
      } else if (response.statusCode == 403) {
        throw Exception(
            'No autorizado: Solo administradores pueden actualizar anuncios');
      } else if (response.statusCode == 422) {
        final decoded = json.decode(response.body);
        final errors = decoded['errors'] ?? {};
        throw Exception('Error de validación: ${errors.toString()}');
      } else {
        throw Exception('Error al actualizar anuncio: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en updateAdvertisement: $e');
      rethrow;
    }
  }

  /// DELETE /api/advertisements/{id} - Eliminar anuncio (admin)
  static Future<void> deleteAdvertisement(int id) async {
    if (_isTestMode) {
      return;
    }
    try {
      debugPrint('📢 AdvertisementAdminService.deleteAdvertisement - ID: $id');

      final uri = Uri.parse('$_baseUrl/api/advertisements/$id');
      final response = await http
          .delete(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Anuncio eliminado exitosamente');
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Anuncio no encontrado');
      } else if (response.statusCode == 403) {
        throw Exception(
            'No autorizado: Solo administradores pueden eliminar anuncios');
      } else {
        throw Exception('Error al eliminar anuncio: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en deleteAdvertisement: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _mockAdJson(int id) {
    return {
      'id': id,
      'type': id.isEven ? 'external_ad' : 'sponsored_product',
      'title': 'Anuncio de prueba $id',
      'description': 'Descripción mock del anuncio $id',
      'image_url': 'https://example.com/mock_$id.png',
      'target_url': 'https://example.com',
      'is_active': true,
      'priority': 50,
      'clicks': 10 * id,
      'impressions': 100 * id,
      'product_id': id,
      'advertiser_name': 'CorralX Mock',
      'start_date': DateTime.now().toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    };
  }
}
