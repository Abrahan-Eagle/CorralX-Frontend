class GasCylinder {
  final String gasCylinderCode;
  final int? cylinderQuantity;
  final String? cylinderType;
  final String? cylinderWeight;
  final DateTime? manufacturingDate;
  final bool approved;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? companySupplierId;
  final String? photoGasCylinder; // Nuevo campo agregado

  GasCylinder({
    required this.gasCylinderCode,
    this.cylinderQuantity,
    this.cylinderType,
    this.cylinderWeight,
    this.manufacturingDate,
    this.approved = false,
    this.createdAt,
    this.updatedAt,
    this.companySupplierId,
    this.photoGasCylinder, // Inicialización del nuevo campo
  });

  // Método para crear una instancia desde JSON
  factory GasCylinder.fromJson(Map<String, dynamic> json) {
    return GasCylinder(
      gasCylinderCode: (json['gas_cylinder_code'] ?? '').toString(),
      cylinderQuantity: json['cylinder_quantity'] is int
          ? json['cylinder_quantity']
          : int.tryParse(json['cylinder_quantity']?.toString() ?? ''),
      cylinderType: json['cylinder_type']?.toString(),
      cylinderWeight: json['cylinder_weight']?.toString(),
      manufacturingDate: json['manufacturing_date'] != null
          ? DateTime.tryParse(json['manufacturing_date'].toString())
          : null,
      approved: json['approved'] is bool
          ? json['approved']
          : (int.tryParse(json['approved']?.toString() ?? '') ?? 0) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      companySupplierId: json['company_supplier_id'] is int
          ? json['company_supplier_id']
          : int.tryParse(json['company_supplier_id']?.toString() ?? ''),
      photoGasCylinder: json['photo_gas_cylinder']?.toString(),
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'gas_cylinder_code': gasCylinderCode,
      'cylinder_quantity': cylinderQuantity,
      'cylinder_type': cylinderType,
      'cylinder_weight': cylinderWeight,
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'approved': approved ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'company_supplier_id': companySupplierId,
      'photo_gas_cylinder': photoGasCylinder, // Conversión del nuevo campo
    };
  }
}
