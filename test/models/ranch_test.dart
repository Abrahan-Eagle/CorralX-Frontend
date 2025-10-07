import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/profiles/models/ranch.dart';
import 'package:zonix/profiles/models/address.dart';

void main() {
  group('Ranch Model', () {
    test('fromJson creates correct Ranch instance', () {
      final json = {
        'id': 1,
        'profile_id': 123,
        'name': 'Hacienda El Paraíso',
        'legal_name': 'Agropecuaria El Paraíso C.A.',
        'tax_id': 'J-123456789-0',
        'business_description': 'Producción de ganado lechero',
        'contact_hours': 'Lunes a Viernes 8am - 5pm',
        'address_id': 456,
        'is_primary': true,
        'delivery_policy': 'Entrega en 48 horas',
        'return_policy': 'Garantía de 30 días',
        'avg_rating': '4.5',
        'total_sales': 25,
        'last_sale_at': '2024-01-15T00:00:00.000000Z',
        'created_at': '2024-01-01T00:00:00.000000Z',
        'updated_at': '2024-01-02T00:00:00.000000Z',
      };

      final ranch = Ranch.fromJson(json);

      expect(ranch.id, 1);
      expect(ranch.profileId, 123);
      expect(ranch.name, 'Hacienda El Paraíso');
      expect(ranch.legalName, 'Agropecuaria El Paraíso C.A.');
      expect(ranch.taxId, 'J-123456789-0');
      expect(ranch.businessDescription, 'Producción de ganado lechero');
      expect(ranch.contactHours, 'Lunes a Viernes 8am - 5pm');
      expect(ranch.addressId, 456);
      expect(ranch.isPrimary, true);
      expect(ranch.deliveryPolicy, 'Entrega en 48 horas');
      expect(ranch.returnPolicy, 'Garantía de 30 días');
      expect(ranch.avgRating, 4.5);
      expect(ranch.totalSales, 25);
      expect(ranch.lastSaleAt, isNotNull);
      expect(ranch.createdAt, isNotNull);
      expect(ranch.updatedAt, isNotNull);
    });

    test('fromJson handles null values correctly', () {
      final json = {
        'id': 1,
        'profile_id': 123,
        'name': 'Hacienda Test',
        'is_primary': false,
        'avg_rating': '0.0',
        'total_sales': 0,
        'created_at': '2024-01-01T00:00:00.000000Z',
        'updated_at': '2024-01-02T00:00:00.000000Z',
      };

      final ranch = Ranch.fromJson(json);

      expect(ranch.legalName, null);
      expect(ranch.taxId, null);
      expect(ranch.businessDescription, null);
      expect(ranch.contactHours, null);
      expect(ranch.addressId, null);
      expect(ranch.deliveryPolicy, null);
      expect(ranch.returnPolicy, null);
      expect(ranch.lastSaleAt, null);
      expect(ranch.address, null);
    });

    test('fromJson parses address relationship', () {
      final json = {
        'id': 1,
        'profile_id': 123,
        'name': 'Hacienda Test',
        'is_primary': true,
        'avg_rating': '0.0',
        'total_sales': 0,
        'created_at': '2024-01-01T00:00:00.000000Z',
        'updated_at': '2024-01-02T00:00:00.000000Z',
        'address': {
          'id': 456,
          'adressses': 'Calle Principal 123',
          'status': 'verified',
          'profile_id': 123,
          'city_id': 789,
        },
      };

      final ranch = Ranch.fromJson(json);

      expect(ranch.address, isNotNull);
      expect(ranch.address!.id, 456);
      expect(ranch.address!.addresses, 'Calle Principal 123');
    });

    test('fromJson parses boolean values correctly', () {
      // Test con booleano verdadero
      final json1 = {
        'id': 1,
        'profile_id': 123,
        'name': 'Test',
        'is_primary': true,
        'avg_rating': '0.0',
        'total_sales': 0,
        'created_at': '2024-01-01T00:00:00.000000Z',
        'updated_at': '2024-01-02T00:00:00.000000Z',
      };

      final ranch1 = Ranch.fromJson(json1);
      expect(ranch1.isPrimary, true);

      // Test con entero 1
      final json2 = {...json1, 'is_primary': 1};
      final ranch2 = Ranch.fromJson(json2);
      expect(ranch2.isPrimary, true);

      // Test con string "true"
      final json3 = {...json1, 'is_primary': 'true'};
      final ranch3 = Ranch.fromJson(json3);
      expect(ranch3.isPrimary, true);

      // Test con false
      final json4 = {...json1, 'is_primary': false};
      final ranch4 = Ranch.fromJson(json4);
      expect(ranch4.isPrimary, false);
    });

    test('fromJson parses numeric values correctly', () {
      // Test con double
      final json1 = {
        'id': 1,
        'profile_id': 123,
        'name': 'Test',
        'is_primary': false,
        'avg_rating': 4.5,
        'total_sales': 25,
        'created_at': '2024-01-01T00:00:00.000000Z',
        'updated_at': '2024-01-02T00:00:00.000000Z',
      };

      final ranch1 = Ranch.fromJson(json1);
      expect(ranch1.avgRating, 4.5);
      expect(ranch1.totalSales, 25);

      // Test con string
      final json2 = {
        ...json1,
        'avg_rating': '4.5',
        'total_sales': '25',
      };

      final ranch2 = Ranch.fromJson(json2);
      expect(ranch2.avgRating, 4.5);
      expect(ranch2.totalSales, 25);

      // Test con integer para double
      final json3 = {
        ...json1,
        'avg_rating': 4,
      };

      final ranch3 = Ranch.fromJson(json3);
      expect(ranch3.avgRating, 4.0);
    });

    test('toJson creates correct map', () {
      final ranch = Ranch(
        id: 1,
        profileId: 123,
        name: 'Hacienda Test',
        legalName: 'Test Legal',
        taxId: 'J-123456',
        businessDescription: 'Descripción',
        contactHours: '8am - 5pm',
        addressId: 456,
        isPrimary: true,
        deliveryPolicy: 'Entrega rápida',
        returnPolicy: 'Garantía',
        avgRating: 4.5,
        totalSales: 25,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = ranch.toJson();

      expect(json['id'], 1);
      expect(json['profile_id'], 123);
      expect(json['name'], 'Hacienda Test');
      expect(json['legal_name'], 'Test Legal');
      expect(json['tax_id'], 'J-123456');
      expect(json['is_primary'], true);
      expect(json['avg_rating'], 4.5);
      expect(json['total_sales'], 25);
    });
  });
}

