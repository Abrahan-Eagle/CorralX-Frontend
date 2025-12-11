import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:corralx/config/app_config.dart';
import 'package:corralx/shared/utils/test_environment.dart';

/// Servicio compartido para cargar ubicaciones (países, estados, ciudades, parroquias)
class LocationService {
  // Usa AppConfig que detecta automáticamente los 3 entornos (local/test/production)
  static String get _baseUrl => AppConfig.apiUrl;

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static bool get _isTestMode => TestEnvironment.isRunningTests;

  /// GET /api/countries - Obtener países
  static Future<List<Map<String, dynamic>>> getCountries() async {
    if (_isTestMode) {
      return _mockLocationList('country');
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/countries'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al cargar países: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ LocationService.getCountries error: $e');
      rethrow;
    }
  }

  /// GET /api/states?country_id={id} - Obtener estados por país
  static Future<List<Map<String, dynamic>>> getStates(int countryId) async {
    if (_isTestMode) {
      return _mockLocationList('state', parentId: countryId);
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/states?country_id=$countryId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al cargar estados: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ LocationService.getStates error: $e');
      rethrow;
    }
  }

  /// GET /api/cities?state_id={id} - Obtener ciudades por estado
  static Future<List<Map<String, dynamic>>> getCities(int stateId) async {
    if (_isTestMode) {
      return _mockLocationList('city', parentId: stateId);
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cities?state_id=$stateId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al cargar ciudades: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ LocationService.getCities error: $e');
      rethrow;
    }
  }

  /// GET /api/parishes?city_id={id} - Obtener parroquias por ciudad
  static Future<List<Map<String, dynamic>>> getParishes(int cityId) async {
    if (_isTestMode) {
      return _mockLocationList('parish', parentId: cityId);
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/parishes?city_id=$cityId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al cargar parroquias: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ LocationService.getParishes error: $e');
      rethrow;
    }
  }

  static List<Map<String, dynamic>> _mockLocationList(String type,
      {int? parentId}) {
    final parentKey = type == 'state'
        ? 'country_id'
        : type == 'city'
            ? 'state_id'
            : 'city_id';

    return List.generate(3, (index) {
      final id = (parentId ?? 0) * 10 + index + 1;
      return {
        'id': id,
        'name': 'Mock $type $id',
        if (type != 'country') parentKey: parentId ?? 1,
      };
    });
  }
}

