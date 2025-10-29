import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

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

    print(
        '🔧 RanchService - Modo: ${isProduction ? "PRODUCCIÓN" : "DESARROLLO"}');
    print('🔧 RanchService - URL Base: $baseUrl');

    return baseUrl;
  }

  /// Headers comunes con token de autenticación
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    return {
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
    List<String>? certifications,
    String? businessLicenseUrl,
    String? contactHours,
    int? addressId,
    bool? isPrimary,
    String? deliveryPolicy,
    String? returnPolicy,
  }) async {
    try {
      print('🌐 RanchService.updateRanch iniciado - ranchId: $ranchId');

      final headers = await _getHeaders();
      // Para JSON explícitamente añadimos Content-Type
      final jsonHeaders = {
        ...headers,
        'Content-Type': 'application/json',
      };
      final uri = Uri.parse('$_baseUrl/api/ranches/$ranchId');

      final Map<String, dynamic> body = {};

      if (name != null) body['name'] = name;
      if (legalName != null) body['legal_name'] = legalName;
      if (taxId != null) body['tax_id'] = taxId;
      if (businessDescription != null)
        body['business_description'] = businessDescription;
      if (certifications != null) body['certifications'] = certifications;
      if (businessLicenseUrl != null)
        body['business_license_url'] = businessLicenseUrl;
      if (contactHours != null) body['contact_hours'] = contactHours;
      if (addressId != null) body['address_id'] = addressId;
      if (isPrimary != null) body['is_primary'] = isPrimary;
      if (deliveryPolicy != null) body['delivery_policy'] = deliveryPolicy;
      if (returnPolicy != null) body['return_policy'] = returnPolicy;

      print('🌐 URL: $uri');
      print('🌐 Body: $body');

      final response = await http.put(
        uri,
        headers: jsonHeaders,
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
    List<String>? certifications,
    String? businessLicenseUrl,
    String? contactHours,
    int? addressId,
    String? deliveryPolicy,
    String? returnPolicy,
  }) async {
    try {
      print('🌐 RanchService.createRanch iniciado');

      final headers = await _getHeaders();
      // Para JSON explícitamente añadimos Content-Type
      final jsonHeaders = {
        ...headers,
        'Content-Type': 'application/json',
      };
      final uri = Uri.parse('$_baseUrl/api/ranches');

      final Map<String, dynamic> body = {
        'name': name,
        if (legalName != null) 'legal_name': legalName,
        if (taxId != null) 'tax_id': taxId,
        if (businessDescription != null)
          'business_description': businessDescription,
        if (certifications != null) 'certifications': certifications,
        if (businessLicenseUrl != null)
          'business_license_url': businessLicenseUrl,
        if (contactHours != null) 'contact_hours': contactHours,
        if (addressId != null) 'address_id': addressId,
        if (deliveryPolicy != null) 'delivery_policy': deliveryPolicy,
        if (returnPolicy != null) 'return_policy': returnPolicy,
      };

      print('🌐 URL: $uri');
      print('🌐 Body: $body');

      final response = await http.post(
        uri,
        headers: jsonHeaders,
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

  /// POST /api/ranches/{ranch}/document - Subir documento (PDF) de la hacienda
  static Future<Map<String, dynamic>> uploadRanchDocument({
    required int ranchId,
    required String filePath,
    String? certificationType,
  }) async {
    try {
      print('📄 RanchService.uploadRanchDocument iniciado - ranchId: $ranchId');

      // Validación simple en cliente: solo PDF
      if (!filePath.toLowerCase().endsWith('.pdf')) {
        throw Exception('Solo se permiten archivos PDF');
      }

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/ranches/$ranchId/documents');

      final request = http.MultipartRequest('POST', uri);
      // Copiar headers excepto Content-Type (multipart lo maneja automáticamente)
      headers.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers[key] = value;
        }
      });

      final file = await http.MultipartFile.fromPath(
        'document',
        filePath,
        contentType: MediaType('application', 'pdf'),
      );

      request.files.add(file);

      // Agregar certification_type si se proporciona
      if (certificationType != null && certificationType.isNotEmpty) {
        request.fields['certification_type'] = certificationType;
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('📄 Upload status: ${response.statusCode}');
      print('📄 Upload body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'document': data['data'],
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
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para subir el documento');
      } else {
        throw Exception('Error al subir documento: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en uploadRanchDocument: $e');
      rethrow;
    }
  }

  /// DELETE /api/ranches/{ranch}/documents/{document} - Eliminar documento
  static Future<Map<String, dynamic>> deleteRanchDocument({
    required int ranchId,
    required int documentId,
  }) async {
    try {
      print(
          '🗑️ RanchService.deleteRanchDocument iniciado - ranchId: $ranchId, documentId: $documentId');

      final headers = await _getHeaders();
      final uri =
          Uri.parse('$_baseUrl/api/ranches/$ranchId/documents/$documentId');

      final response = await http.delete(uri, headers: headers);

      print('🗑️ Delete status: ${response.statusCode}');
      print('🗑️ Delete body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Documento eliminado exitosamente',
        };
      } else if (response.statusCode == 404) {
        throw Exception('Documento no encontrado');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para eliminar este documento');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else {
        throw Exception('Error al eliminar documento: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en deleteRanchDocument: $e');
      rethrow;
    }
  }
}
