/// Modelo Ranch - Hacienda/Finca en el marketplace
///
/// Representa una hacienda o finca asociada a un perfil de vendedor.
/// Contiene información comercial y legal de la operación ganadera.
class Ranch {
  final int id;
  final int profileId;
  final String name; // Nombre de la hacienda
  final String legalName; // Razón social
  final String taxId; // RIF
  final String? description;
  final String? contactHours;
  final int? addressId;
  final bool isPrimary; // Hacienda principal del usuario
  final DateTime createdAt;
  final DateTime updatedAt;

  Ranch({
    required this.id,
    required this.profileId,
    required this.name,
    required this.legalName,
    required this.taxId,
    this.description,
    this.contactHours,
    this.addressId,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory para crear una instancia desde JSON
  factory Ranch.fromJson(Map<String, dynamic> json) {
    return Ranch(
      id: _parseInt(json['id']) ?? 0,
      profileId: _parseInt(json['profile_id']) ?? 0,
      name: json['name'] ?? '',
      legalName: json['legal_name'] ?? '',
      taxId: json['tax_id'] ?? '',
      description: json['description'],
      contactHours: json['contact_hours'],
      addressId: _parseInt(json['address_id']),
      isPrimary: _parseBool(json['is_primary']) ?? false,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
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
      'description': description,
      'contact_hours': contactHours,
      'address_id': addressId,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
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
    String? description,
    String? contactHours,
    int? addressId,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ranch(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      description: description ?? this.description,
      contactHours: contactHours ?? this.contactHours,
      addressId: addressId ?? this.addressId,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
