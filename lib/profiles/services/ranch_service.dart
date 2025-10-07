import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:zonix/profiles/models/ranch.dart';

/// Servicio para manejar operaciones CRUD de Ranches/Haciendas
class RanchService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String get _baseUrl {
    final bool isProduction = kReleaseMode ||
        const bool.fromEnvironment('dart.vm.product') ||
        dotenv.env['ENVIRONMENT'] == 'production';
    
    final String baseUrl = isProduction
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;
    
    print('🔧 RanchService - Modo: ${isProduction ? "PRODUCCIÓN" : "DESARROLLO"}');
    print('🔧 RanchService - URL Base: $baseUrl');
    
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

  /// PUT /api/ranches/{id} - Actualizar hacienda
  static Future<Map<String, dynamic>> updateRanch({
    required int ranchId,
    String? name,
    String? legalName,
    String? taxId,
    String? businessDescription,
    String? contactHours,
    int? addressId,
    bool? isPrimary,
    String? deliveryPolicy,
    String? returnPolicy,
  }) async {
    try {
      print('🌐 RanchService.updateRanch iniciado - ranchId: $ranchId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/ranches/$ranchId');

      final Map<String, dynamic> body = {};

      if (name != null) body['name'] = name;
      if (legalName != null) body['legal_name'] = legalName;
      if (taxId != null) body['tax_id'] = taxId;
      if (businessDescription != null) body['business_description'] = businessDescription;
      if (contactHours != null) body['contact_hours'] = contactHours;
      if (addressId != null) body['address_id'] = addressId;
      if (isPrimary != null) body['is_primary'] = isPrimary;
      if (deliveryPolicy != null) body['delivery_policy'] = deliveryPolicy;
      if (returnPolicy != null) body['return_policy'] = returnPolicy;

      print('🌐 URL: $uri');
      print('🌐 Body: $body');

      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'ranch': data['data'],
        };
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'errors': data['errors'] ?? {},
          'message': data['message'] ?? 'Error de validación',
        };
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para editar esta hacienda');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else {
        throw Exception('Error al actualizar hacienda: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en updateRanch: $e');
      rethrow;
    }
  }

  /// DELETE /api/ranches/{id} - Eliminar hacienda
  static Future<Map<String, dynamic>> deleteRanch(int ranchId) async {
    try {
      print('🌐 RanchService.deleteRanch iniciado - ranchId: $ranchId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/ranches/$ranchId');

      print('🌐 URL: $uri');

      final response = await http.delete(uri, headers: headers);

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Hacienda eliminada exitosamente',
        };
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'No se puede eliminar esta hacienda',
        };
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para eliminar esta hacienda');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else {
        throw Exception('Error al eliminar hacienda: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en deleteRanch: $e');
      rethrow;
    }
  }

  /// POST /api/ranches - Crear hacienda (ya existe, pero lo incluyo para completitud)
  static Future<Map<String, dynamic>> createRanch({
    required String name,
    String? legalName,
    String? taxId,
    String? businessDescription,
    String? contactHours,
    int? addressId,
  }) async {
    try {
      print('🌐 RanchService.createRanch iniciado');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/ranches');

      final Map<String, dynamic> body = {
        'name': name,
        if (legalName != null) 'legal_name': legalName,
        if (taxId != null) 'tax_id': taxId,
        if (businessDescription != null) 'business_description': businessDescription,
        if (contactHours != null) 'contact_hours': contactHours,
        if (addressId != null) 'address_id': addressId,
      };

      print('🌐 URL: $uri');
      print('🌐 Body: $body');

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'ranch': data['data'],
        };
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'errors': data['errors'] ?? {},
          'message': data['message'] ?? 'Error de validación',
        };
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else {
        throw Exception('Error al crear hacienda: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en createRanch: $e');
      rethrow;
    }
  }
}

