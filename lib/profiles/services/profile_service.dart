import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:zonix/profiles/models/ranch.dart';

/// Servicio para manejar todas las operaciones relacionadas con perfiles
class ProfileService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// URL base desde .env con detección robusta del modo producción
  static String get _baseUrl {
    final bool isProduction = kReleaseMode ||
        const bool.fromEnvironment('dart.vm.product') ||
        dotenv.env['ENVIRONMENT'] == 'production';

    final String baseUrl = isProduction
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;

    print(
        '🔧 ProfileService - Modo: ${isProduction ? "PRODUCCIÓN" : "DESARROLLO"}');
    print('🔧 ProfileService - URL Base: $baseUrl');

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

  /// GET /api/profile - Obtener perfil propio (autenticado)
  static Future<Map<String, dynamic>> getMyProfile() async {
    try {
      print('🌐 ProfileService.getMyProfile iniciado');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/profile');

      print('🌐 URL: $uri');
      print('🌐 Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'profile': data,
        };
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else if (response.statusCode == 404) {
        throw Exception('Perfil no encontrado.');
      } else {
        throw Exception('Error al cargar perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getMyProfile: $e');
      rethrow;
    }
  }

  /// GET /api/profiles/{id} - Obtener perfil público de otro usuario
  static Future<Map<String, dynamic>> getPublicProfile(int userId) async {
    try {
      print('🌐 ProfileService.getPublicProfile iniciado - userId: $userId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/profiles/$userId');

      print('🌐 URL: $uri');

      final response = await http.get(uri, headers: headers);

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'profile': data,
        };
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado.');
      } else {
        throw Exception('Error al cargar perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getPublicProfile: $e');
      rethrow;
    }
  }

  /// PUT /api/profile - Actualizar perfil propio
  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? secondLastName,
    String? bio,
    DateTime? dateOfBirth,
    String? maritalStatus,
    String? sex,
    String? ciNumber,
    bool? acceptsCalls,
    bool? acceptsWhatsapp,
    bool? acceptsEmails,
    String? whatsappNumber,
  }) async {
    try {
      print('🌐 ProfileService.updateProfile iniciado');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/profile');

      // Construir el body solo con los campos que no son null
      final Map<String, dynamic> body = {};

      if (firstName != null) body['firstName'] = firstName;
      if (middleName != null) body['middleName'] = middleName;
      if (lastName != null) body['lastName'] = lastName;
      if (secondLastName != null) body['secondLastName'] = secondLastName;
      if (bio != null) body['bio'] = bio;
      if (dateOfBirth != null)
        body['date_of_birth'] = dateOfBirth.toIso8601String();
      if (maritalStatus != null) body['maritalStatus'] = maritalStatus;
      if (sex != null) body['sex'] = sex;
      if (ciNumber != null) body['ci_number'] = ciNumber;
      if (acceptsCalls != null) body['accepts_calls'] = acceptsCalls;
      if (acceptsWhatsapp != null) body['accepts_whatsapp'] = acceptsWhatsapp;
      if (acceptsEmails != null) body['accepts_emails'] = acceptsEmails;
      if (whatsappNumber != null) body['whatsapp_number'] = whatsappNumber;

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
          'message': 'Perfil actualizado exitosamente',
          'profile': data,
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
        throw Exception('Error al actualizar perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en updateProfile: $e');
      rethrow;
    }
  }

  /// PUT /api/profile (multipart) - Subir foto de perfil
  static Future<Map<String, dynamic>> uploadProfilePhoto(File photoFile) async {
    try {
      print('🌐 ProfileService.uploadProfilePhoto iniciado');

      final token = await _storage.read(key: 'token');
      final uri = Uri.parse('$_baseUrl/api/profile/photo');

      var request = http.MultipartRequest('POST', uri);

      // Agregar headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Agregar archivo
      final fileStream = http.ByteStream(photoFile.openRead());
      final fileLength = await photoFile.length();

      final multipartFile = http.MultipartFile(
        'photo_users',
        fileStream,
        fileLength,
        filename: photoFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      print('🌐 URL: $uri');
      print('🌐 Archivo: ${photoFile.path}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Foto actualizada exitosamente',
          'profile': data,
        };
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'errors': data['errors'] ?? {},
          'message': data['message'] ?? 'Error de validación',
        };
      } else {
        throw Exception('Error al subir foto: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en uploadProfilePhoto: $e');
      rethrow;
    }
  }

  /// GET /api/me/metrics - Obtener métricas del perfil
  static Future<Map<String, dynamic>> getProfileMetrics() async {
    try {
      print('🌐 ProfileService.getProfileMetrics iniciado');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/me/metrics');

      print('🌐 URL: $uri');

      final response = await http.get(uri, headers: headers);

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'metrics': data,
        };
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else {
        throw Exception('Error al cargar métricas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getProfileMetrics: $e');
      rethrow;
    }
  }

  /// GET /api/me/products - Obtener productos del perfil (mis publicaciones)
  static Future<Map<String, dynamic>> getProfileProducts({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      print('🌐 ProfileService.getProfileProducts iniciado');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/me/products').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      print('🌐 URL: $uri');

      final response = await http.get(uri, headers: headers);

      print('🌐 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getProfileProducts: $e');
      rethrow;
    }
  }

  /// GET /api/me/ranches - Obtener ranches/haciendas del perfil
  static Future<List<Ranch>> getProfileRanches() async {
    try {
      print('🌐 ProfileService.getProfileRanches iniciado');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/me/ranches');

      print('🌐 URL: $uri');

      final response = await http.get(uri, headers: headers);

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ranch.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else {
        throw Exception('Error al cargar haciendas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getProfileRanches: $e');
      rethrow;
    }
  }

  /// GET /api/profiles/{profileId}/ranches - Obtener ranches de un perfil específico
  static Future<List<Ranch>> getRanchesByProfile(int profileId) async {
    try {
      print(
          '🌐 ProfileService.getRanchesByProfile iniciado - profileId: $profileId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/api/profiles/$profileId/ranches');

      print('🌐 URL: $uri');

      final response = await http.get(uri, headers: headers);

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ranch.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return []; // No tiene ranches
      } else {
        throw Exception('Error al cargar haciendas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getRanchesByProfile: $e');
      rethrow;
    }
  }
}
