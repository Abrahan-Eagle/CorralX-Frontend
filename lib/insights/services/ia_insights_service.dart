import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:zonix/insights/models/ia_insights_payload.dart';

/// Servicio encargado de consultar el backend (o proveer datos simulados)
/// para el módulo de IA Insights.
class IAInsightsService {
  IAInsightsService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String get _baseUrl {
    final bool isProduction = kReleaseMode ||
        const bool.fromEnvironment('dart.vm.product') ||
        dotenv.env['ENVIRONMENT'] == 'production';

    final String url = isProduction
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;

    debugPrint(
        '🤖 IAInsightsService - URL base (${isProduction ? "PROD" : "DEV"}): $url');
    return url;
  }

  static Future<Map<String, String>> _headers() async {
    String? token;
    try {
      token = await _storage.read(key: 'token');
    } catch (e) {
      debugPrint('⚠️ FlutterSecureStorage no disponible: $e');
      token = null;
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene el dashboard completo de IA Insights para un rol específico.
  ///
  static Future<IAInsightsPayload> fetchDashboard({
    required String role,
    String timeRange = '7d',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ia-insights/dashboard').replace(
      queryParameters: {
        'role': role,
        'time_range': timeRange,
      },
    );

    debugPrint('🤖 IAInsightsService.fetchDashboard -> $uri');

    try {
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded =
            json.decode(response.body) as Map<String, dynamic>;
        return IAInsightsPayload.fromJson(decoded);
      }

      throw Exception(
          'Error ${response.statusCode} al cargar IA Insights: ${response.body}');
    } catch (e) {
      debugPrint('❌ IAInsightsService.fetchDashboard error: $e');
      rethrow;
    }
  }

  /// Marca una recomendación como completada en el backend.
  ///
  /// Si la API aún no existe, lanza una excepción para que el provider
  /// pueda revertir la acción localmente.
  static Future<void> updateRecommendationStatus({
    required String recommendationId,
    required bool isCompleted,
  }) async {
    final uri = Uri.parse(
        '$_baseUrl/api/ia-insights/recommendations/$recommendationId/status');

    try {
      final response = await http
          .post(
            uri,
            headers: await _headers(),
            body: json.encode({'is_completed': isCompleted}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      throw Exception(
          'No se pudo actualizar la recomendación (status: ${response.statusCode})');
    } catch (e) {
      debugPrint('❌ Error al actualizar recomendación IA: $e');
      throw Exception('Error al sincronizar recomendación: $e');
    }
  }

}

