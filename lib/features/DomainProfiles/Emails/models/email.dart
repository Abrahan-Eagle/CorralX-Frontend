class Email {
  final int id;
  final int profileId;
  final String email;
  final bool isPrimary;
  final bool status;

  Email({
    required this.id,
    required this.profileId,
    required this.email,
    required this.isPrimary,
    required this.status,
  });

  // Crear una instancia desde JSON
  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      profileId: json['profile_id'] is int
          ? json['profile_id']
          : int.tryParse(json['profile_id'].toString()) ?? 0,
      email: (json['email'] ?? '').toString(),
      isPrimary: json['is_primary'] is bool
          ? json['is_primary']
          : (int.tryParse(json['is_primary'].toString()) ?? 0) == 1,
      status: json['status'] is bool
          ? json['status']
          : (int.tryParse(json['status'].toString()) ?? 0) == 1,
    );
  }

  // Convertir a JSON para enviar datos a la API
  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'email': email,
      'is_primary': isPrimary ? 1 : 0, // Enviar como 1 o 0
      'status': status ? 1 : 0, // Enviar como 1 o 0
    };
  }
}

extension EmailCopyWith on Email {
  Email copyWith({
    int? id,
    int? profileId,
    String? email,
    bool? isPrimary,
    bool? status,
  }) {
    return Email(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
    );
  }
}
