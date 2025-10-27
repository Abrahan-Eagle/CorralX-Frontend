import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'package:zonix/favorites/services/favorite_service.dart';

class ProductProvider with ChangeNotifier {
  // Estado de productos
  List<Product> _products = [];
  Product? _selectedProduct;
  List<Product> _myProducts = [];

  // Estados de carga
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  // Estados de error
  String? _errorMessage;
  Map<String, List<String>>? _validationErrors;

  // Filtros y paginación
  Map<String, dynamic> _currentFilters = {};
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Favoritos
  Set<int> _favorites = {};
  List<Product> _favoriteProducts = [];
  int _currentFavoritesPage = 1;
  bool _hasMoreFavorites = true;
  bool _isLoadingFavorites = false;

  // Getters
  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  List<Product> get myProducts => _myProducts;

  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;

  String? get errorMessage => _errorMessage;
  Map<String, List<String>>? get validationErrors => _validationErrors;

  Map<String, dynamic> get currentFilters => _currentFilters;
  bool get hasMorePages => _hasMorePages;
  Set<int> get favorites => _favorites;
  
  // Getters de favoritos
  List<Product> get favoriteProducts => _favoriteProducts;
  bool get isLoadingFavorites => _isLoadingFavorites;
  bool get hasMoreFavorites => _hasMoreFavorites;
  int get currentFavoritesPage => _currentFavoritesPage;

  // Método para limpiar errores
  void _clearErrors() {
    _errorMessage = null;
    _validationErrors = null;
  }

