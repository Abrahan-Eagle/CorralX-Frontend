import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

/// Provider para gestionar el estado de los pedidos
class OrderProvider with ChangeNotifier {
  bool _disposed = false;

  // Listas de pedidos
  List<Order> _buyerOrders = [];
  List<Order> _sellerOrders = [];

  // Pedido seleccionado
  Order? _selectedOrder;

  // Estados de carga
  bool _isLoadingBuyerOrders = false;
  bool _isLoadingSellerOrders = false;
  bool _isLoadingOrderDetail = false;
  bool _isCreating = false;
  bool _isAccepting = false;
  bool _isRejecting = false;
  bool _isUpdating = false;
  bool _isDelivering = false;
  bool _isCancelling = false;
  bool _isSubmittingReview = false;

  // Estados de error
  String? _errorMessage;
  Map<String, List<String>>? _validationErrors;

  // Paginación
  int _buyerCurrentPage = 1;
  int _sellerCurrentPage = 1;
  bool _hasMoreBuyerPages = true;
  bool _hasMoreSellerPages = true;

  // Getters
  List<Order> get buyerOrders => _buyerOrders;
  List<Order> get sellerOrders => _sellerOrders;
  Order? get selectedOrder => _selectedOrder;

  bool get isLoadingBuyerOrders => _isLoadingBuyerOrders;
  bool get isLoadingSellerOrders => _isLoadingSellerOrders;
  bool get isLoadingOrderDetail => _isLoadingOrderDetail;
  bool get isCreating => _isCreating;
  bool get isAccepting => _isAccepting;
  bool get isRejecting => _isRejecting;
  bool get isUpdating => _isUpdating;
  bool get isDelivering => _isDelivering;
  bool get isCancelling => _isCancelling;
  bool get isSubmittingReview => _isSubmittingReview;

  String? get errorMessage => _errorMessage;
  Map<String, List<String>>? get validationErrors => _validationErrors;

  bool get hasMoreBuyerPages => _hasMoreBuyerPages;
  bool get hasMoreSellerPages => _hasMoreSellerPages;

  /// Limpiar errores
  void clearErrors() {
    _errorMessage = null;
    _validationErrors = null;
    _safeNotifyListeners();
  }

  /// Limpiar errores (método privado para uso interno)
  void _clearErrors() {
    _errorMessage = null;
    _validationErrors = null;
  }

