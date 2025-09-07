// profile_model.dart
class Profile {
  int id;
  int userId; // Clave foránea
  String firstName;
  String middleName;
  String lastName;
  String secondLastName;
  String? photo; // Cambiado a nullable
  String dateOfBirth;
  String maritalStatus;
  String sex;
  // String status; // Agregado

  // Constructor
  Profile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.secondLastName,
    this.photo,
    required this.dateOfBirth,
    required this.maritalStatus,
    required this.sex,
    // required this.status, // Agregado
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,
      firstName: (json['firstName'] ?? '').toString(),
      middleName: (json['middleName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      secondLastName: (json['secondLastName'] ?? '').toString(),
      photo: json['photo_users']?.toString(),
      dateOfBirth: (json['date_of_birth'] ?? '').toString(),
      maritalStatus: (json['maritalStatus'] ?? '').toString(),
      sex: (json['sex'] ?? '').toString(),
      // status: json['status'], // Agregado
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'secondLastName': secondLastName,
      'photo_users': photo,
      'date_of_birth': dateOfBirth,
      'maritalStatus': maritalStatus,
      'sex': sex,
      // 'status': status, // Agregado
    };
  }

  // Método para crear una copia con algunos campos modificados
  Profile copyWith({
    int? id,
    int? userId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? secondLastName,
    String? photo,
    String? dateOfBirth,
    String? maritalStatus,
    String? sex,
    // String? status, // Agregado
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      secondLastName: secondLastName ?? this.secondLastName,
      photo: photo ?? this.photo,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      sex: sex ?? this.sex,
      // status: status ?? this.status, // Agregado
    );
  }
}
