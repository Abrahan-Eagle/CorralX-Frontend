/// Modelo Address - Dirección/Ubicación
///
/// Representa la dirección de un perfil o hacienda.
/// Incluye coordenadas geográficas y relaciones con ciudad/estado/país.
class Address {
  final int id;
  final String addresses; // Dirección completa
  final double? latitude;
  final double? longitude;
  final String status; // verified, notverified
  final int profileId;
  final int cityId;

  // Datos de relaciones (eager loading desde backend)
  final String? cityName;
  final String? stateName;
  final String? countryName;

  Address({
    required this.id,
    required this.addresses,
    this.latitude,
    this.longitude,
    required this.status,
    required this.profileId,
    required this.cityId,
    this.cityName,
    this.stateName,
    this.countryName,
  });

  /// Ubicación formateada (Ciudad, Estado)
  String get formattedLocation {
    final parts = <String>[];
    if (cityName != null && cityName!.isNotEmpty) {
      parts.add(cityName!);
    }
    if (stateName != null && stateName!.isNotEmpty) {
      parts.add(stateName!);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Ubicación no disponible';
  }

  /// Ubicación completa (Ciudad, Estado, País)
  String get fullLocation {
    final parts = <String>[];
    if (cityName != null && cityName!.isNotEmpty) {
      parts.add(cityName!);
    }
    if (stateName != null && stateName!.isNotEmpty) {
      parts.add(stateName!);
    }
    if (countryName != null && countryName!.isNotEmpty) {
      parts.add(countryName!);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Ubicación no disponible';
  }

  /// Factory para crear una instancia desde JSON
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: _parseInt(json['id']) ?? 0,
      addresses: json['adressses'] ??
          json['addresses'] ??
          '', // Backend usa 'adressses' (typo)
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      status: json['status'] ?? 'notverified',
      profileId: _parseInt(json['profile_id']) ?? 0,
      cityId: _parseInt(json['city_id']) ?? 0,
      cityName: json['city_name'] ?? json['city']?['name'],
      stateName: json['state_name'] ?? json['state']?['name'],
      countryName: json['country_name'] ?? json['country']?['name'],
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adressses': addresses, // Backend espera 'adressses'
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'profile_id': profileId,
      'city_id': cityId,
      if (cityName != null) 'city_name': cityName,
      if (stateName != null) 'state_name': stateName,
      if (countryName != null) 'country_name': countryName,
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

  /// Crear una copia con campos actualizados
  Address copyWith({
    int? id,
    String? addresses,
    double? latitude,
    double? longitude,
    String? status,
    int? profileId,
    int? cityId,
    String? cityName,
    String? stateName,
    String? countryName,
  }) {
    return Address(
      id: id ?? this.id,
      addresses: addresses ?? this.addresses,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      profileId: profileId ?? this.profileId,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      stateName: stateName ?? this.stateName,
      countryName: countryName ?? this.countryName,
    );
  }
}
