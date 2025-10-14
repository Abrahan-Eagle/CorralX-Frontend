import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Servicio compartido para cargar ubicaciones (países, estados, ciudades, parroquias)
class LocationService {
  static String get _baseUrl {
    final bool isProduction = kReleaseMode ||
        const bool.fromEnvironment('dart.vm.product') ||
        dotenv.env['ENVIRONMENT'] == 'production';

    final String baseUrl = isProduction
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;

    return baseUrl;
  }

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// GET /api/countries - Obtener países
  static Future<List<Map<String, dynamic>>> getCountries() async {
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
}

