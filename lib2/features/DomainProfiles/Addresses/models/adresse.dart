class Address {
  final int? id; // Cambia a nullable

  final String street;
  final String houseNumber;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String status;
  final int profileId;
  final int cityId;

  Address({
    this.id, // No requerido
    required this.street,
    required this.houseNumber,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.profileId,
    required this.cityId,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(
              json['id']?.toString() ?? ''), // Parsear id si está presente
      street: (json['street'] ?? '').toString(),
      houseNumber: (json['house_number'] ?? '').toString(),
      postalCode: (json['postal_code'] ?? '').toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      status: (json['status'] ?? '').toString(),
      profileId: json['profile_id'] is int
          ? json['profile_id']
          : int.tryParse(json['profile_id']?.toString() ?? '') ?? 0,
      cityId: json['city_id'] is int
          ? json['city_id']
          : int.tryParse(json['city_id']?.toString() ?? '') ?? 0,
    );
  }
}
