import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'dart:math';
import '../models/product.dart';
import '../models/advertisement.dart';
import '../services/product_service.dart';
import '../services/advertisement_service.dart';
import 'package:zonix/favorites/services/favorite_service.dart';

class ProductProvider with ChangeNotifier {
  // Flag para verificar si el provider está disposed
  bool _disposed = false;
  
  // Estado de productos
  List<Product> _products = [];
  Product? _selectedProduct;
  List<Product> _myProducts = [];

  // Estado de anuncios
  List<Advertisement> _advertisements = [];
  List<MarketplaceItem> _marketplaceItems = []; // Lista mezclada de productos y anuncios

  // Estados de carga
  bool _isLoading = false;
  bool _isLoadingAdvertisements = false;
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
  List<Advertisement> get advertisements => _advertisements;
  List<MarketplaceItem> get marketplaceItems => _marketplaceItems;

  bool get isLoading => _isLoading;
  bool get isLoadingAdvertisements => _isLoadingAdvertisements;
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

  // Cargar anuncios activos
  Future<void> fetchAdvertisements() async {
    try {
      debugPrint('📢 ProductProvider.fetchAdvertisements iniciado');
      _isLoadingAdvertisements = true;
      _safeNotifyListeners();

      final ads = await AdvertisementService.getActiveAdvertisements();
      _advertisements = ads;

      debugPrint('📢 Anuncios cargados: ${_advertisements.length}');
      
      // Mezclar con productos si ya están cargados
      _mixProductsWithAdvertisements();
    } catch (e) {
      debugPrint('❌ Error en fetchAdvertisements: $e');
      // No mostrar error crítico, solo log
    } finally {
      _isLoadingAdvertisements = false;
      _safeNotifyListeners();
    }
  }

  // Mezclar productos con anuncios usando modelo unificado con prioridad
  // Modelo similar a Instagram: anuncios con mayor prioridad aparecen primero,
  // pero manteniendo rotación aleatoria dentro de cada nivel de prioridad
  void _mixProductsWithAdvertisements() {
    debugPrint('🔄 Mezclando productos con anuncios (modelo unificado con prioridad)...');
    
    final random = Random();
    
    // Separar anuncios por prioridad
    final List<MarketplaceItem> highPriorityAds = []; // priority > 50
    final List<MarketplaceItem> lowPriorityAds = [];  // priority <= 50
    final List<MarketplaceItem> normalProducts = [];

    // Agregar todos los productos normales
    // NOTA: Los productos con anuncio patrocinado aparecerán tanto como producto normal
    // como en su versión patrocinada (según la especificación - Opción A)
    for (var product in _products) {
      normalProducts.add(MarketplaceItem.fromProduct(product));
    }

    // Separar anuncios por prioridad
    for (var ad in _advertisements) {
      final adItem = MarketplaceItem.fromAdvertisement(ad);
      if (ad.priority > 50) {
        highPriorityAds.add(adItem);
      } else {
        lowPriorityAds.add(adItem);
      }
    }

    // Ordenar anuncios de alta prioridad por prioridad (mayor primero)
    // pero aplicar variación aleatoria para rotación
    highPriorityAds.sort((a, b) {
      final adA = a.item as Advertisement;
      final adB = b.item as Advertisement;
      // Aplicar variación aleatoria del ±20% para rotación
      final priorityA = adA.priority * (0.8 + random.nextDouble() * 0.4);
      final priorityB = adB.priority * (0.8 + random.nextDouble() * 0.4);
      return priorityB.compareTo(priorityA);
    });

    // Ordenar anuncios de baja prioridad por prioridad (mayor primero)
    // pero aplicar variación aleatoria para rotación
    lowPriorityAds.sort((a, b) {
      final adA = a.item as Advertisement;
      final adB = b.item as Advertisement;
      // Aplicar variación aleatoria del ±20% para rotación
      final priorityA = adA.priority * (0.8 + random.nextDouble() * 0.4);
      final priorityB = adB.priority * (0.8 + random.nextDouble() * 0.4);
      return priorityB.compareTo(priorityA);
    });

    // Mezclar productos normales aleatoriamente
    normalProducts.shuffle(random);

    // Mezclar anuncios de baja prioridad con productos normales
    final List<MarketplaceItem> normalAndLowPriority = [];
    normalAndLowPriority.addAll(normalProducts);
    normalAndLowPriority.addAll(lowPriorityAds);
    normalAndLowPriority.shuffle(random);

    // Construir lista final: primero anuncios de alta prioridad, luego el resto mezclado
    final List<MarketplaceItem> finalItems = [];
    finalItems.addAll(highPriorityAds);
    finalItems.addAll(normalAndLowPriority);

    // Aplicar un shuffle final suave para intercalar mejor
    // (pero manteniendo que los de alta prioridad estén más arriba)
    if (highPriorityAds.isNotEmpty && normalAndLowPriority.isNotEmpty) {
      // Intercalar algunos productos normales entre anuncios de alta prioridad
      // para evitar que todos los anuncios estén al inicio
      final List<MarketplaceItem> intercalated = [];
      int highIndex = 0;
      int normalIndex = 0;
      
      // Intercalar: 2-3 anuncios de alta prioridad, luego 1-2 productos normales
      while (highIndex < highPriorityAds.length || normalIndex < normalAndLowPriority.length) {
        // Agregar 2-3 anuncios de alta prioridad
        for (int i = 0; i < 2 + random.nextInt(2) && highIndex < highPriorityAds.length; i++) {
          intercalated.add(highPriorityAds[highIndex]);
          highIndex++;
        }
        
        // Agregar 1-2 productos normales/baja prioridad
        for (int i = 0; i < 1 + random.nextInt(2) && normalIndex < normalAndLowPriority.length; i++) {
          intercalated.add(normalAndLowPriority[normalIndex]);
          normalIndex++;
        }
      }
      
      _marketplaceItems = intercalated;
    } else {
      _marketplaceItems = finalItems;
    }
    
    debugPrint('✅ Marketplace items mezclados con prioridad: ${_marketplaceItems.length} (${normalProducts.length} productos normales + ${highPriorityAds.length} anuncios alta prioridad + ${lowPriorityAds.length} anuncios baja prioridad)');
  }
  
