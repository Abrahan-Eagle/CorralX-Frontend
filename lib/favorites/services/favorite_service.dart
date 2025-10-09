import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zonix/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// FavoriteService - Servicio para gestión de favoritos
/// 
/// Maneja todas las operaciones relacionadas con favoritos:
/// - Obtener lista de favoritos del usuario
/// - Toggle favorito (agregar/remover)
/// - Verificar si un producto es favorito
/// - Remover de favoritos
class FavoriteService {
  static const storage = FlutterSecureStorage();

  /// GET /api/me/favorites
  /// Obtener lista de favoritos del usuario autenticado
  static Future<Map<String, dynamic>> getMyFavorites({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final baseUrl = AppConfig.apiUrl;

      print('🌐 FavoriteService.getMyFavorites iniciado');
      print('🔧 URL Base: $baseUrl');
      print('📄 Página: $page, Por página: $perPage');

      final url = '$baseUrl/api/me/favorites?page=$page&per_page=$perPage';
      print('🌐 URL completa: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🌐 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Favoritos obtenidos: ${data['data']?.length ?? 0}');
        return data;
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        throw Exception('Error al cargar favoritos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Excepción en getMyFavorites: $e');
      rethrow;
    }
  }

  /// POST /api/products/{id}/favorite
  /// Toggle favorito (agregar/remover)
  static Future<bool> toggleFavorite(int productId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final baseUrl = AppConfig.apiUrl;

      print('🔄 FavoriteService.toggleFavorite - ProductID: $productId');

      final url = '$baseUrl/api/products/$productId/favorite';
      print('🌐 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isFavorite = data['is_favorite'] ?? false;
        print('✅ Toggle exitoso - Estado: ${isFavorite ? "FAVORITO" : "NO FAVORITO"}');
        return isFavorite;
      } else {
        print('❌ Error en toggle: ${response.statusCode}');
        throw Exception('Error al toggle favorito: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Excepción en toggleFavorite: $e');
      rethrow;
    }
  }

  /// GET /api/products/{id}/is-favorite
  /// Verificar si un producto es favorito
  static Future<bool> isFavorite(int productId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final baseUrl = AppConfig.apiUrl;

      print('🔍 FavoriteService.isFavorite - ProductID: $productId');

      final url = '$baseUrl/api/products/$productId/is-favorite';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isFav = data['is_favorite'] ?? false;
        print('✅ isFavorite resultado: $isFav');
        return isFav;
      } else {
        print('⚠️ Error al verificar favorito, asumiendo false');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en isFavorite: $e');
      return false; // No throw, retornar false si falla
    }
  }

  /// DELETE /api/products/{id}/favorite
  /// Remover producto de favoritos
  static Future<bool> removeFavorite(int productId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final baseUrl = AppConfig.apiUrl;

      print('🗑️ FavoriteService.removeFavorite - ProductID: $productId');

      final url = '$baseUrl/api/products/$productId/favorite';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Favorito removido exitosamente');
        return data['success'] ?? true;
      } else {
        print('❌ Error al remover favorito: ${response.statusCode}');
        throw Exception('Error al remover favorito');
      }
    } catch (e) {
      print('❌ Excepción en removeFavorite: $e');
      rethrow;
    }
  }

  /// GET /api/products/{id}/favorites-count
  /// Obtener número de veces que un producto fue marcado como favorito
  static Future<int> getFavoritesCount(int productId) async {
    try {
      final baseUrl = AppConfig.apiUrl;
      
      final url = '$baseUrl/api/products/$productId/favorites-count';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['favorites_count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('❌ Error al obtener count de favoritos: $e');
      return 0;
    }
  }
}

