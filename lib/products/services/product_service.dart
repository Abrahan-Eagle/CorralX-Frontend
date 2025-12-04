import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:corralx/config/app_config.dart';
import 'package:corralx/shared/utils/test_environment.dart';

class ProductService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static bool get _isTestMode => TestEnvironment.isRunningTests;

  // URL base desde AppConfig - Lógica simple: release = producción, debug = local
  static String get _baseUrl {
    final String baseUrl = AppConfig.isProduction
        ? AppConfig.apiUrlProd
        : AppConfig.apiUrlLocal;

    print(
        '🔧 ProductService - Modo: ${AppConfig.isProduction ? "PRODUCCIÓN" : "DESARROLLO"}');
    print('🔧 ProductService - URL Base: $baseUrl');

    return baseUrl;
  }

  // Headers comunes con token de autenticación
  static Future<Map<String, String>> _getHeaders() async {
    String? token;
    try {
      token = await _storage.read(
          key: 'token'); // ✅ CORREGIDO: usar 'token' no 'auth_token'
    } catch (e) {
      // En entorno de test, flutter_secure_storage no tiene implementación
      // Evitamos que rompa y seguimos sin Authorization
      debugPrint('⚠️ FlutterSecureStorage no disponible en tests: $e');
      if (_isTestMode) {
        token = 'test-token';
      }
    }
    token ??= _isTestMode ? 'test-token' : null;
    print(
        '🔑 Token recuperado: ${token != null ? "✅ SI (${token.substring(0, 20)}...)" : "❌ NO"}');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET /api/products - Listar productos con filtros
  static Future<Map<String, dynamic>> getProducts({
    Map<String, dynamic>? filters,
    int page = 1,
    int perPage = 20,
  }) async {
    if (_isTestMode) {
      return _buildMockProductsResponse(page: page, perPage: perPage);
    }
    try {
      print('🌐 ProductService.getProducts iniciado');
      print('🌐 URL base: $_baseUrl');

      // Convertir filtros a strings para la URL
      Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }

      final uri = Uri.parse('$_baseUrl/api/products').replace(
        queryParameters: queryParams,
      );

      print('🌐 URL completa: $uri');
      print('🌐 Headers: ${await _getHeaders()}');

      final response = await http
          .get(
            uri,
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      print('🌐 Status code: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('🌐 Response decoded: $decoded');
        return decoded;
      } else {
        print('❌ Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // GET /api/exchange-rate - Obtener tasa de cambio USD a Bs del BCV automáticamente
  // Retorna null si no se puede obtener (NO HAY VALORES HARDCODEADOS)
  static Future<double?> getExchangeRate() async {
    if (_isTestMode) {
      // Solo en tests usar un valor mock
      return 247.40;
    }
    try {
      // Intentar obtener el valor real del backend (que obtiene automáticamente del BCV)
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/exchange-rate'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verificar si hay error en la respuesta
        if (data.containsKey('error')) {
          if (kDebugMode) {
            print('⚠️ Backend reporta error: ${data['error']}');
          }
          return null; // No hay tasa disponible
        }
        
        final rate = (data['rate'] as num).toDouble();
        
        // Validar que el valor sea razonable (entre 1 y 1,000,000)
        if (rate > 0 && rate < 1000000) {
          return rate;
        } else {
          // Valor inválido del backend
          if (kDebugMode) {
            print('⚠️ Tasa BCV inválida recibida del backend: $rate');
          }
          return null; // No usar valores inválidos
        }
      } else if (response.statusCode == 503) {
        // Service Unavailable - El backend no pudo obtener la tasa del BCV
        if (kDebugMode) {
          print('⚠️ Backend no pudo obtener tasa BCV (503)');
        }
        return null; // No hay tasa disponible
      } else {
        // Error del servidor
        if (kDebugMode) {
          print('⚠️ Error del servidor al obtener tasa BCV: ${response.statusCode}');
        }
        return null; // No usar valores hardcodeados
      }
    } catch (e) {
      // Error de conexión o timeout
      if (kDebugMode) {
        print('⚠️ Error de conexión al obtener tasa BCV: $e');
      }
      // NO RETORNAR VALOR HARDCODEADO - Retornar null para indicar que no hay tasa disponible
      return null;
    }
  }

  // GET /api/products/{id} - Obtener detalle de un producto
  static Future<Map<String, dynamic>> getProductDetail(int productId) async {
    if (_isTestMode) {
      return _buildMockProduct(productId);
    }
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/products/$productId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Producto no encontrado');
      } else {
        throw Exception('Error al obtener producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // POST /api/products - Crear nuevo producto
  static Future<Map<String, dynamic>> createProduct({
    required int ranchId,
    int? stateId, // ✅ NUEVO: ID del estado del ranch
    required String title,
    required String description,
    required String breed,
    required int age,
    required int quantity,
    required double price,
    required String currency,
    double? weightAvg,
    double? weightMin,
    double? weightMax,
    String? sex,
    String? purpose,
    String? feedingType, // ✅ NUEVO: tipo de alimento
    String? healthCertificateUrl,
    String? vaccinesApplied,
    bool? documentationIncluded,
    String? geneticTestResults,
    bool? isVaccinated,
    required String deliveryMethod,
    double? deliveryCost,
    double? deliveryRadiusKm,
    String? status,
  }) async {
    if (_isTestMode) {
      final mock = Map<String, dynamic>.from(_buildMockProduct(999));
      mock['title'] = title;
      return mock;
    }
    try {
      final body = {
        'ranch_id': ranchId,
        'state_id': stateId, // ✅ NUEVO: estado del ranch
        'title': title,
        'description': description,
        // 'type' eliminado - ahora se usa solo 'purpose'
        'breed': breed,
        'age': age, // ✅ Backend espera "age" (no "age_months")
        'quantity': quantity,
        'price': price,
        'currency': currency,
        'weight_avg': weightAvg,
        'weight_min': weightMin,
        'weight_max': weightMax,
        'sex': sex,
        'purpose': purpose,
        'feeding_type': feedingType, // ✅ NUEVO: tipo de alimento
        'health_certificate_url': healthCertificateUrl,
        'vaccines_applied': vaccinesApplied,
        'documentation_included': documentationIncluded,
        'genetic_test_results': geneticTestResults,
        'is_vaccinated':
            isVaccinated ?? false, // ✅ Default false si no se especifica
        // ✅ Eliminados: is_featured y negotiable (se guardan como false por defecto en backend)
        'delivery_method': deliveryMethod,
        'delivery_cost': deliveryCost,
        'delivery_radius_km': deliveryRadiusKm,
        'status': status ?? 'active',
      };

      // Remover valores null del body
      body.removeWhere((key, value) => value == null);

      // Log del body antes de enviar
      print('🌐 ProductService: POST $_baseUrl/api/products');
      print('📦 Body enviado al backend:');
      print(json.encode(body));

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/products'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 422) {
        // Errores de validación
        final errors = json.decode(response.body);
        
        // Manejar específicamente errores de KYC
        if (errors['error'] == 'kyc_incomplete' || 
            (errors['errors'] != null && errors['errors'].toString().contains('KYC'))) {
          final kycStatus = errors['kyc_status'] ?? 'no_verified';
          String message = 'Debes completar la verificación de identidad (KYC) antes de publicar productos.';
          
          if (kycStatus == 'pending') {
            message = 'Tu verificación KYC está en revisión. Por favor espera a que se complete antes de publicar productos.';
          } else if (kycStatus == 'rejected') {
            final reason = errors['rejection_reason'] ?? '';
            message = 'Tu verificación KYC fue rechazada. ${reason.isNotEmpty ? "Razón: $reason" : ""} Por favor, completa nuevamente el proceso de verificación.';
          }
          
          throw Exception(message);
        }
        
        throw Exception('Errores de validación: ${errors['errors'] ?? errors['message'] ?? 'Datos inválidos'}');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else {
        throw Exception('Error al crear producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // PUT /api/products/{id} - Actualizar producto
  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    int? ranchId,
    String? title,
    String? description,
    String? breed,
    int? age,
    int? quantity,
    double? price,
    String? currency,
    double? weightAvg,
    double? weightMin,
    double? weightMax,
    String? sex,
    String? purpose,
    String? feedingType, // ✅ NUEVO: tipo de alimento
    String? healthCertificateUrl,
    String? vaccinesApplied,
    bool? documentationIncluded,
    String? geneticTestResults,
    bool? isVaccinated,
    String? deliveryMethod,
    double? deliveryCost,
    double? deliveryRadiusKm,
    String? status,
  }) async {
    if (_isTestMode) {
      return _buildMockProduct(productId);
    }
    try {
      final body = <String, dynamic>{};

      // Solo incluir campos que no sean null
      if (ranchId != null) body['ranch_id'] = ranchId;
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      // 'type' eliminado - ahora se usa solo 'purpose'
      if (breed != null) body['breed'] = breed;
      if (age != null) body['age'] = age;
      if (quantity != null) body['quantity'] = quantity;
      if (price != null) body['price'] = price;
      if (currency != null) body['currency'] = currency;
      if (weightAvg != null) body['weight_avg'] = weightAvg;
      if (weightMin != null) body['weight_min'] = weightMin;
      if (weightMax != null) body['weight_max'] = weightMax;
      if (sex != null) body['sex'] = sex;
      if (purpose != null) body['purpose'] = purpose;
      if (feedingType != null) body['feeding_type'] = feedingType; // ✅ NUEVO
      if (healthCertificateUrl != null)
        body['health_certificate_url'] = healthCertificateUrl;
      if (vaccinesApplied != null) body['vaccines_applied'] = vaccinesApplied;
      if (documentationIncluded != null)
        body['documentation_included'] = documentationIncluded;
      if (geneticTestResults != null)
        body['genetic_test_results'] = geneticTestResults;
      if (isVaccinated != null) body['is_vaccinated'] = isVaccinated;
      if (deliveryMethod != null) body['delivery_method'] = deliveryMethod;
      if (deliveryCost != null) body['delivery_cost'] = deliveryCost;
      if (deliveryRadiusKm != null)
        body['delivery_radius_km'] = deliveryRadiusKm;
      // 'negotiable' eliminado - se guarda como false por defecto
      if (status != null) body['status'] = status;

      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/products/$productId'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Producto no encontrado');
      } else if (response.statusCode == 422) {
        final errors = json.decode(response.body);
        throw Exception('Errores de validación: ${errors['errors']}');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para actualizar este producto');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else {
        throw Exception('Error al actualizar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // DELETE /api/products/{id} - Eliminar producto
  static Future<bool> deleteProduct(int productId) async {
    if (_isTestMode) {
      return true;
    }
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/api/products/$productId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Producto no encontrado');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para eliminar este producto');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else {
        throw Exception('Error al eliminar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // POST /api/products/{id}/images - Subir imágenes
  static Future<Map<String, dynamic>> uploadImages({
    required int productId,
    required List<String> imagePaths,
  }) async {
    if (_isTestMode) {
      return {
        'product_id': productId,
        'images': imagePaths
            .map((path) => {'url': path, 'id': imagePaths.indexOf(path)})
            .toList(),
      };
    }
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/products/$productId/images'),
      );

      // Agregar headers de autenticación
      final token = await _storage.read(
          key: 'token'); // ✅ CORREGIDO: usar 'token' no 'auth_token'
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Agregar archivos
      for (int i = 0; i < imagePaths.length; i++) {
        request.files.add(await http.MultipartFile.fromPath(
          'images[$i]',
          imagePaths[i],
        ));
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 422) {
        final errors = json.decode(response.body);
        throw Exception('Errores de validación: ${errors['errors']}');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else {
        throw Exception('Error al subir imágenes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Métodos de utilidad para filtros
  static Map<String, String> createFilters({
    String? type,
    String? breed,
    String? sex,
    String? purpose,
    bool? isVaccinated,
    String? deliveryMethod,
    bool? negotiable,
    String? status,
    double? minPrice,
    double? maxPrice,
    int? minAge,
    int? maxAge,
    double? minWeight,
    double? maxWeight,
  }) {
    final filters = <String, String>{};

    if (type != null && type.isNotEmpty) filters['type'] = type;
    if (breed != null && breed.isNotEmpty) filters['breed'] = breed;
    if (sex != null && sex.isNotEmpty) filters['sex'] = sex;
    if (purpose != null && purpose.isNotEmpty) filters['purpose'] = purpose;
    if (isVaccinated != null)
      filters['is_vaccinated'] = isVaccinated.toString();
    if (deliveryMethod != null && deliveryMethod.isNotEmpty)
      filters['delivery_method'] = deliveryMethod;
    if (negotiable != null) filters['negotiable'] = negotiable.toString();
    if (status != null && status.isNotEmpty) filters['status'] = status;
    if (minPrice != null) filters['min_price'] = minPrice.toString();
    if (maxPrice != null) filters['max_price'] = maxPrice.toString();
    if (minAge != null) filters['min_age'] = minAge.toString();
    if (maxAge != null) filters['max_age'] = maxAge.toString();
    if (minWeight != null) filters['min_weight'] = minWeight.toString();
    if (maxWeight != null) filters['max_weight'] = maxWeight.toString();

    return filters;
  }

  static Map<String, dynamic> _buildMockProductsResponse({
    required int page,
    required int perPage,
  }) {
    final products = List.generate(
      perPage,
      (index) => _buildMockProduct(index + 1),
    );
    return {
      'data': products,
      'meta': {
        'current_page': page,
        'last_page': 1,
      },
    };
  }

  static Map<String, dynamic> _buildMockProduct(int id) {
    return {
      'id': id,
      'ranch_id': 1,
      'title': 'Producto de prueba $id',
      'description': 'Descripción mock para el producto $id',
      'type': 'lechero',
      'breed': 'Holstein',
      'age': 12,
      'quantity': 5,
      'price': 1200,
      'currency': 'USD',
      'status': 'active',
      'is_featured': false,
      'delivery_method': 'pickup',
      'negotiable': true,
      'is_vaccinated': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
