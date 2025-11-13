import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../../profiles/models/ranch.dart';

class RanchMarketplaceService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String get _baseUrl {
    // Lógica simple: release = producción, debug = local
    final bool isProduction = kReleaseMode ||
        const bool.fromEnvironment('dart.vm.product');
    return isProduction
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtener todos los ranchos públicos (con filtros opcionales)
  Future<List<Ranch>> getAllRanches({Map<String, dynamic>? filters}) async {
    try {
      debugPrint('🌐 RanchMarketplaceService.getAllRanches iniciado');

      // Construir URL con query parameters
      String url = '$_baseUrl/api/ranches';
      
      if (filters != null && filters.isNotEmpty) {
        final queryParams = <String>[];
        
        // Búsqueda por texto
        if (filters['search'] != null && filters['search'].toString().isNotEmpty) {
          queryParams.add('search=${Uri.encodeComponent(filters['search'])}');
        }
        
        // Filtro por ubicación (state_id, city_id)
        if (filters['state_id'] != null) {
          queryParams.add('state_id=${filters['state_id']}');
        }
        
        if (filters['city_id'] != null) {
          queryParams.add('city_id=${filters['city_id']}');
        }
        
        // Filtro por certificaciones
        if (filters['certifications'] != null && filters['certifications'] is List) {
          for (var cert in filters['certifications']) {
            queryParams.add('certifications[]=${Uri.encodeComponent(cert)}');
          }
        }
        
        // Filtro por acepta visitas
        if (filters['accepts_visits'] != null) {
          queryParams.add('accepts_visits=${filters['accepts_visits']}');
        }
        
        if (queryParams.isNotEmpty) {
          url += '?${queryParams.join('&')}';
        }
      }

      debugPrint('📡 Fetching: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // El backend devuelve un objeto paginado con { data: [], ...meta }
        final List<dynamic> data = responseData is Map && responseData.containsKey('data')
            ? responseData['data']
            : responseData;
        
        debugPrint('✅ ${data.length} ranchos recibidos');
        
        return data.map((json) => Ranch.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al cargar ranchos');
      }
    } catch (e) {
      debugPrint('❌ Error en getAllRanches: $e');
      rethrow;
    }
  }

  /// Obtener detalle de un rancho específico
  Future<Ranch> getRanchById(int id) async {
    try {
      debugPrint('🌐 RanchMarketplaceService.getRanchById iniciado: ID $id');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/ranches/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Ranch.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al cargar rancho');
      }
    } catch (e) {
      debugPrint('❌ Error en getRanchById: $e');
      rethrow;
    }
  }

  // TODO: Implementar cuando existan endpoints en el backend
  // Future<void> toggleFavorite(int ranchId) async { ... }
  // Future<List<Ranch>> getFavoriteRanches() async { ... }
}

