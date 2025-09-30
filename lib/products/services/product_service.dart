import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // URL base desde env_config.json
  static String get _baseUrl {
    // Por ahora usamos la URL local directamente
    return 'http://192.168.27.11:8000';
  }

  // Headers comunes con token de autenticación
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
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

  // GET /api/products/{id} - Obtener detalle de un producto
  static Future<Map<String, dynamic>> getProductDetail(int productId) async {
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
    required String title,
    required String description,
    required String type,
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
    String? healthCertificateUrl,
    String? vaccinesApplied,
    bool? documentationIncluded,
    String? geneticTestResults,
    bool? isVaccinated,
    required String deliveryMethod,
    double? deliveryCost,
    double? deliveryRadiusKm,
    required bool negotiable,
    String? status,
  }) async {
    try {
      final body = {
        'ranch_id': ranchId,
        'title': title,
        'description': description,
        'type': type,
        'breed': breed,
        'age': age,
        'quantity': quantity,
        'price': price,
        'currency': currency,
        'weight_avg': weightAvg,
        'weight_min': weightMin,
        'weight_max': weightMax,
        'sex': sex,
        'purpose': purpose,
        'health_certificate_url': healthCertificateUrl,
        'vaccines_applied': vaccinesApplied,
        'documentation_included': documentationIncluded,
        'genetic_test_results': geneticTestResults,
        'is_vaccinated': isVaccinated,
        'delivery_method': deliveryMethod,
        'delivery_cost': deliveryCost,
        'delivery_radius_km': deliveryRadiusKm,
        'negotiable': negotiable,
        'status': status ?? 'active',
      };

      // Remover valores null del body
      body.removeWhere((key, value) => value == null);

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/products'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 422) {
        // Errores de validación
        final errors = json.decode(response.body);
        throw Exception('Errores de validación: ${errors['errors']}');
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
    String? type,
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
    String? healthCertificateUrl,
    String? vaccinesApplied,
    bool? documentationIncluded,
    String? geneticTestResults,
    bool? isVaccinated,
    String? deliveryMethod,
    double? deliveryCost,
    double? deliveryRadiusKm,
    bool? negotiable,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};

      // Solo incluir campos que no sean null
      if (ranchId != null) body['ranch_id'] = ranchId;
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (type != null) body['type'] = type;
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
      if (negotiable != null) body['negotiable'] = negotiable;
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
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/products/$productId/images'),
      );

      // Agregar headers de autenticación
      final token = await _storage.read(key: 'auth_token');
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
}
