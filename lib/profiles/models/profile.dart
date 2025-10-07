import 'package:zonix/profiles/models/address.dart';
import 'package:zonix/profiles/models/ranch.dart';

/// Modelo Profile - Datos del marketplace de ganado
///
/// Este modelo representa el perfil completo de un usuario en el marketplace.
/// Contiene toda la información personal, comercial y de verificación necesaria
/// para operar en la plataforma de compra/venta de ganado.
class Profile {
  final int id;
  final int userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? secondLastName;
  final String? photoUsers; // URL de la foto
  final DateTime? dateOfBirth;
  final String? maritalStatus; // married, divorced, single
  final String? sex; // F, M
  final String ciNumber;
  final String status; // verified, notverified, suspended
  final bool isVerified;
  final double rating; // avg_rating
  final int ratingsCount;
  final bool hasUnreadMessages;
  final String userType; // buyer, seller, both
  final bool isBothVerified;
  final bool acceptsCalls;
  final bool acceptsWhatsapp;
  final bool acceptsEmails;
  final String? whatsappNumber;
  final bool isPremiumSeller;
  final DateTime? premiumExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones (opcional, dependiendo de la respuesta del backend)
  final Ranch? ranch;
  final Address? address;

  Profile({
    required this.id,
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.secondLastName,
    this.photoUsers,
    this.dateOfBirth,
    this.maritalStatus,
    this.sex,
    required this.ciNumber,
    required this.status,
    required this.isVerified,
    required this.rating,
    required this.ratingsCount,
    required this.hasUnreadMessages,
    required this.userType,
    required this.isBothVerified,
    required this.acceptsCalls,
    required this.acceptsWhatsapp,
    required this.acceptsEmails,
    this.whatsappNumber,
    required this.isPremiumSeller,
    this.premiumExpiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.ranch,
    this.address,
  });

  /// Nombre completo del usuario
  String get fullName {
    final parts = [
      firstName,
      if (middleName != null && middleName!.isNotEmpty) middleName,
      lastName,
      if (secondLastName != null && secondLastName!.isNotEmpty) secondLastName,
    ];
    return parts.join(' ');
  }

  /// Nombre comercial (para vendedores, usa el nombre del ranch si existe)
  String get displayName {
    if (ranch != null && ranch!.name.isNotEmpty) {
      return ranch!.name;
    }
    return fullName;
  }

  /// Factory para crear una instancia desde JSON
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',
      secondLastName: json['secondLastName'],
      photoUsers: json['photo_users'],
      dateOfBirth: _parseDateTime(json['date_of_birth']),
      maritalStatus: json['maritalStatus'],
      sex: json['sex'],
      ciNumber: json['ci_number'] ?? '',
      status: json['status'] ?? 'notverified',
      isVerified: _parseBool(json['is_verified']) ?? false,
      rating: _parseDouble(json['rating']) ?? 0.0,
      ratingsCount: _parseInt(json['ratings_count']) ?? 0,
      hasUnreadMessages: _parseBool(json['has_unread_messages']) ?? false,
      userType: json['user_type'] ?? 'buyer',
      isBothVerified: _parseBool(json['is_both_verified']) ?? false,
      acceptsCalls: _parseBool(json['accepts_calls']) ?? true,
      acceptsWhatsapp: _parseBool(json['accepts_whatsapp']) ?? true,
      acceptsEmails: _parseBool(json['accepts_emails']) ?? true,
      whatsappNumber: json['whatsapp_number'],
      isPremiumSeller: _parseBool(json['is_premium_seller']) ?? false,
      premiumExpiresAt: _parseDateTime(json['premium_expires_at']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      ranch: json['ranch'] != null ? Ranch.fromJson(json['ranch']) : null,
      address:
          json['address'] != null ? Address.fromJson(json['address']) : null,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'secondLastName': secondLastName,
      'photo_users': photoUsers,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'maritalStatus': maritalStatus,
      'sex': sex,
      'ci_number': ciNumber,
      'status': status,
      'is_verified': isVerified,
      'rating': rating,
      'ratings_count': ratingsCount,
      'has_unread_messages': hasUnreadMessages,
      'user_type': userType,
      'is_both_verified': isBothVerified,
      'accepts_calls': acceptsCalls,
      'accepts_whatsapp': acceptsWhatsapp,
      'accepts_emails': acceptsEmails,
      'whatsapp_number': whatsappNumber,
      'is_premium_seller': isPremiumSeller,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (ranch != null) 'ranch': ranch!.toJson(),
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

  /// Helper: Parsear int desde dynamic
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
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
  Profile copyWith({
    int? id,
    int? userId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? secondLastName,
    String? photoUsers,
    DateTime? dateOfBirth,
    String? maritalStatus,
    String? sex,
    String? ciNumber,
    String? status,
    bool? isVerified,
    double? rating,
    int? ratingsCount,
    bool? hasUnreadMessages,
    String? userType,
    bool? isBothVerified,
    bool? acceptsCalls,
    bool? acceptsWhatsapp,
    bool? acceptsEmails,
    String? whatsappNumber,
    bool? isPremiumSeller,
    DateTime? premiumExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Ranch? ranch,
    Address? address,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      secondLastName: secondLastName ?? this.secondLastName,
      photoUsers: photoUsers ?? this.photoUsers,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      sex: sex ?? this.sex,
      ciNumber: ciNumber ?? this.ciNumber,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      userType: userType ?? this.userType,
      isBothVerified: isBothVerified ?? this.isBothVerified,
      acceptsCalls: acceptsCalls ?? this.acceptsCalls,
      acceptsWhatsapp: acceptsWhatsapp ?? this.acceptsWhatsapp,
      acceptsEmails: acceptsEmails ?? this.acceptsEmails,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      isPremiumSeller: isPremiumSeller ?? this.isPremiumSeller,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ranch: ranch ?? this.ranch,
      address: address ?? this.address,
    );
  }
}
