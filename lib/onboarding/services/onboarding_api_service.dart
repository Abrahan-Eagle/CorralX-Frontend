import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:corralx/config/app_config.dart';

class OnboardingApiService {
  // Usa AppConfig que detecta automáticamente los 3 entornos (local/test/production)
  String get baseUrl => AppConfig.apiBaseUrl;

  String? _authToken;

  // Configurar token de autenticación
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Headers comunes
  Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Headers para multipart (subida de archivos)
  Map<String, String> get _multipartHeaders {
    Map<String, String> headers = {
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Helper para llamadas HTTP con timeout
  Future<http.Response> _makeRequest(
      Future<http.Response> Function() request) async {
    return await request().timeout(const Duration(seconds: 30));
  }

  // Obtener países
  Future<List<Map<String, dynamic>>> getCountries() async {
    try {
      final response = await _makeRequest(() => http.get(
            Uri.parse('$baseUrl/countries'),
            headers: _headers,
          ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Respuesta de países: $data');

        // Verificar la estructura de la respuesta
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Formato de respuesta inesperado: $data');
        }
      } else {
        throw Exception('Error al cargar países: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estados por país
  Future<List<Map<String, dynamic>>> getStates(int countryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/states?country_id=$countryId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Respuesta de estados: $data');

        // Verificar la estructura de la respuesta
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(
              'Formato de respuesta inesperado para estados: $data');
        }
      } else {
        throw Exception('Error al cargar estados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener ciudades por estado
  Future<List<Map<String, dynamic>>> getCities(int stateId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cities?state_id=$stateId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Respuesta de ciudades: $data');

        // Verificar la estructura de la respuesta
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(
              'Formato de respuesta inesperado para ciudades: $data');
        }
      } else {
        throw Exception('Error al cargar ciudades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener parroquias por ciudad
  Future<List<Map<String, dynamic>>> getParroquias(int cityId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parishes?city_id=$cityId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Respuesta de parroquias: $data');

        // Verificar la estructura de la respuesta
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(
              'Formato de respuesta inesperado para parroquias: $data');
        }
      } else {
        throw Exception('Error al cargar parroquias: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: $e');
    } on SocketException catch (e) {
      throw Exception('Error de conexión: $e');
    } on TimeoutException catch (_) {
      throw Exception('Tiempo de espera agotado al cargar parroquias');
    } catch (e) {
      throw Exception('Error al cargar parroquias: $e');
    }
  }

  // Obtener códigos de operadora
  Future<List<Map<String, dynamic>>> getOperatorCodes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/phones/operator-codes'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Respuesta de códigos de operadora: $data');

        // Verificar la estructura de la respuesta
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Formato de respuesta inesperado: $data');
        }
      } else {
        throw Exception(
            'Error al cargar códigos de operadora: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear perfil
  Future<Map<String, dynamic>> createProfile({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String ciNumber,
    File? photoUsers,
  }) async {
    try {
      // Obtener el user_id del token almacenado
      final userId = await _getUserIdFromToken();

      if (photoUsers != null) {
        // Crear request multipart para subir imagen
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/profiles'),
        );

        request.headers.addAll(_multipartHeaders);
        request.fields['user_id'] = userId.toString();
        request.fields['firstName'] = firstName;
        request.fields['lastName'] = lastName;
        request.fields['date_of_birth'] = dateOfBirth;
        request.fields['ci_number'] = ciNumber;

        // Agregar archivo de imagen
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo_users',
            photoUsers.path,
          ),
        );

        var response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 201 || response.statusCode == 200) {
          return json.decode(responseBody);
        } else {
          final errorData = json.decode(responseBody);
          debugPrint('❌ FRONTEND: Error al crear perfil (multipart): $errorData');
          
          // Mostrar detalles del error de validación
          String errorMessage = 'Error al crear perfil: ${response.statusCode}';
          
          // Priorizar mensajes específicos de validación (ci_number, etc.)
          if (errorData['error'] != null && errorData['error'] is Map) {
            final errors = errorData['error'] as Map;
            
            // Buscar mensaje específico de ci_number si existe
            if (errors.containsKey('ci_number') && errors['ci_number'] is List) {
              final ciErrors = errors['ci_number'] as List;
              if (ciErrors.isNotEmpty) {
                errorMessage = ciErrors.first.toString();
              }
            } else {
              // Si no hay ci_number, formatear todos los errores
              final errorListStr = errors.entries
                  .map((e) => '${e.key}: ${(e.value is List ? (e.value as List).join(', ') : e.value.toString())}')
                  .join('; ');
              errorMessage = 'Error de validación: $errorListStr';
            }
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
          
          throw Exception(errorMessage);
        }
      } else {
        // Crear perfil sin imagen
        final response = await http.post(
          Uri.parse('$baseUrl/profiles'),
          headers: _headers,
          body: json.encode({
            'user_id': userId,
            'firstName': firstName,
            'lastName': lastName,
            'date_of_birth': dateOfBirth,
            'ci_number': ciNumber,
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          final errorData = json.decode(response.body);
          debugPrint('❌ FRONTEND: Error al crear perfil: $errorData');
          
          // Mostrar detalles del error de validación
          String errorMessage = 'Error al crear perfil: ${response.statusCode}';
          
          // Priorizar mensajes específicos de validación (ci_number, etc.)
          if (errorData['error'] != null && errorData['error'] is Map) {
            final errors = errorData['error'] as Map;
            
            // Buscar mensaje específico de ci_number si existe
            if (errors.containsKey('ci_number') && errors['ci_number'] is List) {
              final ciErrors = errors['ci_number'] as List;
              if (ciErrors.isNotEmpty) {
                errorMessage = ciErrors.first.toString();
              }
            } else {
              // Si no hay ci_number, formatear todos los errores
              final errorListStr = errors.entries
                  .map((e) => '${e.key}: ${(e.value is List ? (e.value as List).join(', ') : e.value.toString())}')
                  .join('; ');
              errorMessage = 'Error de validación: $errorListStr';
            }
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
          
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      throw Exception('Error al crear perfil: $e');
    }
  }

  // Obtener user_id del token almacenado
  Future<int> _getUserIdFromToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'] ?? 0;
      } else {
        throw Exception(
            'Error al obtener información del usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener user_id: $e');
    }
  }

  // Crear teléfono
  Future<Map<String, dynamic>> createPhone({
    required String number,
    required int operatorCodeId,
    required int userId,
  }) async {
    try {
      final requestBody = {
        'user_id': userId,
        'number': number,
        'operator_code_id': operatorCodeId,
        'is_primary': true,
      };
      
      debugPrint('📞 FRONTEND: Enviando petición para crear teléfono...');
      debugPrint('📞 FRONTEND: Datos enviados: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/phones'),
        headers: _headers,
        body: json.encode(requestBody),
      );

      debugPrint('📞 FRONTEND: Respuesta del servidor: ${response.statusCode}');
      debugPrint('📞 FRONTEND: Body de respuesta: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ FRONTEND: Teléfono creado exitosamente.');
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ FRONTEND: Error al crear teléfono: $errorData');
        
        // Mostrar detalles del error de validación
        String errorMessage = 'Error al crear teléfono: ${response.statusCode}';
        if (errorData['error'] != null) {
          if (errorData['error'] is Map) {
            final errors = errorData['error'] as Map;
            final errorListStr = errors.entries
                .map((e) => '${e.key}: ${(e.value is List ? (e.value as List).join(', ') : e.value.toString())}')
                .join('; ');
            errorMessage = 'Error de validación: $errorListStr';
          } else {
            errorMessage = errorData['error'].toString();
          }
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ FRONTEND: Excepción al crear teléfono: $e');
      throw Exception('Error al crear teléfono: $e');
    }
  }

  // Crear dirección
  Future<Map<String, dynamic>> createAddress({
    required int profileId, // ✅ Ahora requiere profile_id directamente
    required String addresses,
    required int cityId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addresses'),
        headers: _headers,
        body: json.encode({
          'profile_id': profileId, // ✅ Usar el profile_id real
          'adressses': addresses, // Nota: manteniendo el typo del backend
          'city_id': cityId,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        // Mostrar detalles del error de validación
        String errorMessage =
            'Error al crear dirección: ${response.statusCode}';
        if (errorData['error'] != null) {
          if (errorData['error'] is Map) {
            final errors = errorData['error'] as Map;
            final errorListStr = errors.entries
                .map((e) => '${e.key}: ${(e.value is List ? (e.value as List).join(', ') : e.value.toString())}')
                .join('; ');
            errorMessage = 'Error de validación: $errorListStr';
          } else {
            errorMessage = errorData['error'].toString();
          }
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error al crear dirección: $e');
    }
  }

  // Crear hacienda
  Future<Map<String, dynamic>> createRanch({
    required String name,
    String? legalName,
    String? taxId,
    String? businessDescription,
    String? contactHours,
    int? addressId,
    required int profileId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ranches'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'profile_id': profileId,
          if (legalName != null) 'legal_name': legalName,
          if (taxId != null) 'tax_id': taxId,
          if (businessDescription != null)
            'business_description': businessDescription,
          if (contactHours != null) 'contact_hours': contactHours,
          if (addressId != null) 'address_id': addressId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ FRONTEND: Error al crear hacienda: $errorData');
        
        // Mostrar detalles del error de validación
        String errorMessage = 'Error al crear hacienda: ${response.statusCode}';
        
        // Priorizar mensajes específicos de validación (tax_id, etc.)
        if (errorData['error'] != null && errorData['error'] is Map) {
          final errors = errorData['error'] as Map;
          
          // Buscar mensaje específico de tax_id si existe
          if (errors.containsKey('tax_id') && errors['tax_id'] is List) {
            final taxErrors = errors['tax_id'] as List;
            if (taxErrors.isNotEmpty) {
              errorMessage = taxErrors.first.toString();
            }
          } else {
            // Si no hay tax_id, formatear todos los errores
            final errorListStr = errors.entries
                .map((e) => '${e.key}: ${(e.value is List ? (e.value as List).join(', ') : e.value.toString())}')
                .join('; ');
            errorMessage = 'Error de validación: $errorListStr';
          }
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error al crear hacienda: $e');
    }
  }

  // Obtener usuario actual
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {};
      } else {
        throw Exception(
            'Error al obtener usuario actual: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener usuario actual: $e');
    }
  }

  // Obtener perfil del usuario autenticado
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        throw Exception('Formato inesperado al obtener el perfil: $data');
      } else if (response.statusCode == 404) {
        // No hay perfil todavía
        return null;
      } else {
        throw Exception(
            'Error al obtener perfil: ${response.statusCode} (${response.body})');
      }
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  // Completar onboarding
  Future<Map<String, dynamic>> completeOnboarding(int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/onboarding/$userId'),
        headers: _headers,
        body: json.encode({
          'completed_onboarding': true, // ✅ CORREGIDO: debe ser 'completed_onboarding' no 'completed'
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ??
            'Error al completar onboarding: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al completar onboarding: $e');
    }
  }
}