  // Verificar si un producto tiene anuncio patrocinado
  bool isProductSponsored(int productId) {
    return _advertisements.any(
      (ad) => ad.isSponsoredProduct && ad.productId == productId && ad.isCurrentlyActive,
    );
  }

  // Cargar productos con filtros
  Future<void> fetchProducts({
    Map<String, dynamic>? filters,
    bool refresh = false,
  }) async {
    try {
      debugPrint('🔍 ProductProvider.fetchProducts iniciado');
      _clearErrors();

      if (refresh) {
        _currentPage = 1;
        _products.clear();
        _hasMorePages = true;
      }

      _isLoading = true;
      _safeNotifyListeners();

      if (filters != null) {
        _currentFilters = filters;
        debugPrint('🔍 Filtros aplicados: $_currentFilters');
      }

      debugPrint('🔍 Llamando a ProductService.getProducts...');
      final response = await ProductService.getProducts(
        filters: _currentFilters.isNotEmpty ? _currentFilters : null,
        page: _currentPage,
        perPage: 20,
      );

      debugPrint('🔍 Respuesta recibida: $response');

      if (response['data'] != null) {
        final List<dynamic> productData = response['data'];
        debugPrint('🔍 Datos de productos: $productData');

        final List<Product> newProducts =
            productData.map((json) => Product.fromJson(json)).toList();

        debugPrint('🔍 Productos parseados: ${newProducts.length}');

        if (refresh) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }

        debugPrint('🔍 Total productos en provider: ${_products.length}');

        // Verificar si hay más páginas
        final pagination = response['meta'];
        if (pagination != null) {
          _hasMorePages = _currentPage < pagination['last_page'];
          debugPrint(
              '🔍 Paginación: página $_currentPage de ${pagination['last_page']}');
        }

        _currentPage++;
        
        // Mezclar con anuncios después de cargar productos
        _mixProductsWithAdvertisements();
      } else {
        debugPrint('⚠️ No hay datos en la respuesta');
      }
    } catch (e) {
      debugPrint('❌ Error en fetchProducts: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
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
      debugPrint('🔍 ProductProvider.fetchProductDetail: Iniciando carga de producto $productId');
      _clearErrors();
      _isLoading = true;
      _safeNotifyListeners();

      final response = await ProductService.getProductDetail(productId);
      debugPrint('🔍 ProductProvider: Response recibida: ${response.keys.toList()}');

      // El backend devuelve el producto directamente o en {data: ...}
      Product? product;
      if (response['data'] != null) {
        product = Product.fromJson(response['data']);
        debugPrint('✅ ProductProvider: Producto cargado desde "data" - ID: ${product.id}');
      } else if (response['id'] != null) {
        // El backend devuelve el producto directamente
        product = Product.fromJson(response);
        debugPrint('✅ ProductProvider: Producto cargado directamente - ID: ${product.id}');
      } else {
        debugPrint('⚠️ ProductProvider: Response no contiene ni "data" ni "id"');
      }
      
      if (product != null) {
        _selectedProduct = product;
        debugPrint('✅ ProductProvider: Producto asignado a _selectedProduct');
      }
    } catch (e) {
      debugPrint('❌ ProductProvider: Error en fetchProductDetail: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
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
      _safeNotifyListeners();

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
      debugPrint('📦 ProductProvider: Response recibida');

      // Intentar obtener el producto desde 'data' o directamente
      final productData = response['data'] ?? response;
      debugPrint('📦 ProductProvider: productData obtenido');

      debugPrint('📦 ProductProvider: Intentando parsear producto...');
      try {
        final newProduct = Product.fromJson(productData);
        debugPrint(
            '✅ ProductProvider: Producto parseado correctamente - ID: ${newProduct.id}');
        _products.insert(0, newProduct); // Agregar al inicio

        // ✅ Subir imágenes si existen (endpoint implementado en backend)
        if (imagePaths != null && imagePaths.isNotEmpty) {
          debugPrint(
              '📸 ProductProvider: Subiendo ${imagePaths.length} imágenes...');
          try {
            await ProductService.uploadImages(
              productId: newProduct.id,
              imagePaths: imagePaths,
            );
            debugPrint('✅ ProductProvider: Imágenes subidas exitosamente');

            // Refrescar el producto para obtener las imágenes actualizadas
            _safeNotifyListeners();
          } catch (imageError) {
            debugPrint(
                '⚠️ ProductProvider: Error al subir imágenes (no crítico): $imageError');
            // NO retornar false, el producto ya se creó exitosamente
          }
        }

        debugPrint('✅ ProductProvider: ¡Producto creado exitosamente!');
        return true;
      } catch (parseError) {
        debugPrint('❌ ProductProvider: Error al parsear producto: $parseError');
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
      _safeNotifyListeners();
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
      _safeNotifyListeners();

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
      _safeNotifyListeners();
    }
  }

  // Eliminar producto
  Future<bool> deleteProduct(int productId) async {
    try {
      _clearErrors();
      _isDeleting = true;
      _safeNotifyListeners();

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
      _safeNotifyListeners();
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
      _safeNotifyListeners();

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
      _safeNotifyListeners();
    }
  }

  // Limpiar filtros
  void clearFilters() {
    _currentFilters.clear();
    fetchProducts(refresh: true);
  }

  // Refrescar productos y anuncios
  Future<void> refreshProducts() async {
    await Future.wait([
      fetchProducts(refresh: true),
      fetchAdvertisements(),
    ]);
  }
  
  // Obtener producto asociado a un anuncio patrocinado
  // Prioriza el producto que viene en el anuncio (del backend) sobre la lista local
  Product? getProductForSponsoredAd(Advertisement ad) {
    if (!ad.isSponsoredProduct || ad.productId == null) return null;
    
    // PRIMERO: Intentar usar el producto que viene en el anuncio (más actualizado)
    if (ad.product != null) {
      try {
        return Product.fromJson(ad.product!);
      } catch (e) {
        debugPrint('⚠️ Error al parsear producto del anuncio: $e');
      }
    }
    
    // SEGUNDO: Buscar en la lista local de productos
    try {
      return _products.firstWhere((p) => p.id == ad.productId);
    } catch (e) {
      debugPrint('⚠️ Producto ${ad.productId} no encontrado en la lista local');
      return null;
    }
  }
  
  // Registrar click en anuncio
  Future<void> registerAdvertisementClick(Advertisement ad) async {
    await AdvertisementService.registerClick(ad.id);
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
    _advertisements.clear();
    _marketplaceItems.clear();
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
      debugPrint('⚠️ Ya se están cargando favoritos, saltando...');
      return;
    }

    try {
      _isLoadingFavorites = true;
      _clearErrors();
      _safeNotifyListeners();

      debugPrint('🔍 ProductProvider.fetchFavorites iniciado - Página: $page');

      final response = await FavoriteService.getMyFavorites(
        page: page,
        perPage: 20,
      );

      debugPrint('🔍 Respuesta de favoritos recibida');

      // Parsear productos de la respuesta
      final favoritesData = response['data'] as List;
      final newFavorites = favoritesData.map((fav) {
        return Product.fromJson(fav['product']);
      }).toList();

      debugPrint('🔍 Favoritos parseados: ${newFavorites.length}');

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

      debugPrint('✅ Favoritos cargados: ${_favoriteProducts.length} total');
      debugPrint('📊 Página actual: $_currentFavoritesPage, Hay más: $_hasMoreFavorites');
    } catch (e) {
      debugPrint('❌ Error en fetchFavorites: $e');
      _errorMessage = 'Error al cargar favoritos: $e';
    } finally {
      _isLoadingFavorites = false;
      _safeNotifyListeners();
    }
  }

  /// Toggle favorito (agregar/remover) con sincronización al backend
  Future<void> toggleFavorite(int productId) async {
    try {
      debugPrint('🔄 ProductProvider.toggleFavorite - ProductID: $productId');
      
      // 1. Optimistic update (actualizar UI inmediatamente)
      final wasInFavorites = _favorites.contains(productId);
      if (wasInFavorites) {
        _favorites.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
        debugPrint('🔄 Optimistic: Removido de favoritos localmente');
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
              debugPrint('⚠️ No se pudo obtener el producto: $e2');
            }
          }
          
          if (product != null) {
            _favoriteProducts.add(product);
          }
        }
        debugPrint('🔄 Optimistic: Agregado a favoritos localmente (ID: $productId)');
      }
      _safeNotifyListeners();
      
