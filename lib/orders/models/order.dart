import 'package:corralx/products/models/product.dart';
import 'package:corralx/profiles/models/profile.dart';
import 'package:corralx/profiles/models/ranch.dart' as ProfileRanch;

/// Modelo que representa un pedido en el sistema
class Order {
  final int id;
  final int productId;
  final int buyerProfileId;
  final int sellerProfileId;
  final int? conversationId;
  final int ranchId;

  // Información del pedido
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String currency;

  // Estado del pedido
  final String status; // 'pending', 'accepted', 'rejected', 'delivered', 'completed', 'cancelled'

  // Información de delivery
  final String deliveryMethod; // 'buyer_transport', 'seller_transport', 'external_delivery', 'corralx_delivery'
  final String? pickupLocation; // 'ranch', 'other'
  final String? pickupAddress;
  final String? deliveryAddress;
  final String? pickupNotes;
  final double? deliveryCost;
  final String? deliveryCostCurrency;
  final String? deliveryProvider;
  final String? deliveryTrackingNumber;

  // Información de comprobante
  final String? receiptNumber;
  final Map<String, dynamic>? receiptData;

  // Notas
  final String? buyerNotes;
  final String? sellerNotes;

  // Fechas
  final DateTime? expectedPickupDate;
  final DateTime? actualPickupDate;

  // Timestamps de estados
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  // Fechas de creación y actualización
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones
  final Product? product;
  final Profile? buyer;
  final Profile? seller;
  final ProfileRanch.Ranch? ranch;

  Order({
    required this.id,
    required this.productId,
    required this.buyerProfileId,
    required this.sellerProfileId,
    this.conversationId,
    required this.ranchId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.currency,
    required this.status,
    required this.deliveryMethod,
    this.pickupLocation,
    this.pickupAddress,
    this.deliveryAddress,
    this.pickupNotes,
    this.deliveryCost,
    this.deliveryCostCurrency,
    this.deliveryProvider,
    this.deliveryTrackingNumber,
    this.receiptNumber,
    this.receiptData,
    this.buyerNotes,
    this.sellerNotes,
    this.expectedPickupDate,
    this.actualPickupDate,
    this.acceptedAt,
    this.rejectedAt,
    this.deliveredAt,
    this.completedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    this.product,
    this.buyer,
    this.seller,
    this.ranch,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: _parseInt(json['id']) ?? 0,
      productId: _parseInt(json['product_id']) ?? 0,
      buyerProfileId: _parseInt(json['buyer_profile_id']) ?? 0,
      sellerProfileId: _parseInt(json['seller_profile_id']) ?? 0,
      conversationId: _parseInt(json['conversation_id']),
      ranchId: _parseInt(json['ranch_id']) ?? 0,
      quantity: _parseInt(json['quantity']) ?? 0,
      unitPrice: _parseDouble(json['unit_price']) ?? 0.0,
      totalPrice: _parseDouble(json['total_price']) ?? 0.0,
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      deliveryMethod: json['delivery_method'] ?? 'buyer_transport',
      pickupLocation: json['pickup_location'],
      pickupAddress: json['pickup_address'],
      deliveryAddress: json['delivery_address'],
      pickupNotes: json['pickup_notes'],
      deliveryCost: _parseDouble(json['delivery_cost']),
      deliveryCostCurrency: json['delivery_cost_currency'],
      deliveryProvider: json['delivery_provider'],
      deliveryTrackingNumber: json['delivery_tracking_number'],
      receiptNumber: json['receipt_number'],
      receiptData: json['receipt_data'] is Map ? Map<String, dynamic>.from(json['receipt_data']) : null,
      buyerNotes: json['buyer_notes'],
      sellerNotes: json['seller_notes'],
      expectedPickupDate: json['expected_pickup_date'] != null
          ? DateTime.parse(json['expected_pickup_date'])
          : null,
      actualPickupDate: json['actual_pickup_date'] != null
          ? DateTime.parse(json['actual_pickup_date'])
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      buyer: json['buyer'] != null ? Profile.fromJson(json['buyer']) : null,
      seller: json['seller'] != null ? Profile.fromJson(json['seller']) : null,
      ranch: json['ranch'] != null ? ProfileRanch.Ranch.fromJson(json['ranch']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'buyer_profile_id': buyerProfileId,
      'seller_profile_id': sellerProfileId,
      'conversation_id': conversationId,
      'ranch_id': ranchId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'currency': currency,
      'status': status,
      'delivery_method': deliveryMethod,
      'pickup_location': pickupLocation,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'pickup_notes': pickupNotes,
      'delivery_cost': deliveryCost,
      'delivery_cost_currency': deliveryCostCurrency,
      'delivery_provider': deliveryProvider,
      'delivery_tracking_number': deliveryTrackingNumber,
      'receipt_number': receiptNumber,
      'receipt_data': receiptData,
      'buyer_notes': buyerNotes,
      'seller_notes': sellerNotes,
      'expected_pickup_date': expectedPickupDate?.toIso8601String(),
      'actual_pickup_date': actualPickupDate?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'product': product?.toJson(),
      'buyer': buyer?.toJson(),
      'seller': seller?.toJson(),
      'ranch': ranch?.toJson(),
    };
  }

  // Helper methods para parsear tipos desde JSON
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // Métodos de conveniencia para estados
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isDelivered => status == 'delivered';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  // Métodos de conveniencia para delivery
  String get deliveryMethodDisplayName {
    switch (deliveryMethod) {
      case 'buyer_transport':
        return 'Transporte del comprador';
      case 'seller_transport':
        return 'Transporte del vendedor';
      case 'external_delivery':
        return 'Delivery externo';
      case 'corralx_delivery':
        return 'Delivery CorralX';
      default:
        return 'No especificado';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'rejected':
        return 'Rechazado';
      case 'delivered':
        return 'Entregado';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  // Formato de precio
  String get formattedTotalPrice {
    return '${currency == 'USD' ? '\$' : 'Bs'} ${totalPrice.toStringAsFixed(2)}';
  }

  String get formattedUnitPrice {
    return '${currency == 'USD' ? '\$' : 'Bs'} ${unitPrice.toStringAsFixed(2)}';
  }

  // Verificar si el pedido tiene comprobante
  bool get hasReceipt => receiptNumber != null && receiptData != null;

  // Verificar si se puede aceptar
  bool get canBeAccepted => isPending;

  // Verificar si se puede rechazar
  bool get canBeRejected => isPending;

  // Verificar si se puede marcar como entregado
  bool get canBeDelivered => isAccepted;

  // Verificar si se puede calificar
  bool get canBeReviewed => isDelivered && !isCompleted;

  // Verificar si se puede cancelar
  bool get canBeCancelled => isPending || isAccepted;
}