  /// Cargar pedidos como comprador
  Future<void> loadBuyerOrders({
    String? status,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _buyerCurrentPage = 1;
        _buyerOrders = [];
        _hasMoreBuyerPages = true;
      }

      if (!_hasMoreBuyerPages && !refresh) {
        return;
      }

      _isLoadingBuyerOrders = true;
      _clearErrors();
      _safeNotifyListeners();

      final response = await OrderService.getOrders(
        role: 'buyer',
        status: status,
        page: _buyerCurrentPage,
      );

      final List<dynamic> data = response['data'] ?? [];
      final List<Order> newOrders =
          data.map((json) => Order.fromJson(json)).toList();

      if (refresh) {
        _buyerOrders = newOrders;
      } else {
        _buyerOrders.addAll(newOrders);
      }

      _buyerCurrentPage++;
      _hasMoreBuyerPages = response['current_page'] < response['last_page'];

      _isLoadingBuyerOrders = false;
      _safeNotifyListeners();
    } catch (e) {
      _isLoadingBuyerOrders = false;
      _errorMessage = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Cargar pedidos como vendedor
  Future<void> loadSellerOrders({
    String? status,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _sellerCurrentPage = 1;
        _sellerOrders = [];
        _hasMoreSellerPages = true;
      }

      if (!_hasMoreSellerPages && !refresh) {
        return;
      }

      _isLoadingSellerOrders = true;
      _clearErrors();
      _safeNotifyListeners();

      final response = await OrderService.getOrders(
        role: 'seller',
        status: status,
        page: _sellerCurrentPage,
      );

      final List<dynamic> data = response['data'] ?? [];
      final List<Order> newOrders =
          data.map((json) => Order.fromJson(json)).toList();

      if (refresh) {
        _sellerOrders = newOrders;
      } else {
        _sellerOrders.addAll(newOrders);
      }

      _sellerCurrentPage++;
      _hasMoreSellerPages = response['current_page'] < response['last_page'];

      _isLoadingSellerOrders = false;
      _safeNotifyListeners();
    } catch (e) {
      _isLoadingSellerOrders = false;
      _errorMessage = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Cargar detalle de un pedido
  Future<void> loadOrderDetail(int orderId) async {
    try {
      _isLoadingOrderDetail = true;
      _clearErrors();
      _safeNotifyListeners();

      final response = await OrderService.getOrderDetail(orderId);
      _selectedOrder = Order.fromJson(response['data'] ?? response);

      _isLoadingOrderDetail = false;
      _safeNotifyListeners();
    } catch (e) {
      _isLoadingOrderDetail = false;
      _errorMessage = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Crear un nuevo pedido
  Future<bool> createOrder({
    required int productId,
    required int quantity,
    required double unitPrice,
    required String deliveryMethod,
    int? conversationId,
    String? pickupLocation,
    String? pickupAddress,
    String? deliveryAddress,
    String? pickupNotes,
    double? deliveryCost,
    String? deliveryCostCurrency,
    String? deliveryProvider,
    String? deliveryTrackingNumber,
    DateTime? expectedPickupDate,
    String? buyerNotes,
  }) async {
    try {
      _isCreating = true;
      _clearErrors();
      _safeNotifyListeners();

      final response = await OrderService.createOrder(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        deliveryMethod: deliveryMethod,
        conversationId: conversationId,
        pickupLocation: pickupLocation,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        pickupNotes: pickupNotes,
        deliveryCost: deliveryCost,
        deliveryCostCurrency: deliveryCostCurrency,
        deliveryProvider: deliveryProvider,
        deliveryTrackingNumber: deliveryTrackingNumber,
        expectedPickupDate: expectedPickupDate,
        buyerNotes: buyerNotes,
      );

      final Order newOrder = Order.fromJson(response['data'] ?? response);

      // Agregar a la lista correspondiente
      _buyerOrders.insert(0, newOrder);

      _isCreating = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString();

      // Parsear errores de validación si existen
      if (e.toString().contains('validation')) {
        _validationErrors = {'general': [e.toString()]};
      }

      _safeNotifyListeners();
      return false;
    }
  }

  /// Aceptar un pedido
  Future<bool> acceptOrder(int orderId) async {
    try {
      _isAccepting = true;
      _clearErrors();
      _safeNotifyListeners();

      final response = await OrderService.acceptOrder(orderId);
      final Order updatedOrder = Order.fromJson(response['data'] ?? response);

      // Actualizar en listas
      _updateOrderInLists(updatedOrder);
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }

      _isAccepting = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _isAccepting = false;
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  /// Rechazar un pedido
  Future<bool> rejectOrder(int orderId, {String? reason}) async {
    try {
      _isRejecting = true;
      _clearErrors();
      _safeNotifyListeners();

      final response = await OrderService.rejectOrder(orderId, reason: reason);
      final Order updatedOrder = Order.fromJson(response['data'] ?? response);

      // Actualizar en listas
      _updateOrderInLists(updatedOrder);
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }

      _isRejecting = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _isRejecting = false;
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  /// Actualizar un pedido pendiente (vendedor)
  Future<bool> updateOrder({
    required int orderId,
    int? quantity,
    double? unitPrice,
    String? deliveryMethod,
    String? pickupLocation,
    String? pickupAddress,
    String? deliveryAddress,
    String? pickupNotes,
    double? deliveryCost,
    String? deliveryCostCurrency,
    String? deliveryProvider,
    String? deliveryTrackingNumber,
    DateTime? expectedPickupDate,
    String? sellerNotes,
  }) async {
    try {
      _isUpdating = true;
      _clearErrors();
      _safeNotifyListeners();

      final response = await OrderService.updateOrder(
        orderId: orderId,
        quantity: quantity,
        unitPrice: unitPrice,
        deliveryMethod: deliveryMethod,
        pickupLocation: pickupLocation,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        pickupNotes: pickupNotes,
        deliveryCost: deliveryCost,
        deliveryCostCurrency: deliveryCostCurrency,
        deliveryProvider: deliveryProvider,
        deliveryTrackingNumber: deliveryTrackingNumber,
        expectedPickupDate: expectedPickupDate,
        sellerNotes: sellerNotes,
      );

      final Order updatedOrder = Order.fromJson(response['data'] ?? response);

      // Actualizar en listas
      _updateOrderInLists(updatedOrder);
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }

      _isUpdating = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _isUpdating = false;
      _errorMessage = e.toString();

      // Parsear errores de validación si existen
      if (e.toString().contains('validation')) {
        _validationErrors = {'general': [e.toString()]};
      }

      _safeNotifyListeners();
      return false;
    }
  }

  /// Marcar como entregado
  Future<bool> markAsDelivered(int orderId) async {
    try {
      _isDelivering = true;
      _clearErrors();
      _safeNotifyListeners();

      final response = await OrderService.markAsDelivered(orderId);
      final Order updatedOrder = Order.fromJson(response['data'] ?? response);

      // Actualizar en listas
      _updateOrderInLists(updatedOrder);
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }

      _isDelivering = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _isDelivering = false;
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  /// Cancelar un pedido
  Future<bool> cancelOrder(int orderId, {String? reason}) async {
    try {
      _isCancelling = true;
      _clearErrors();
      _safeNotifyListeners();

      final response = await OrderService.cancelOrder(orderId, reason: reason);
      final Order updatedOrder = Order.fromJson(response['data'] ?? response);

      // Actualizar en listas
      _updateOrderInLists(updatedOrder);
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }

      _isCancelling = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _isCancelling = false;
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  /// Enviar calificación
  Future<bool> submitReview({
    required int orderId,
    int? productRating,
    String? productComment,
    int? sellerRating,
    String? sellerComment,
    int? buyerRating,
    String? buyerComment,
  }) async {
    try {
      _isSubmittingReview = true;
      _clearErrors();
      _safeNotifyListeners();

      await OrderService.submitReview(
        orderId: orderId,
        productRating: productRating,
        productComment: productComment,
        sellerRating: sellerRating,
        sellerComment: sellerComment,
        buyerRating: buyerRating,
        buyerComment: buyerComment,
      );

      // Recargar detalle del pedido
      await loadOrderDetail(orderId);

      _isSubmittingReview = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _isSubmittingReview = false;
      // Extraer mensaje de error más amigable
      String errorMsg = e.toString();
      
      // Si el error contiene información del servidor, intentar extraer el mensaje
      if (errorMsg.contains('Ya registraste')) {
        // Extraer el mensaje del backend
        final match = RegExp(r'Ya registraste[^\.]*\.').firstMatch(errorMsg);
        if (match != null) {
          errorMsg = match.group(0)!;
        }
      } else if (errorMsg.contains('Duplicate entry') || errorMsg.contains('duplicate')) {
        errorMsg = 'Ya registraste tus calificaciones para este pedido.';
      } else if (errorMsg.contains('product_id') && errorMsg.contains('cannot be null')) {
        errorMsg = 'Error: No se pudo identificar el producto. Por favor intenta de nuevo.';
      } else if (errorMsg.contains('Connection error') || errorMsg.contains('Error de conexión')) {
        // Intentar extraer el mensaje real del error anidado
        final match = RegExp(r'Exception:\s*(.+?)(?:\n|$)').firstMatch(errorMsg);
        if (match != null) {
          final innerError = match.group(1)!.trim();
          if (innerError.contains('Ya registraste')) {
            errorMsg = innerError;
          } else {
            errorMsg = 'Error de conexión. Por favor intenta de nuevo.';
          }
        }
      }
      
      _errorMessage = errorMsg;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Obtener comprobante de venta
  Future<Map<String, dynamic>?> getReceipt(int orderId) async {
    try {
      _clearErrors();
      final response = await OrderService.getReceipt(orderId);
      // El backend devuelve { receipt: {...}, order: {...} }
      if (response.containsKey('receipt')) {
        return Map<String, dynamic>.from(response['receipt'] as Map);
      }
      return response['data'] ?? response;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return null;
    }
  }

  /// Actualizar pedido en las listas
  void _updateOrderInLists(Order updatedOrder) {
    final buyerIndex = _buyerOrders.indexWhere((o) => o.id == updatedOrder.id);
    if (buyerIndex != -1) {
      _buyerOrders[buyerIndex] = updatedOrder;
    }

    final sellerIndex = _sellerOrders.indexWhere((o) => o.id == updatedOrder.id);
    if (sellerIndex != -1) {
      _sellerOrders[sellerIndex] = updatedOrder;
    }
  }

  /// Refrescar todas las listas
  Future<void> refreshAll() async {
    await Future.wait([
      loadBuyerOrders(refresh: true),
      loadSellerOrders(refresh: true),
    ]);
  }

  /// Helper para notificar listeners de forma segura
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

