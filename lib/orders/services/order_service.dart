import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:corralx/config/app_config.dart';
import 'package:corralx/shared/utils/test_environment.dart';

/// Servicio para manejar todas las operaciones relacionadas con pedidos
class OrderService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static bool get _isTestMode => TestEnvironment.isRunningTests;

  /// URL base desde AppConfig - Detecta automáticamente 3 entornos (local/test/production)
  static String get _baseUrl {
    final String baseUrl = AppConfig.apiUrl;

    print('🔧 OrderService - Entorno: ${AppConfig.buildType.toUpperCase()}');
    print('🔧 OrderService - URL Base: $baseUrl');

    return baseUrl;
  }

  /// Headers comunes con token de autenticación
  static Future<Map<String, String>> _getHeaders() async {
    String? token;
    try {
      token = await _storage.read(key: 'token');
    } catch (e) {
      debugPrint('⚠️ FlutterSecureStorage no disponible en tests: $e');
      if (_isTestMode) {
        token = 'test-token';
      }
    }
    token ??= _isTestMode ? 'test-token' : null;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/orders - Listar pedidos del usuario autenticado
  /// 
  /// [role] - 'buyer' o 'seller' (default: 'buyer')
  /// [status] - Estado del pedido a filtrar (opcional)
  /// [page] - Número de página (default: 1)
  /// [perPage] - Items por página (default: 15)
  static Future<Map<String, dynamic>> getOrders({
    String role = 'buyer',
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    if (_isTestMode) {
      return _buildMockOrdersResponse(role: role, status: status);
    }
    try {
      final queryParams = <String, String>{
        'role': role,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl/api/orders').replace(
        queryParameters: queryParams,
      );

      final response = await http
          .get(
            uri,
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener pedidos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// GET /api/orders/{id} - Obtener detalle de un pedido
  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    if (_isTestMode) {
      return _buildMockOrder(orderId);
    }
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/orders/$orderId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Pedido no encontrado');
      } else {
        throw Exception('Error al obtener pedido: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// PUT /api/orders/{id} - Actualizar un pedido pendiente (vendedor)
  static Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    int? quantity,
    double? unitPrice,
    String? deliveryMethod,
    String? pickupLocation,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? pickupNotes,
    double? deliveryCost,
    String? deliveryCostCurrency,
    String? deliveryProvider,
    String? deliveryTrackingNumber,
    DateTime? expectedPickupDate,
    String? sellerNotes,
  }) async {
    if (_isTestMode) {
      return _buildMockOrder(orderId);
    }
    try {
      final body = <String, dynamic>{};

      if (quantity != null) {
        body['quantity'] = quantity;
      }
      if (unitPrice != null) {
        body['unit_price'] = unitPrice;
      }
      if (deliveryMethod != null) {
        body['delivery_method'] = deliveryMethod;
      }
      if (pickupLocation != null) {
        body['pickup_location'] = pickupLocation;
      }
      if (pickupAddress != null) {
        body['pickup_address'] = pickupAddress;
      }
      if (pickupLatitude != null) {
        body['pickup_latitude'] = pickupLatitude;
      }
      if (pickupLongitude != null) {
        body['pickup_longitude'] = pickupLongitude;
      }
      if (deliveryAddress != null) {
        body['delivery_address'] = deliveryAddress;
      }
      if (deliveryLatitude != null) {
        body['delivery_latitude'] = deliveryLatitude;
      }
      if (deliveryLongitude != null) {
        body['delivery_longitude'] = deliveryLongitude;
      }
      if (pickupNotes != null) {
        body['pickup_notes'] = pickupNotes;
      }
      if (deliveryCost != null) {
        body['delivery_cost'] = deliveryCost;
      }
      if (deliveryCostCurrency != null) {
        body['delivery_cost_currency'] = deliveryCostCurrency;
      }
      if (deliveryProvider != null) {
        body['delivery_provider'] = deliveryProvider;
      }
      if (deliveryTrackingNumber != null) {
        body['delivery_tracking_number'] = deliveryTrackingNumber;
      }
      if (expectedPickupDate != null) {
        body['expected_pickup_date'] = expectedPickupDate.toIso8601String();
      }
      if (sellerNotes != null) {
        body['seller_notes'] = sellerNotes;
      }

      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/orders/$orderId'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Error al actualizar pedido: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// POST /api/orders - Crear un pedido nuevo
  static Future<Map<String, dynamic>> createOrder({
    required int productId,
    required int quantity,
    required double unitPrice,
    required String deliveryMethod,
    int? conversationId,
    String? pickupLocation,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? pickupNotes,
    double? deliveryCost,
    String? deliveryCostCurrency,
    String? deliveryProvider,
    String? deliveryTrackingNumber,
    DateTime? expectedPickupDate,
    String? buyerNotes,
  }) async {
    if (_isTestMode) {
      return _buildMockOrder(1);
    }
    try {
      final body = <String, dynamic>{
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'delivery_method': deliveryMethod,
      };

      if (conversationId != null) {
        body['conversation_id'] = conversationId;
      }
      if (pickupLocation != null) {
        body['pickup_location'] = pickupLocation;
      }
      if (pickupAddress != null) {
        body['pickup_address'] = pickupAddress;
      }
      if (pickupLatitude != null) {
        body['pickup_latitude'] = pickupLatitude;
      }
      if (pickupLongitude != null) {
        body['pickup_longitude'] = pickupLongitude;
      }
      if (deliveryAddress != null) {
        body['delivery_address'] = deliveryAddress;
      }
      if (deliveryLatitude != null) {
        body['delivery_latitude'] = deliveryLatitude;
      }
      if (deliveryLongitude != null) {
        body['delivery_longitude'] = deliveryLongitude;
      }
      if (pickupNotes != null) {
        body['pickup_notes'] = pickupNotes;
      }
      if (deliveryCost != null) {
        body['delivery_cost'] = deliveryCost;
      }
      if (deliveryCostCurrency != null) {
        body['delivery_cost_currency'] = deliveryCostCurrency;
      }
      if (deliveryProvider != null) {
        body['delivery_provider'] = deliveryProvider;
      }
      if (deliveryTrackingNumber != null) {
        body['delivery_tracking_number'] = deliveryTrackingNumber;
      }
      if (expectedPickupDate != null) {
        body['expected_pickup_date'] = expectedPickupDate.toIso8601String();
      }
      if (buyerNotes != null) {
        body['buyer_notes'] = buyerNotes;
      }

      // Log del body que se está enviando
      debugPrint('🔍 OrderService.createOrder - Body enviado: ${json.encode(body)}');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/orders'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('🔍 OrderService.createOrder - Status: ${response.statusCode}');
      debugPrint('🔍 OrderService.createOrder - Response: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        String errorMessage = errorBody['message'] ?? 'Error al crear pedido: ${response.statusCode}';
        
        // Si hay errores de validación, agregarlos al mensaje
        if (errorBody['errors'] != null && errorBody['errors'] is Map) {
          final errors = errorBody['errors'] as Map<String, dynamic>;
          final errorList = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorList.addAll(value.map((e) => '$key: $e'));
            } else {
              errorList.add('$key: $value');
            }
          });
          if (errorList.isNotEmpty) {
            errorMessage = errorList.join('\n');
          }
        }
        
        debugPrint('❌ OrderService.createOrder - Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// PUT /api/orders/{id}/accept - Aceptar un pedido (vendedor)
  static Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    if (_isTestMode) {
      return _buildMockOrder(orderId);
    }
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/orders/$orderId/accept'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Error al aceptar pedido: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// PUT /api/orders/{id}/reject - Rechazar un pedido (vendedor)
  static Future<Map<String, dynamic>> rejectOrder(
    int orderId, {
    String? reason,
  }) async {
    if (_isTestMode) {
      return _buildMockOrder(orderId);
    }
    try {
      final body = <String, dynamic>{};
      if (reason != null) {
        body['reason'] = reason;
      }

      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/orders/$orderId/reject'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Error al rechazar pedido: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// PUT /api/orders/{id}/deliver - Marcar como entregado (comprador)
  static Future<Map<String, dynamic>> markAsDelivered(int orderId) async {
    if (_isTestMode) {
      return _buildMockOrder(orderId);
    }
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/orders/$orderId/deliver'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Error al marcar como entregado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// PUT /api/orders/{id}/cancel - Cancelar un pedido
  static Future<Map<String, dynamic>> cancelOrder(
    int orderId, {
    String? reason,
  }) async {
    if (_isTestMode) {
      return _buildMockOrder(orderId);
    }
    try {
      final body = <String, dynamic>{};
      if (reason != null) {
        body['reason'] = reason;
      }

      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/orders/$orderId/cancel'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Error al cancelar pedido: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// GET /api/orders/{id}/receipt - Obtener comprobante de venta
  static Future<Map<String, dynamic>> getReceipt(int orderId) async {
    if (_isTestMode) {
      return _buildMockReceipt(orderId);
    }
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/orders/$orderId/receipt'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Comprobante no encontrado');
      } else {
        throw Exception('Error al obtener comprobante: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// POST /api/orders/{id}/review - Enviar calificaciones mutuas
  static Future<Map<String, dynamic>> submitReview({
    required int orderId,
    // Para compradores
    int? productRating,
    String? productComment,
    int? sellerRating,
    String? sellerComment,
    // Para vendedores
    int? buyerRating,
    String? buyerComment,
  }) async {
    if (_isTestMode) {
      return {'success': true, 'message': 'Calificación enviada exitosamente'};
    }
    try {
      final body = <String, dynamic>{};

      if (productRating != null) {
        body['product_rating'] = productRating;
      }
      if (productComment != null) {
        body['product_comment'] = productComment;
      }
      if (sellerRating != null) {
        body['seller_rating'] = sellerRating;
      }
      if (sellerComment != null) {
        body['seller_comment'] = sellerComment;
      }
      if (buyerRating != null) {
        body['buyer_rating'] = buyerRating;
      }
      if (buyerComment != null) {
        body['buyer_comment'] = buyerComment;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/orders/$orderId/review'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        String errorMessage = 'Error al enviar calificación';
        
        // Extraer mensaje de error del backend
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'].toString();
        } else if (errorBody['errors'] != null) {
          // Si hay errores de validación
          final errors = errorBody['errors'];
          if (errors is Map && errors.containsKey('order_id')) {
            errorMessage = errors['order_id'][0] ?? errorMessage;
          } else {
            errorMessage = errors.toString();
          }
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Si el error ya es una Exception con mensaje, propagarlo
      if (e is Exception && e.toString().contains('Ya registraste')) {
        throw e;
      }
      // Para otros errores de conexión, incluir el mensaje original
      final errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        // Ya tiene formato de Exception, extraer el mensaje
        final match = RegExp(r'Exception:\s*(.+)$').firstMatch(errorMsg);
        if (match != null) {
          throw Exception(match.group(1)!.trim());
        }
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Mock methods para testing
  static Map<String, dynamic> _buildMockOrdersResponse({
    String role = 'buyer',
    String? status,
  }) {
    return {
      'data': [],
      'current_page': 1,
      'last_page': 1,
      'per_page': 15,
      'total': 0,
    };
  }

  static Map<String, dynamic> _buildMockOrder(int orderId) {
    return {
      'id': orderId,
      'product_id': 1,
      'buyer_profile_id': 1,
      'seller_profile_id': 2,
      'status': 'pending',
      'quantity': 5,
      'unit_price': 1000.0,
      'total_price': 5000.0,
      'currency': 'USD',
      'delivery_method': 'buyer_transport',
    };
  }

  static Map<String, dynamic> _buildMockReceipt(int orderId) {
    return {
      'receipt_number': 'CORRALX-00000001-20250101',
      'receipt_data': {
        'buyer': {},
        'seller': {},
        'product': {},
        'delivery': {},
      },
    };
  }
}

