class Phone {
  final int id;
  final int profileId;
  final int operatorCodeId;
  final String operatorCodeName;
  final String number;
  final bool isPrimary;
  final bool status;

  Phone({
    required this.id,
    required this.profileId,
    required this.operatorCodeId,
    required this.operatorCodeName,
    required this.number,
    required this.isPrimary,
    required this.status,
  });

  factory Phone.fromJson(Map<String, dynamic> json) {
    final operatorCode = json['operator_code'] ?? {};
    return Phone(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      profileId: json['profile_id'] is int
          ? json['profile_id']
          : int.tryParse(json['profile_id']?.toString() ?? '') ?? 0,
      operatorCodeId: operatorCode['id'] is int
          ? operatorCode['id']
          : int.tryParse(operatorCode['id']?.toString() ?? '') ?? 0,
      operatorCodeName: (operatorCode['name'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      isPrimary: json['is_primary'] is bool
          ? json['is_primary']
          : (int.tryParse(json['is_primary']?.toString() ?? '') ?? 0) == 1,
      status: json['status'] is bool
          ? json['status']
          : (int.tryParse(json['status']?.toString() ?? '') ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'operator_code_id': operatorCodeId,
      'operator_code_name': operatorCodeName,
      'number': number,
      'is_primary': isPrimary ? 1 : 0,
      'status': status ? 1 : 0,
    };
  }

  // Método copyWith para facilitar la modificación de propiedades
  Phone copyWith({
    int? id,
    int? profileId,
    int? operatorCodeId,
    String? operatorCodeName,
    String? number,
    bool? isPrimary,
    bool? status,
  }) {
    return Phone(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      operatorCodeId: operatorCodeId ?? this.operatorCodeId,
      operatorCodeName: operatorCodeName ?? this.operatorCodeName,
      number: number ?? this.number,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
    );
  }
}
