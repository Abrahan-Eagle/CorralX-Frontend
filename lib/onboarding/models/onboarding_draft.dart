class PersonalInfoDraft {
  PersonalInfoDraft({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirthIso,
    required this.ciNumber,
    required this.operatorCodeId,
    required this.operatorCode,
    required this.phoneNumber,
    required this.address,
    required this.cityId,
    required this.latitude,
    required this.longitude,
    this.middleName,
    this.secondLastName,
    this.countryName,
    this.stateName,
    this.cityName,
  });

  final String firstName;
  final String? middleName;
  final String lastName;
  final String? secondLastName;
  final String dateOfBirthIso;
  final String ciNumber;
  final int operatorCodeId;
  final String operatorCode;
  final String phoneNumber;
  final String address;
  final int cityId;
  final double latitude;
  final double longitude;
  final String? countryName;
  final String? stateName;
  final String? cityName;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'secondLastName': secondLastName,
        'dateOfBirthIso': dateOfBirthIso,
        'ciNumber': ciNumber,
        'operatorCodeId': operatorCodeId,
        'operatorCode': operatorCode,
        'phoneNumber': phoneNumber,
        'address': address,
        'cityId': cityId,
        'latitude': latitude,
        'longitude': longitude,
        'countryName': countryName,
        'stateName': stateName,
        'cityName': cityName,
      };

  factory PersonalInfoDraft.fromJson(Map<String, dynamic> json) =>
      PersonalInfoDraft(
        firstName: json['firstName'] as String,
        middleName: json['middleName'] as String?,
        lastName: json['lastName'] as String,
        secondLastName: json['secondLastName'] as String?,
        dateOfBirthIso: json['dateOfBirthIso'] as String,
        ciNumber: json['ciNumber'] as String,
        operatorCodeId: json['operatorCodeId'] as int,
        operatorCode: json['operatorCode'] as String,
        phoneNumber: json['phoneNumber'] as String,
        address: json['address'] as String,
        cityId: json['cityId'] as int,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        countryName: json['countryName'] as String?,
        stateName: json['stateName'] as String?,
        cityName: json['cityName'] as String?,
      );
}

class RanchInfoDraft {
  RanchInfoDraft({
    required this.name,
    required this.legalName,
    required this.rif,
    required this.description,
    this.contactHours,
  });

  final String name;
  final String legalName;
  final String rif;
  final String description;
  final String? contactHours;

  Map<String, dynamic> toJson() => {
        'name': name,
        'legalName': legalName,
        'rif': rif,
        'description': description,
        'contactHours': contactHours,
      };

  factory RanchInfoDraft.fromJson(Map<String, dynamic> json) =>
      RanchInfoDraft(
        name: json['name'] as String,
        legalName: json['legalName'] as String,
        rif: json['rif'] as String,
        description: json['description'] as String,
        contactHours: json['contactHours'] as String?,
      );
}

