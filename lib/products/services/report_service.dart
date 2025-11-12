import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:corralx/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ReportService - Servicio para reportar contenido
class ReportService {
  static const storage = FlutterSecureStorage();

  /// POST /api/reports
  /// Reportar un producto, perfil, ranch, etc.
  static Future<bool> reportContent({
    required String reportableType, // 'App\\Models\\Product', etc.
    required int reportableId,
    required String reportType, // 'spam', 'inappropriate', etc.
    String? description,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      final baseUrl = AppConfig.apiUrl;

      if (token == null || token.isEmpty) {
        throw Exception('No hay token de autenticación');
      }

      final url = '$baseUrl/api/reports';
      
      final body = {
        'reportable_type': reportableType,
        'reportable_id': reportableId,
        'report_type': reportType,
        if (description != null) 'description': description,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Error al reportar: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en reportContent: $e');
      rethrow;
    }
  }

  /// Reportar un producto
  static Future<bool> reportProduct({
    required int productId,
    required String reportType,
    String? description,
  }) async {
    return reportContent(
      reportableType: 'App\\Models\\Product',
      reportableId: productId,
      reportType: reportType,
      description: description,
    );
  }
}
