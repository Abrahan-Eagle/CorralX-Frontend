import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generar mocks con: flutter pub run build_runner build
@GenerateMocks([http.Client, FlutterSecureStorage])
import 'test_helpers.mocks.dart';

/// Helper para crear un mock de FlutterSecureStorage
class MockSecureStorageHelper {
  static FlutterSecureStorage createMock() {
    final mock = MockFlutterSecureStorage();
    
    // Mock para leer token (retorna null por defecto, simula no autenticado)
    when(mock.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    
    // Mock para escribir token
    when(mock.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((_) async {});
    
    // Mock para eliminar token
    when(mock.delete(key: anyNamed('key'))).thenAnswer((_) async {});
    
    // Mock para leer todos
    when(mock.readAll()).thenAnswer((_) async => {});
    
    // Mock para eliminar todos
    when(mock.deleteAll()).thenAnswer((_) async {});
    
    return mock;
  }
  
  /// Crear mock con token predefinido
  static FlutterSecureStorage createMockWithToken(String token) {
    final mock = MockFlutterSecureStorage();
    
    when(mock.read(key: 'token')).thenAnswer((_) async => token);
    when(mock.read(key: anyNamed('key')))
        .thenAnswer((invocation) async {
      if (invocation.namedArguments[#key] == 'token') {
        return token;
      }
      return null;
    });
    
    when(mock.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((_) async {});
    when(mock.delete(key: anyNamed('key'))).thenAnswer((_) async {});
    when(mock.readAll()).thenAnswer((_) async => {'token': token});
    when(mock.deleteAll()).thenAnswer((_) async {});
    
    return mock;
  }
}

/// Helper para crear respuestas HTTP mock
class MockHttpResponse {
  /// Crear respuesta exitosa de productos
  static http.Response productsSuccess({
    List<Map<String, dynamic>>? products,
    int page = 1,
    int perPage = 20,
    int total = 0,
  }) {
    final productsList = products ?? [];
    final lastPage = (total / perPage).ceil();
    
    return http.Response(
      '''
{
  "current_page": $page,
  "data": ${_jsonEncode(productsList)},
  "first_page_url": "http://localhost/api/products?page=1",
  "from": ${productsList.isEmpty ? 'null' : '1'},
  "last_page": $lastPage,
  "last_page_url": "http://localhost/api/products?page=$lastPage",
  "links": [],
  "next_page_url": ${page < lastPage ? '"http://localhost/api/products?page=${page + 1}"' : 'null'},
  "path": "http://localhost/api/products",
  "per_page": $perPage,
  "prev_page_url": ${page > 1 ? '"http://localhost/api/products?page=${page - 1}"' : 'null'},
  "to": ${productsList.isEmpty ? 'null' : productsList.length.toString()},
  "total": $total
}
''',
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  
  /// Crear respuesta exitosa de anuncios activos
  static http.Response advertisementsSuccess({
    List<Map<String, dynamic>>? advertisements,
  }) {
    final adsList = advertisements ?? [];
    
    return http.Response(
      '''
{
  "data": ${_jsonEncode(adsList)},
  "count": ${adsList.length}
}
''',
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  
  /// Crear respuesta de error
  static http.Response error({
    int statusCode = 400,
    String? message,
    Map<String, dynamic>? errors,
  }) {
    final errorBody = <String, dynamic>{};
    if (message != null) {
      errorBody['message'] = message;
    }
    if (errors != null) {
      errorBody['errors'] = errors;
    }
    
    return http.Response(
      _jsonEncode(errorBody),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
  
  /// Crear respuesta de producto individual
  static http.Response productSuccess(Map<String, dynamic> product) {
    return http.Response(
      _jsonEncode(product),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  
  /// Crear respuesta de favorito toggle
  static http.Response favoriteToggleSuccess({
    required bool isFavorite,
    String? message,
  }) {
    return http.Response(
      '''
{
  "success": true,
  "is_favorite": $isFavorite,
  "message": "${message ?? (isFavorite ? 'Agregado a favoritos' : 'Removido de favoritos')}"
}
''',
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  
  /// Helper para convertir a JSON string
  static String _jsonEncode(dynamic data) {
    if (data is List) {
      return '[${data.map((e) => _jsonEncode(e)).join(',')}]';
    } else if (data is Map) {
      final entries = data.entries.map((e) {
        final key = '"${e.key}"';
        final value = e.value is String 
            ? '"${e.value.toString().replaceAll('"', '\\"')}"'
            : e.value is bool
                ? e.value.toString()
                : e.value is num
                    ? e.value.toString()
                    : e.value == null
                        ? 'null'
                        : _jsonEncode(e.value);
        return '$key: $value';
      }).join(',');
      return '{$entries}';
    } else if (data is String) {
      return '"${data.replaceAll('"', '\\"')}"';
    } else if (data is num || data is bool) {
      return data.toString();
    } else if (data == null) {
      return 'null';
    }
    return '""';
  }
}

/// Helper para crear datos de prueba
class TestDataFactory {
  /// Crear producto de prueba
  static Map<String, dynamic> createProduct({
    int id = 1,
    String title = 'Test Product',
    String type = 'lechero',
    String breed = 'Holstein',
    double price = 1000.0,
    String status = 'active',
  }) {
    return {
      'id': id,
      'ranch_id': 1,
      'state_id': null,
      'title': title,
      'description': 'Test description',
      'type': type,
      'breed': breed,
      'age': 24,
      'quantity': 10,
      'price': price.toStringAsFixed(2),
      'currency': 'USD',
      'status': status,
      'weight_avg': null,
      'weight_min': null,
      'weight_max': null,
      'sex': 'mixed',
      'purpose': 'dairy',
      'health_certificate_url': null,
      'vaccines_applied': null,
      'last_vaccination': null,
      'is_vaccinated': true,
      'feeding_info': null,
      'handling_info': null,
      'origin_farm': 'Test Ranch',
      'available_from': null,
      'available_until': null,
      'delivery_method': 'both',
      'delivery_cost': null,
      'delivery_radius_km': null,
      'price_type': 'per_unit',
      'negotiable': false,
      'min_order_quantity': null,
      'is_featured': false,
      'views': 0,
      'transportation_included': 'no',
      'documentation_included': null,
      'genetic_tests_available': false,
      'genetic_test_results': null,
      'bloodline': null,
      'created_at': '2025-01-01T00:00:00.000000Z',
      'updated_at': '2025-01-01T00:00:00.000000Z',
    };
  }
  
  /// Crear anuncio de prueba
  static Map<String, dynamic> createAdvertisement({
    int id = 1,
    String type = 'sponsored_product',
    String title = 'Test Ad',
    int priority = 50,
    int? productId,
  }) {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': 'Test ad description',
      'image_url': 'https://example.com/image.jpg',
      'target_url': type == 'external_ad' ? 'https://example.com' : null,
      'is_active': true,
      'start_date': '2025-01-01T00:00:00.000000Z',
      'end_date': '2025-12-31T23:59:59.000000Z',
      'priority': priority,
      'clicks': 0,
      'impressions': 0,
      'product_id': productId,
      'advertiser_name': type == 'external_ad' ? 'Test Advertiser' : null,
      'created_by': 1,
      'created_at': '2025-01-01T00:00:00.000000Z',
      'updated_at': '2025-01-01T00:00:00.000000Z',
    };
  }
}

/// Helper para esperar operaciones async en tests
class AsyncTestHelper {
  /// Esperar a que un provider termine todas sus operaciones async
  static Future<void> waitForProviderOperations() async {
    // Dar tiempo para que las operaciones async terminen
    await Future.delayed(const Duration(milliseconds: 100));
    // Permitir que el event loop procese callbacks pendientes
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  /// Esperar múltiples operaciones async
  static Future<void> waitForMultipleOperations(int count) async {
    for (int i = 0; i < count; i++) {
      await waitForProviderOperations();
    }
  }
}

