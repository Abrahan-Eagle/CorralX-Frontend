class Product {
  final int id;
  final String title;
  final String description;
  final String
      type; // 'engorde', 'lechero', 'padrote', 'equipment', 'feed', 'other'
  final String breed;
  final int age;
  final int quantity;
  final double price;
  final String currency; // 'USD', 'VES'
  final double? weightAvg;
  final double? weightMin;
  final double? weightMax;
  final String? sex; // 'male', 'female', 'mixed'
  final String? purpose; // 'breeding', 'meat', 'dairy', 'mixed'
  final String? feedingType; // ✅ NUEVO: 'pastura_natural', 'pasto_corte', 'concentrado', 'mixto', 'otro'
  final String? healthCertificateUrl;
  final String? vaccinesApplied;
  final bool? documentationIncluded;
  final String? geneticTestResults;
  final bool? isVaccinated;
  final String deliveryMethod; // 'pickup', 'delivery', 'both'
  final double? deliveryCost;
  final double? deliveryRadiusKm;
  final bool negotiable;
  final String status; // 'active', 'paused', 'sold', 'expired'
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones
  final int ranchId;
  final Ranch? ranch;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.breed,
    required this.age,
    required this.quantity,
    required this.price,
    required this.currency,
    this.weightAvg,
    this.weightMin,
    this.weightMax,
    this.sex,
    this.purpose,
    this.feedingType, // ✅ NUEVO
    this.healthCertificateUrl,
    this.vaccinesApplied,
    this.documentationIncluded,
    this.geneticTestResults,
    this.isVaccinated,
    required this.deliveryMethod,
    this.deliveryCost,
    this.deliveryRadiusKm,
    required this.negotiable,
    required this.status,
    required this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
    required this.ranchId,
    this.ranch,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _parseInt(json['id']) ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      breed: json['breed'] ?? '',
      age: _parseInt(json['age']) ?? 0,
      quantity: _parseInt(json['quantity']) ?? 0,
      price: _parseDouble(json['price']) ?? 0.0,
      currency: json['currency'] ?? 'USD',
      weightAvg: _parseDouble(json['weight_avg']),
      weightMin: _parseDouble(json['weight_min']),
      weightMax: _parseDouble(json['weight_max']),
      sex: json['sex'],
      purpose: json['purpose'],
      feedingType: json['feeding_type'], // ✅ NUEVO
      healthCertificateUrl: json['health_certificate_url'],
      vaccinesApplied: json['vaccines_applied'],
      documentationIncluded: _parseBool(json['documentation_included']),
      geneticTestResults: json['genetic_test_results'],
      isVaccinated: _parseBool(json['is_vaccinated']),
      deliveryMethod: json['delivery_method'] ?? 'pickup',
      deliveryCost: _parseDouble(json['delivery_cost']),
      deliveryRadiusKm: _parseDouble(json['delivery_radius_km']),
      negotiable: _parseBool(json['negotiable']) ?? false,
      status: json['status'] ?? 'active',
      viewsCount: _parseInt(json['views_count']) ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      ranchId: _parseInt(json['ranch_id']) ?? 0,
      ranch: json['ranch'] != null ? Ranch.fromJson(json['ranch']) : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => ProductImage.fromJson(image))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'status': status,
      'views_count': viewsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'ranch_id': ranchId,
      'ranch': ranch?.toJson(),
      'images': images.map((image) => image.toJson()).toList(),
    };
  }

  // Helper method para parsear enteros desde JSON
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // Helper method para parsear doubles desde JSON
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // Helper method para parsear booleans desde JSON
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) {
      return value == 1;
    }
    return null;
  }

  // Métodos de conveniencia
  String get formattedPrice {
    return '${currency == 'USD' ? '\$' : 'Bs'} ${price.toStringAsFixed(0)}';
  }

  String get formattedWeight {
    if (weightAvg != null) {
      return '${weightAvg!.toStringAsFixed(0)} kg promedio';
    }
    return 'Peso no especificado';
  }

  bool get isAvailable {
    return status == 'active';
  }

  String get typeDisplayName {
    switch (type) {
      case 'engorde':
        return 'Engorde';
      case 'lechero':
        return 'Lechero';
      case 'padrote':
        return 'Padrote';
      case 'equipment':
        return 'Equipos';
      case 'feed':
        return 'Alimentos';
      default:
        return 'Otros';
    }
  }

  String get sexDisplayName {
    switch (sex) {
      case 'male':
        return 'Macho';
      case 'female':
        return 'Hembra';
      case 'mixed':
        return 'Mixto';
      default:
        return 'No especificado';
    }
  }
}

class ProductImage {
  final int id;
  final String fileUrl;
  final String fileType; // 'image', 'video'
  final bool isPrimary;
  final int sortOrder;
  final int? duration;
  final String? resolution;
  final String? format;
  final int? fileSize;

  ProductImage({
    required this.id,
    required this.fileUrl,
    required this.fileType,
    required this.isPrimary,
    required this.sortOrder,
    this.duration,
    this.resolution,
    this.format,
    this.fileSize,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: Product._parseInt(json['id']) ?? 0,
      fileUrl: json['file_url'] ?? '',
      fileType: json['file_type'] ?? 'image',
      isPrimary: Product._parseBool(json['is_primary']) ?? false,
      sortOrder: Product._parseInt(json['sort_order']) ?? 0,
      duration: json['duration'],
      resolution: json['resolution'],
      format: json['format'],
      fileSize: Product._parseInt(json['file_size']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_url': fileUrl,
      'file_type': fileType,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
      'duration': duration,
      'resolution': resolution,
      'format': format,
      'file_size': fileSize,
    };
  }
}

class Ranch {
  final int id;
  final int? profileId; // Agregado para compatibilidad
  final String name;
  final String? legalName;
  final String? description;
  final String? specialization;
  final double? avgRating;
  final int? totalSales;
  final DateTime? lastSaleAt;
  // Address data (opcional, solo si viene del backend)
  final Map<String, dynamic>? addressData; // Para almacenar address si viene en JSON

  Ranch({
    required this.id,
    this.profileId,
    required this.name,
    this.legalName,
    this.description,
    this.specialization,
    this.avgRating,
    this.totalSales,
    this.lastSaleAt,
    this.addressData,
  });

  factory Ranch.fromJson(Map<String, dynamic> json) {
    // Debug: verificar si address viene en el JSON
    if (json['address'] != null) {
      print('✅ Ranch.fromJson: address encontrado: ${json['address']}');
    } else {
      print('⚠️ Ranch.fromJson: address NO encontrado en JSON. Keys disponibles: ${json.keys.toList()}');
    }
    
    return Ranch(
      id: Product._parseInt(json['id']) ?? 0,
      profileId: Product._parseInt(json['profile_id']),
      name: json['name'] ?? '',
      legalName: json['legal_name'],
      description: json['description'] ?? json['business_description'],
      specialization: json['specialization'],
      avgRating: Product._parseDouble(json['avg_rating']),
      totalSales: Product._parseInt(json['total_sales']),
      lastSaleAt: json['last_sale_at'] != null
          ? DateTime.parse(json['last_sale_at'])
          : null,
      // Almacenar address si viene en el JSON (aunque no lo parseamos completamente)
      addressData: json['address'] != null 
          ? Map<String, dynamic>.from(json['address']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'legal_name': legalName,
      'description': description,
      'specialization': specialization,
      'avg_rating': avgRating,
      'total_sales': totalSales,
      'last_sale_at': lastSaleAt?.toIso8601String(),
      if (addressData != null) 'address': addressData,
    };
  }

  String get displayName {
    return legalName ?? name;
  }
}
