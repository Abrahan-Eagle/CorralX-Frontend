import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/advertisement.dart';

class AdvertisementService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // URL base desde .env con detección robusta del modo producción
  static String get _baseUrl {
    final bool isProduction = kReleaseMode ||
        const bool.fromEnvironment('dart.vm.product') ||
        dotenv.env['ENVIRONMENT'] == 'production';

    final String baseUrl = isProduction
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;

    return baseUrl;
  }

  // Headers comunes con token de autenticación
  static Future<Map<String, String>> _getHeaders() async {
    String? token;
    try {
      token = await _storage.read(key: 'token');
    } catch (e) {
      debugPrint('⚠️ FlutterSecureStorage no disponible en tests: $e');
      token = null;
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/advertisements/active - Obtener anuncios activos
  /// Este endpoint es público y no requiere autenticación
  static Future<List<Advertisement>> getActiveAdvertisements() async {
    try {
      debugPrint('📢 AdvertisementService.getActiveAdvertisements iniciado');

      final uri = Uri.parse('$_baseUrl/api/advertisements/active');

      debugPrint('📢 URL: $uri');

      final response = await http
          .get(
            uri,
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📢 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        debugPrint('📢 Response decoded: ${decoded.keys.toList()}');

        // El backend devuelve: { data: [...], count: ... }
        final List<dynamic> adsData = decoded['data'] ?? [];
        debugPrint('📢 Anuncios encontrados: ${adsData.length}');

        final List<Advertisement> advertisements = adsData
            .map((json) => Advertisement.fromJson(json))
            .toList();

        // Filtrar solo los que están activos actualmente (por fecha)
        final activeAds = advertisements
            .where((ad) => ad.isCurrentlyActive)
            .toList();

        debugPrint('📢 Anuncios activos después de filtrar por fechas: ${activeAds.length}');
        return activeAds;
      } else {
        debugPrint('❌ Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Error al obtener anuncios: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en getActiveAdvertisements: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// POST /api/advertisements/{id}/click - Registrar click en anuncio
  /// Este endpoint es público y no requiere autenticación
  static Future<void> registerClick(int advertisementId) async {
    try {
      debugPrint('📢 AdvertisementService.registerClick - ID: $advertisementId');

      final uri = Uri.parse('$_baseUrl/api/advertisements/$advertisementId/click');

      final response = await http
          .post(
            uri,
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('✅ Click registrado exitosamente');
      } else {
        debugPrint('⚠️ Error al registrar click: ${response.statusCode}');
        // No lanzar excepción, es no crítico
      }
    } catch (e) {
      debugPrint('⚠️ Error al registrar click (no crítico): $e');
      // No lanzar excepción, es no crítico
    }
  }
}