  // Cargar productos con filtros
  Future<void> fetchProducts({
    Map<String, dynamic>? filters,
    bool refresh = false,
  }) async {
    try {
      print('🔍 ProductProvider.fetchProducts iniciado');
      _clearErrors();

      if (refresh) {
        _currentPage = 1;
        _products.clear();
        _hasMorePages = true;
      }

      _isLoading = true;
      notifyListeners();

      if (filters != null) {
        _currentFilters = filters;
        print('🔍 Filtros aplicados: $_currentFilters');
      }

      print('🔍 Llamando a ProductService.getProducts...');
      final response = await ProductService.getProducts(
        filters: _currentFilters.isNotEmpty ? _currentFilters : null,
        page: _currentPage,
        perPage: 20,
      );

      print('🔍 Respuesta recibida: $response');

      if (response['data'] != null) {
        final List<dynamic> productData = response['data'];
        print('🔍 Datos de productos: $productData');

        final List<Product> newProducts =
            productData.map((json) => Product.fromJson(json)).toList();

        print('🔍 Productos parseados: ${newProducts.length}');

        if (refresh) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }

        print('🔍 Total productos en provider: ${_products.length}');

        // Verificar si hay más páginas
        final pagination = response['meta'];
        if (pagination != null) {
          _hasMorePages = _currentPage < pagination['last_page'];
          print(
              '🔍 Paginación: página $_currentPage de ${pagination['last_page']}');
        }

        _currentPage++;
      } else {
        print('⚠️ No hay datos en la respuesta');
      }
    } catch (e) {
      print('❌ Error en fetchProducts: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar más productos (paginación)
  Future<void> loadMoreProducts() async {
    if (!_isLoading && _hasMorePages) {
      await fetchProducts();
    }
  }

  // Obtener detalle de un producto
  Future<void> fetchProductDetail(int productId) async {
    try {
      print('🔍 ProductProvider.fetchProductDetail: Iniciando carga de producto $productId');
      _clearErrors();
      _isLoading = true;
      notifyListeners();

      final response = await ProductService.getProductDetail(productId);
      print('🔍 ProductProvider: Response recibida: ${response.containsKey('data')}');

      if (response['data'] != null) {
        _selectedProduct = Product.fromJson(response['data']);
        print('✅ ProductProvider: Producto cargado correctamente - ID: ${_selectedProduct?.id}');
      } else {
        print('⚠️ ProductProvider: Response no contiene "data"');
      }
    } catch (e) {
      print('❌ ProductProvider: Error en fetchProductDetail: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear nuevo producto
  Future<bool> createProduct({
    required int ranchId,
    int? stateId, // ✅ NUEVO: ID del estado del ranch
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
    double? weightMax, // ✅ Corregido de maxWeight a weightMax
    String? sex,
    String? purpose,
    String? healthCertificateUrl,
    String? vaccinesApplied,
    bool? documentationIncluded,
    String? geneticTestResults,
    bool? isVaccinated,
    bool? isFeatured, // ✅ NUEVO: destacado
    required String deliveryMethod,
    double? deliveryCost,
    double? deliveryRadiusKm,
    required bool negotiable,
    String? status,
    List<String>? imagePaths,
  }) async {
    try {
      _clearErrors();
      _isCreating = true;
      notifyListeners();

      // Crear el producto
      final response = await ProductService.createProduct(
        ranchId: ranchId,
        stateId: stateId, // ✅ NUEVO: pasar stateId
        title: title,
        description: description,
        type: type,
        breed: breed,
        age: age,
        quantity: quantity,
        price: price,
        currency: currency,
        weightAvg: weightAvg,
        weightMin: weightMin,
        weightMax: weightMax, // ✅ Corregido
        sex: sex,
        purpose: purpose,
        healthCertificateUrl: healthCertificateUrl,
        vaccinesApplied: vaccinesApplied,
        documentationIncluded: documentationIncluded,
        geneticTestResults: geneticTestResults,
        isVaccinated: isVaccinated,
        isFeatured: isFeatured, // ✅ NUEVO
        deliveryMethod: deliveryMethod,
        deliveryCost: deliveryCost,
        deliveryRadiusKm: deliveryRadiusKm,
        negotiable: negotiable,
        status: status,
      );

      // ✅ Backend devuelve el producto directamente (no en 'data')
      print('📦 ProductProvider: Response recibida');

      // Intentar obtener el producto desde 'data' o directamente
      final productData = response['data'] ?? response;
      print('📦 ProductProvider: productData obtenido');

      print('📦 ProductProvider: Intentando parsear producto...');
      try {
        final newProduct = Product.fromJson(productData);
        print(
            '✅ ProductProvider: Producto parseado correctamente - ID: ${newProduct.id}');
        _products.insert(0, newProduct); // Agregar al inicio

        // ✅ Subir imágenes si existen (endpoint implementado en backend)
        if (imagePaths != null && imagePaths.isNotEmpty) {
          print(
              '📸 ProductProvider: Subiendo ${imagePaths.length} imágenes...');
          try {
            await ProductService.uploadImages(
              productId: newProduct.id,
              imagePaths: imagePaths,
            );
            print('✅ ProductProvider: Imágenes subidas exitosamente');

            // Refrescar el producto para obtener las imágenes actualizadas
            notifyListeners();
          } catch (imageError) {
            print(
                '⚠️ ProductProvider: Error al subir imágenes (no crítico): $imageError');
            // NO retornar false, el producto ya se creó exitosamente
          }
        }

        print('✅ ProductProvider: ¡Producto creado exitosamente!');
        return true;
      } catch (parseError) {
        print('❌ ProductProvider: Error al parsear producto: $parseError');
        _errorMessage = 'Error al procesar respuesta del servidor';
        return false;
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      // Manejar errores de validación
      if (errorMessage.contains('Errores de validación:')) {
        // Aquí podrías parsear los errores de validación si el backend los retorna estructurados
        _validationErrors = {
          'general': [errorMessage]
        };
      } else {
        _errorMessage = errorMessage;
      }

      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // Actualizar producto
  Future<bool> updateProduct({
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
      _clearErrors();
      _isUpdating = true;
      notifyListeners();

      final response = await ProductService.updateProduct(
        productId: productId,
        ranchId: ranchId,
        title: title,
        description: description,
        type: type,
        breed: breed,
        age: age,
        quantity: quantity,
        price: price,
        currency: currency,
        weightAvg: weightAvg,
        weightMin: weightMin,
        weightMax: weightMax,
        sex: sex,
        purpose: purpose,
        healthCertificateUrl: healthCertificateUrl,
        vaccinesApplied: vaccinesApplied,
        documentationIncluded: documentationIncluded,
        geneticTestResults: geneticTestResults,
        isVaccinated: isVaccinated,
        deliveryMethod: deliveryMethod,
        deliveryCost: deliveryCost,
        deliveryRadiusKm: deliveryRadiusKm,
        negotiable: negotiable,
        status: status,
      );

      if (response['data'] != null) {
        final updatedProduct = Product.fromJson(response['data']);

        // Actualizar en la lista de productos
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = updatedProduct;
        }

        // Actualizar producto seleccionado si es el mismo
        if (_selectedProduct?.id == productId) {
          _selectedProduct = updatedProduct;
        }

        // Actualizar en mis productos si existe
        final myIndex = _myProducts.indexWhere((p) => p.id == productId);
        if (myIndex != -1) {
          _myProducts[myIndex] = updatedProduct;
        }

        return true;
      }

      return false;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      if (errorMessage.contains('Errores de validación:')) {
        _validationErrors = {
          'general': [errorMessage]
        };
      } else {
        _errorMessage = errorMessage;
      }

      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Eliminar producto
  Future<bool> deleteProduct(int productId) async {
    try {
      _clearErrors();
      _isDeleting = true;
      notifyListeners();

      final success = await ProductService.deleteProduct(productId);

      if (success) {
        // Remover de la lista de productos
        _products.removeWhere((p) => p.id == productId);

        // Remover de mis productos
        _myProducts.removeWhere((p) => p.id == productId);

        // Limpiar producto seleccionado si es el mismo
        if (_selectedProduct?.id == productId) {
          _selectedProduct = null;
        }
      }

      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // Cargar mis productos (del usuario actual)
  Future<void> fetchMyProducts({bool refresh = false}) async {
    try {
      _clearErrors();

      if (refresh) {
        _myProducts.clear();
      }

      _isLoading = true;
      notifyListeners();

      // Usar filtros para obtener solo mis productos
      // Esto dependerá de cómo el backend maneje la propiedad
      final response = await ProductService.getProducts(
        filters: {'my_products': 'true'}, // Ajustar según el backend
        page: 1,
        perPage: 100,
      );

      if (response['data'] != null) {
        final List<dynamic> productData = response['data'];
        _myProducts =
            productData.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpiar filtros
  void clearFilters() {
    _currentFilters.clear();
    fetchProducts(refresh: true);
  }

  // Refrescar productos
  Future<void> refreshProducts() async {
    await fetchProducts(refresh: true);
  }

  // Método para aplicar filtros desde el modal
  void applyFilters(Map<String, dynamic> filters) {
    _currentFilters = filters;
    fetchProducts(filters: filters, refresh: true);
  }

  // Método para obtener el conteo de filtros activos
  int get activeFiltersCount {
    int count = 0;
    if (_currentFilters['search'] != null &&
        _currentFilters['search'].toString().isNotEmpty) count++;
    if (_currentFilters['type'] != null && _currentFilters['type'] != 'Todos')
      count++;
    if (_currentFilters['location'] != null &&
        _currentFilters['location'] != 'Todos') count++;
    if (_currentFilters['min_price'] != null &&
        _currentFilters['min_price'] > 0) count++;
    if (_currentFilters['max_price'] != null &&
        _currentFilters['max_price'] < 100000) count++;
    if (_currentFilters['sort_by'] != null &&
        _currentFilters['sort_by'] != 'newest') count++;
    if (_currentFilters['quantity'] != null && _currentFilters['quantity'] > 1)
      count++;
    return count;
  }

  // Limpiar estado
  void clearState() {
    _products.clear();
    _selectedProduct = null;
    _myProducts.clear();
    _currentFilters.clear();
    _currentPage = 1;
    _hasMorePages = true;
    _clearErrors();
    notifyListeners();
  }

  // Métodos de utilidad
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsByType(String type) {
    return _products.where((p) => p.type == type).toList();
  }

  List<Product> getProductsByBreed(String breed) {
    return _products
        .where((p) => p.breed.toLowerCase().contains(breed.toLowerCase()))
        .toList();
  }

  List<Product> getAvailableProducts() {
    return _products.where((p) => p.isAvailable).toList();
  }

  /// Cargar lista de productos favoritos del usuario
  Future<void> fetchFavorites({int page = 1, bool refresh = false}) async {
    if (refresh) {
      _favoriteProducts.clear();
      _currentFavoritesPage = 1;
      _hasMoreFavorites = true;
    }

    if (_isLoadingFavorites) {
      print('⚠️ Ya se están cargando favoritos, saltando...');
      return;
    }

    try {
      _isLoadingFavorites = true;
      _clearErrors();
      notifyListeners();

      print('🔍 ProductProvider.fetchFavorites iniciado - Página: $page');

      final response = await FavoriteService.getMyFavorites(
        page: page,
        perPage: 20,
      );

      print('🔍 Respuesta de favoritos recibida');

      // Parsear productos de la respuesta
      final favoritesData = response['data'] as List;
      final newFavorites = favoritesData.map((fav) {
        return Product.fromJson(fav['product']);
      }).toList();

      print('🔍 Favoritos parseados: ${newFavorites.length}');

      if (refresh) {
        _favoriteProducts = newFavorites;
      } else {
        _favoriteProducts.addAll(newFavorites);
      }

      // Actualizar set de IDs de favoritos
      _favorites = _favoriteProducts.map((p) => p.id).toSet();

      // Actualizar paginación
      _currentFavoritesPage = page;
      _hasMoreFavorites = response['current_page'] < response['last_page'];

      print('✅ Favoritos cargados: ${_favoriteProducts.length} total');
      print('📊 Página actual: $_currentFavoritesPage, Hay más: $_hasMoreFavorites');
    } catch (e) {
      print('❌ Error en fetchFavorites: $e');
      _errorMessage = 'Error al cargar favoritos: $e';
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  /// Toggle favorito (agregar/remover) con sincronización al backend
  Future<void> toggleFavorite(int productId) async {
    try {
      print('🔄 ProductProvider.toggleFavorite - ProductID: $productId');
      
      // 1. Optimistic update (actualizar UI inmediatamente)
      final wasInFavorites = _favorites.contains(productId);
      if (wasInFavorites) {
        _favorites.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
        print('🔄 Optimistic: Removido de favoritos localmente');
      } else {
        _favorites.add(productId);
        // ✅ Solo agregar si no existe ya
        if (!_favoriteProducts.any((p) => p.id == productId)) {
          // Intentar obtener el producto desde _products o _selectedProduct
          Product? product;
          try {
            product = _products.firstWhere((p) => p.id == productId);
          } catch (e) {
            // Si no está en _products, obtenerlo del backend
            try {
              final response = await ProductService.getProductDetail(productId);
              if (response['data'] != null) {
                product = Product.fromJson(response['data']);
              }
            } catch (e2) {
              print('⚠️ No se pudo obtener el producto: $e2');
            }
          }
          
          if (product != null) {
            _favoriteProducts.add(product);
          }
        }
        print('🔄 Optimistic: Agregado a favoritos localmente (ID: $productId)');
      }
      notifyListeners();
      
      // 2. Sincronizar con backend
      print('🌐 Llamando a FavoriteService.toggleFavorite...');
      final isFavorite = await FavoriteService.toggleFavorite(productId);
      
      // 3. Si se agregó exitosamente, recargar lista de favoritos para asegurar datos completos
      if (isFavorite && !wasInFavorites) {
        print('🔄 Recargando lista de favoritos para actualizar UI...');
        await fetchFavorites(refresh: false);
        return; // Ya se actualizó con fetchFavorites, no hacer más
      }
      
      // 4. Sincronizar estado con respuesta del servidor (solo si no se recargó)
      if (isFavorite && !_favorites.contains(productId)) {
        _favorites.add(productId);
        print('✅ Sincronizado: Agregado a favoritos');
      } else if (!isFavorite && _favorites.contains(productId)) {
        _favorites.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
        print('✅ Sincronizado: Removido de favoritos');
      }
      
      notifyListeners();
      print('✅ Toggle favorito completado - Estado final: ${isFavorite ? "FAVORITO" : "NO FAVORITO"}');
    } catch (e) {
      print('❌ Error al toggle favorito: $e');
      
      // Revertir cambio optimista si falló
      final wasInFavorites = _favorites.contains(productId);
      if (wasInFavorites) {
        _favorites.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
        print('🔄 Revirtiendo: Removido de favoritos');
      } else {
        _favorites.add(productId);
        print('🔄 Revirtiendo: Agregado a favoritos');
      }
      
      notifyListeners();
      
      _errorMessage = 'Error al actualizar favorito';
      rethrow; // Para que la UI pueda mostrar error si lo desea
    }
  }

  /// Verificar si un producto es favorito
  Future<bool> checkIsFavorite(int productId) async {
    try {
      final isFavorite = await FavoriteService.isFavorite(productId);
      
      // Sincronizar con estado local
      if (isFavorite) {
        _favorites.add(productId);
      } else {
        _favorites.remove(productId);
      }
      
      return isFavorite;
    } catch (e) {
      print('❌ Error al verificar favorito: $e');
      return _favorites.contains(productId); // Fallback al estado local
    }
  }

  /// Cargar más favoritos (paginación infinita)
  Future<void> loadMoreFavorites() async {
    if (!_hasMoreFavorites || _isLoadingFavorites) {
      print('⚠️ No hay más favoritos o ya se están cargando');
      return;
    }

    await fetchFavorites(page: _currentFavoritesPage + 1, refresh: false);
  }
}
