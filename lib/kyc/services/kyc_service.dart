import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

/// Servicio para comunicarse con los endpoints de KYC del backend.
class KycService {
  KycService()
      : _baseUrl = const bool.fromEnvironment('dart.vm.product')
            ? dotenv.env['API_URL_PROD']!
            : dotenv.env['API_URL_LOCAL']!;

  final String _baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  Future<Map<String, dynamic>> _authorizedGet(String path) async {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      throw Exception('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$_baseUrl$path');
    _logger.i('KYC GET $uri');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    _logger.e('Error KYC GET $uri: ${response.statusCode} - ${response.body}');
    throw Exception('Error KYC (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _authorizedPostJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      throw Exception('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$_baseUrl$path');
    _logger.i('KYC POST $uri body=$body');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    _logger.e('Error KYC POST $uri: ${response.statusCode} - ${response.body}');
    throw Exception('Error KYC (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _authorizedMultipart(
    String path, {
    required Map<String, String> fields,
    required Map<String, XFile> files,
  }) async {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      throw Exception('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$_baseUrl$path');
    _logger.i('KYC MULTIPART $uri fields=$fields files=${files.keys}');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields.addAll(fields);

    for (final entry in files.entries) {
      final file = await http.MultipartFile.fromPath(
        entry.key,
        entry.value.path,
        filename: entry.value.name,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(file);
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    _logger.e(
      'Error KYC MULTIPART $uri: ${response.statusCode} - ${response.body}',
    );
    throw Exception('Error KYC (${response.statusCode})');
  }

  /// GET /api/kyc/status
  Future<Map<String, dynamic>> getStatus() async {
    return _authorizedGet('/api/kyc/status');
  }

  /// POST /api/kyc/start
  Future<Map<String, dynamic>> startKyc({
    String? documentType,
    String? countryCode,
  }) async {
    return _authorizedPostJson(
      '/api/kyc/start',
      body: {
        if (documentType != null) 'document_type': documentType,
        if (countryCode != null) 'country_code': countryCode,
      },
    );
  }

  /// POST /api/kyc/upload-document
  Future<Map<String, dynamic>> uploadDocument({
    required XFile front,
    required XFile rif,
    required String documentType,
    String? documentNumber,
    String? countryCode,
  }) async {
    final fields = <String, String>{
      'document_type': documentType,
      if (documentNumber != null) 'document_number': documentNumber,
      if (countryCode != null) 'country_code': countryCode,
    };

    final files = <String, XFile>{
      'front': front,
      'rif': rif,
    };

    return _authorizedMultipart('/api/kyc/upload-document', fields: fields, files: files);
  }

  /// POST /api/kyc/upload-selfie
  Future<Map<String, dynamic>> uploadSelfie({
    required XFile selfie,
  }) async {
    return _authorizedMultipart(
      '/api/kyc/upload-selfie',
      fields: const {},
      files: {'selfie': selfie},
    );
  }

  /// POST /api/kyc/upload-selfie-with-doc
  Future<Map<String, dynamic>> uploadSelfieWithDoc({
    required XFile selfieWithDoc,
  }) async {
    return _authorizedMultipart(
      '/api/kyc/upload-selfie-with-doc',
      fields: const {},
      files: {'selfie_with_doc': selfieWithDoc},
    );
  }
}


