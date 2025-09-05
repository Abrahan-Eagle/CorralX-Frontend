// lib/features/GasTicket/models/gas_ticket.dart
class GasTicket {
  final int id;
  final int profileId;
  final int gasCylindersId;
  final String status;
  final String reservedDate;
  final String appointmentDate;
  final String expiryDate;
  final String queuePosition;
  final String timePosition;
  final String qrCode;
  final int stationId;
  // final int operatorCodeId;
  // final String operatorName;
  final List<String> operatorName;
  final String stationCode;

  // Datos de perfil
  final String firstName;
  final String middleName;
  final String lastName;
  final String secondLastName;
  final String photoUser;
  final String dateOfBirth;
  final String maritalStatus;
  final String sex;
  final String profileStatus;

  // Datos de usuario
  final String userName;
  final String userEmail;
  final String userProfilePic;

  // Datos de teléfono, emails, documentos y direcciones
  final List<String> phoneNumbers;
  final List<String> emailAddresses;
  final List<String> documentImages;
  final List<String> documentType;
  final List<String> documentNumberCi;
  final List<String> addresses;
  final String gasCylinderCode;
  final String cylinderQuantity;
  final String cylinderType;
  final String cylinderWeight;
  final String gasCylinderPhoto;
  final String manufacturingDate;

  GasTicket({
    required this.id,
    required this.profileId,
    required this.gasCylindersId,
    required this.status,
    required this.reservedDate,
    required this.appointmentDate,
    required this.expiryDate,
    required this.queuePosition,
    required this.timePosition,
    required this.qrCode,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.secondLastName,
    required this.photoUser,
    required this.dateOfBirth,
    required this.maritalStatus,
    required this.sex,
    required this.profileStatus,
    required this.userName,
    required this.userEmail,
    required this.userProfilePic,
    required this.phoneNumbers,
    required this.emailAddresses,
    required this.documentImages,
    required this.documentType,
    required this.documentNumberCi,
    required this.addresses,
    required this.gasCylinderCode,
    required this.cylinderQuantity,
    required this.cylinderType,
    required this.cylinderWeight,
    required this.gasCylinderPhoto,
    required this.manufacturingDate,
    required this.stationId,
    // required this.operatorCodeId,
    required this.operatorName,
    required this.stationCode,
  });

  factory GasTicket.fromJson(Map<String, dynamic> json) {
    print('DEBUG: Processing ticket JSON: ${json['id']}');
    print('DEBUG: Profile phones data: ${json['profile']['phones']}');

    var ciDocuments = (json['profile']['documents'] as List<dynamic>?)
            ?.where((document) => document['type'] == 'ci')
            .toList() ??
        [];

    List<String> frontImageList = List<String>.from(
        ciDocuments.map((document) => document['front_image'] ?? ''));
    List<String> typeList = List<String>.from(
        ciDocuments.map((document) => document['type'] ?? ''));
    List<String> numberCiList = List<String>.from(ciDocuments
        .where((document) =>
            document.containsKey('number_ci') && document['number_ci'] != null)
        .map((document) => document['number_ci']?.toString() ?? ''));

    return GasTicket(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      profileId: json['profile_id'] is int
          ? json['profile_id']
          : int.tryParse(json['profile_id'].toString()) ?? 0,
      gasCylindersId: json['gas_cylinders_id'] is int
          ? json['gas_cylinders_id']
          : int.tryParse(json['gas_cylinders_id'].toString()) ?? 0,
      status: json['status']?.toString() ?? '',
      reservedDate: json['reserved_date']?.toString() ?? '',
      appointmentDate: json['appointment_date']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString() ?? '',
      queuePosition: json['queue_position']?.toString() ?? '',
      timePosition: json['time_position']?.toString() ?? '',
      qrCode: json['qr_code']?.toString() ?? '',

      // Datos del perfil
      firstName: json['profile']['firstName']?.toString() ?? '',
      middleName: json['profile']['middleName']?.toString() ?? '',
      lastName: json['profile']['lastName']?.toString() ?? '',
      secondLastName: json['profile']['secondLastName']?.toString() ?? '',
      photoUser: json['profile']['photo_users']?.toString() ?? '',
      dateOfBirth: json['profile']['date_of_birth']?.toString() ?? '',
      maritalStatus: json['profile']['maritalStatus']?.toString() ?? '',
      sex: json['profile']['sex']?.toString() ?? '',
      profileStatus: json['profile']['status']?.toString() ?? '',
      stationId: json['profile']['station_id'] is int
          ? json['profile']['station_id']
          : int.tryParse(json['profile']['station_id'].toString()) ?? 0,

      operatorName: List<String>.from(
          (json['profile']['phones'] as List<dynamic>?)?.map((phone) =>
                  phone['operator_code']?['name']?.toString() ?? '') ??
              []),

      stationCode: json['station']?['code']?.toString() ?? '',

      // Datos del usuario
      userName: json['profile']['user']?['name']?.toString() ?? '',
      userEmail: json['profile']['user']?['email']?.toString() ?? '',
      userProfilePic: json['profile']['user']?['profile_pic']?.toString() ?? '',

      phoneNumbers: List<String>.from(
          (json['profile']['phones'] as List<dynamic>?)
                  ?.map((phone) => phone['number']?.toString() ?? '') ??
              []),

      emailAddresses: List<String>.from(
          (json['profile']['emails'] as List<dynamic>?)
                  ?.map((email) => email['email']?.toString() ?? '') ??
              []),

      documentNumberCi:
          numberCiList, // Almacenar los números de CI como un String (puedes cambiar a List si prefieres)
      documentImages: frontImageList,
      documentType: typeList,
      addresses: List<String>.from(
          (json['profile']['addresses'] as List<dynamic>?)
                  ?.map((address) => address['street']?.toString() ?? '') ??
              []),

      // Datos de bombonas de gas
      gasCylinderCode:
          json['gas_cylinder']?['gas_cylinder_code']?.toString() ?? '',
      cylinderQuantity:
          json['gas_cylinder']?['cylinder_quantity']?.toString() ?? '',
      cylinderType: json['gas_cylinder']?['cylinder_type']?.toString() ?? '',
      cylinderWeight:
          json['gas_cylinder']?['cylinder_weight']?.toString() ?? '',
      gasCylinderPhoto:
          json['gas_cylinder']?['photo_gas_cylinder']?.toString() ?? '',
      manufacturingDate:
          json['gas_cylinder']?['manufacturing_date']?.toString() ?? '',
    );
  }
}
