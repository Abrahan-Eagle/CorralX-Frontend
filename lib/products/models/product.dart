class Product {
  final int id;
  final String title;
  final String description;
  final String type; // 'engorde', 'lechero', 'padrote', 'equipment', 'feed', 'other'
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
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      weightAvg: json['weight_avg']?.toDouble(),
      weightMin: json['weight_min']?.toDouble(),
      weightMax: json['weight_max']?.toDouble(),
      sex: json['sex'],
      purpose: json['purpose'],
      healthCertificateUrl: json['health_certificate_url'],
      vaccinesApplied: json['vaccines_applied'],
      documentationIncluded: json['documentation_included'],
      geneticTestResults: json['genetic_test_results'],
      isVaccinated: json['is_vaccinated'],
      deliveryMethod: json['delivery_method'] ?? 'pickup',
      deliveryCost: json['delivery_cost']?.toDouble(),
      deliveryRadiusKm: json['delivery_radius_km']?.toDouble(),
      negotiable: json['negotiable'] ?? false,
      status: json['status'] ?? 'active',
      viewsCount: json['views_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      ranchId: json['ranch_id'] ?? 0,
      ranch: json['ranch'] != null ? Ranch.fromJson(json['ranch']) : null,
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => ProductImage.fromJson(image))
          .toList() ?? [],
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
      id: json['id'] ?? 0,
      fileUrl: json['file_url'] ?? '',
      fileType: json['file_type'] ?? 'image',
      isPrimary: json['is_primary'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      duration: json['duration'],
      resolution: json['resolution'],
      format: json['format'],
      fileSize: json['file_size'],
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
  final String name;
  final String? legalName;
  final String? description;
  final String? specialization;
  final double? avgRating;
  final int? totalSales;
  final DateTime? lastSaleAt;

  Ranch({
    required this.id,
    required this.name,
    this.legalName,
    this.description,
    this.specialization,
    this.avgRating,
    this.totalSales,
    this.lastSaleAt,
  });

  factory Ranch.fromJson(Map<String, dynamic> json) {
    return Ranch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      legalName: json['legal_name'],
      description: json['description'],
      specialization: json['specialization'],
      avgRating: json['avg_rating']?.toDouble(),
      totalSales: json['total_sales'],
      lastSaleAt: json['last_sale_at'] != null 
          ? DateTime.parse(json['last_sale_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'legal_name': legalName,
      'description': description,
      'specialization': specialization,
      'avg_rating': avgRating,
      'total_sales': totalSales,
      'last_sale_at': lastSaleAt?.toIso8601String(),
    };
  }

  String get displayName {
    return legalName ?? name;
  }
}
