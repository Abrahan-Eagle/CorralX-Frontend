/// Modelo para representar un anuncio en el marketplace
class Advertisement {
  final int id;
  final String type; // 'sponsored_product' o 'external_ad'
  final String title;
  final String? description;
  final String imageUrl;
  final String? targetUrl;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int priority;
  final int clicks;
  final int impressions;
  final int? productId; // Solo para sponsored_product
  final String? advertiserName; // Solo para external_ad
  final Map<String, dynamic>? product; // Datos del producto si es sponsored_product

  Advertisement({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.imageUrl,
    this.targetUrl,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.priority,
    required this.clicks,
    required this.impressions,
    this.productId,
    this.advertiserName,
    this.product,
  });

  /// Factory constructor para crear Advertisement desde JSON
  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String,
      targetUrl: json['target_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      priority: json['priority'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
      impressions: json['impressions'] as int? ?? 0,
      productId: json['product_id'] as int?,
      advertiserName: json['advertiser_name'] as String?,
      product: json['product'] as Map<String, dynamic>?,
    );
  }

  /// Verificar si el anuncio está activo actualmente
  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Verificar si es un producto patrocinado
  bool get isSponsoredProduct => type == 'sponsored_product';

  /// Verificar si es publicidad externa
  bool get isExternalAd => type == 'external_ad';
}

/// Clase helper para mezclar productos y anuncios
class MarketplaceItem {
  final dynamic item; // Puede ser Product o Advertisement
  final bool isAdvertisement;
  final bool isProduct;

  MarketplaceItem({
    required this.item,
    required this.isAdvertisement,
    required this.isProduct,
  });

  /// Factory para crear un MarketplaceItem desde un Product
  factory MarketplaceItem.fromProduct(dynamic product) {
    return MarketplaceItem(
      item: product,
      isAdvertisement: false,
      isProduct: true,
    );
  }

  /// Factory para crear un MarketplaceItem desde un Advertisement
  factory MarketplaceItem.fromAdvertisement(Advertisement advertisement) {
    return MarketplaceItem(
      item: advertisement,
      isAdvertisement: true,
      isProduct: false,
    );
  }
}
