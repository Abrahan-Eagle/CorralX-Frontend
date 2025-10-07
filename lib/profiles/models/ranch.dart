import 'package:zonix/profiles/models/address.dart';

/// Modelo Ranch - Hacienda/Finca en el marketplace
///
/// Representa una hacienda o finca asociada a un perfil de vendedor.
/// Contiene información comercial y legal de la operación ganadera.
class Ranch {
  final int id;
  final int profileId;
  final String name; // Nombre de la hacienda
  final String? legalName; // Razón social
  final String? taxId; // RIF
  final String? businessDescription;
  final String? contactHours;
  final int? addressId;
  final bool isPrimary; // Hacienda principal del usuario
  final String? deliveryPolicy;
  final String? returnPolicy;
  final double avgRating;
  final int totalSales;
  final DateTime? lastSaleAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relaciones
  final Address? address;

  Ranch({
    required this.id,
    required this.profileId,
    required this.name,
    this.legalName,
    this.taxId,
    this.businessDescription,
    this.contactHours,
    this.addressId,
    required this.isPrimary,
    this.deliveryPolicy,
    this.returnPolicy,
    required this.avgRating,
    required this.totalSales,
    this.lastSaleAt,
    required this.createdAt,
    required this.updatedAt,
    this.address,
  });

  /// Factory para crear una instancia desde JSON
  factory Ranch.fromJson(Map<String, dynamic> json) {
    return Ranch(
      id: _parseInt(json['id']) ?? 0,
      profileId: _parseInt(json['profile_id']) ?? 0,
      name: json['name'] ?? '',
      legalName: json['legal_name'],
      taxId: json['tax_id'],
      businessDescription: json['business_description'],
      contactHours: json['contact_hours'],
      addressId: _parseInt(json['address_id']),
      isPrimary: _parseBool(json['is_primary']) ?? false,
      deliveryPolicy: json['delivery_policy'],
      returnPolicy: json['return_policy'],
      avgRating: _parseDouble(json['avg_rating']) ?? 0.0,
      totalSales: _parseInt(json['total_sales']) ?? 0,
      lastSaleAt: _parseDateTime(json['last_sale_at']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'legal_name': legalName,
      'tax_id': taxId,
      'business_description': businessDescription,
      'contact_hours': contactHours,
      'address_id': addressId,
      'is_primary': isPrimary,
      'delivery_policy': deliveryPolicy,
      'return_policy': returnPolicy,
      'avg_rating': avgRating,
      'total_sales': totalSales,
      'last_sale_at': lastSaleAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (address != null) 'address': address!.toJson(),
    };
  }

  /// Helper: Parsear double desde dynamic
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper: Parsear int desde dynamic
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper: Parsear bool desde dynamic
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  /// Helper: Parsear DateTime desde dynamic
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Crear una copia con campos actualizados
  Ranch copyWith({
    int? id,
    int? profileId,
    String? name,
    String? legalName,
    String? taxId,
    String? businessDescription,
    String? contactHours,
    int? addressId,
    bool? isPrimary,
    String? deliveryPolicy,
    String? returnPolicy,
    double? avgRating,
    int? totalSales,
    DateTime? lastSaleAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Address? address,
  }) {
    return Ranch(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      businessDescription: businessDescription ?? this.businessDescription,
      contactHours: contactHours ?? this.contactHours,
      addressId: addressId ?? this.addressId,
      isPrimary: isPrimary ?? this.isPrimary,
      deliveryPolicy: deliveryPolicy ?? this.deliveryPolicy,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      avgRating: avgRating ?? this.avgRating,
      totalSales: totalSales ?? this.totalSales,
      lastSaleAt: lastSaleAt ?? this.lastSaleAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      address: address ?? this.address,
    );
  }

  /// Descripción corta de la hacienda (para compatibilidad)
  String? get description => businessDescription;
}
