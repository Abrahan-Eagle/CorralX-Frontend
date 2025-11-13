import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar operaciones CRUD de Address
class AddressService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String get _baseUrl {
    // Lógica simple: release = producción, debug = local
    final bool isProduction = kReleaseMode ||
        const bool.fromEnvironment('dart.vm.product');

    final String baseUrl = isProduction
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;

    return baseUrl;
  }

  /// Headers comunes con token de autenticación
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// POST /api/addresses - Crear dirección
  static Future<Map<String, dynamic>> createAddress({
    required int profileId,
    required int cityId,
    required String addressDetail,
    double? latitude,
    double? longitude,
    String level = 'users', // 'users' o 'ranches'
  }) async {
    try {
      debugPrint('🌐 AddressService.createAddress iniciado');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/addresses');

      final Map<String, dynamic> body = {
        'profile_id': profileId,
        'city_id': cityId,
        'adressses': addressDetail, // Backend usa 'adressses' (typo)
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'level': level, // 'users' o 'ranches'
      };

      debugPrint('🌐 URL: $uri');
      debugPrint('🌐 Body: $body');

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      debugPrint('🌐 Status code: ${response.statusCode}');
      debugPrint('🌐 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'address': data['address'] ?? data,
        };
      } else if (response.statusCode == 409) {
        // Ya existe una dirección
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Ya existe una dirección',
        };
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'errors': data['error'] ?? {},
          'message': 'Error de validación',
        };
      } else {
        throw Exception('Error al crear dirección: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en createAddress: $e');
      rethrow;
    }
  }

  /// PUT /api/addresses/{id} - Actualizar dirección
  static Future<Map<String, dynamic>> updateAddress({
    required int addressId,
    int? cityId,
    String? addressDetail,
    double? latitude,
    double? longitude,
    String? level, // 'users' o 'ranches'
  }) async {
    try {
      debugPrint(
          '🌐 AddressService.updateAddress iniciado - addressId: $addressId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/addresses/$addressId');

      final Map<String, dynamic> body = {};

      if (cityId != null) body['city_id'] = cityId;
      if (addressDetail != null) body['adressses'] = addressDetail;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (level != null) body['level'] = level;

      debugPrint('🌐 URL: $uri');
      debugPrint('🌐 Body: $body');

      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      debugPrint('🌐 Status code: ${response.statusCode}');
      debugPrint('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'address': data['address'] ?? data,
        };
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'errors': data['error'] ?? {},
          'message': 'Error de validación',
        };
      } else {
        throw Exception(
            'Error al actualizar dirección: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en updateAddress: $e');
      rethrow;
    }
  }
}