      // 2. Sincronizar con backend
      debugPrint('🌐 Llamando a FavoriteService.toggleFavorite...');
      final isFavorite = await FavoriteService.toggleFavorite(productId);
      
      // 3. NO recargar la lista completa de favoritos porque causa duplicados
      // El optimistic update ya añadió/removió el producto localmente
      // Solo sincronizar el estado si el backend confirma el cambio
      
      // 4. Verificar que el estado coincida con el backend
      if (isFavorite && !_favorites.contains(productId)) {
        // Si el backend dice que ES favorito pero localmente NO está
        _favorites.add(productId);
        // Solo agregar a _favoriteProducts si no existe ya
        if (!_favoriteProducts.any((p) => p.id == productId)) {
          Product? product;
          try {
            product = _products.firstWhere((p) => p.id == productId);
            _favoriteProducts.add(product);
          } catch (e) {
            debugPrint('⚠️ Producto no encontrado localmente, se sincronizará en la próxima carga');
          }
        }
        debugPrint('✅ Sincronizado: Agregado a favoritos');
      } else if (!isFavorite && _favorites.contains(productId)) {
        // Si el backend dice que NO es favorito pero localmente SÍ está
        _favorites.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
        debugPrint('✅ Sincronizado: Removido de favoritos');
      }
      
      _safeNotifyListeners();
      debugPrint('✅ Toggle favorito completado - Estado final: ${isFavorite ? "FAVORITO" : "NO FAVORITO"}');
    } catch (e) {
      debugPrint('❌ Error al toggle favorito: $e');
      
      // Revertir cambio optimista si falló
      final wasInFavorites = _favorites.contains(productId);
      if (wasInFavorites) {
        _favorites.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
        debugPrint('🔄 Revirtiendo: Removido de favoritos');
      } else {
        _favorites.add(productId);
        debugPrint('🔄 Revirtiendo: Agregado a favoritos');
      }
      
      _safeNotifyListeners();
      
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
      debugPrint('❌ Error al verificar favorito: $e');
      return _favorites.contains(productId); // Fallback al estado local
    }
  }

  /// Cargar más favoritos (paginación infinita)
  Future<void> loadMoreFavorites() async {
    if (!_hasMoreFavorites || _isLoadingFavorites) {
      debugPrint('⚠️ No hay más favoritos o ya se están cargando');
      return;
    }

    await fetchFavorites(page: _currentFavoritesPage + 1, refresh: false);
  }
  
  /// Override dispose para manejar correctamente el cleanup
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
  
  /// Helper para verificar si está disposed antes de notificar
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
