import 'package:flutter_test/flutter_test.dart';
import 'package:corralx/profiles/models/address.dart';

void main() {
  group('Address Model', () {
    test('fromJson creates correct Address instance', () {
      final json = {
        'id': 1,
        'adressses': 'Av. Principal 123, Valencia',
        'latitude': 10.1234,
        'longitude': -68.5678,
        'status': 'verified',
        'profile_id': 456,
        'city_id': 789,
        'city': {
          'name': 'Valencia',
        },
        'state': {
          'name': 'Carabobo',
        },
      };

      final address = Address.fromJson(json);

      expect(address.id, 1);
      expect(address.addresses, 'Av. Principal 123, Valencia');
      expect(address.latitude, 10.1234);
      expect(address.longitude, -68.5678);
      expect(address.status, 'verified');
      expect(address.profileId, 456);
      expect(address.cityId, 789);
      expect(address.cityName, 'Valencia');
      expect(address.stateName, 'Carabobo');
      expect(address.countryName, null); // countryName no se parsea en Address
    });

    test('fromJson handles null coordinates', () {
      final json = {
        'id': 1,
        'adressses': 'Dirección test',
        'status': 'notverified',
        'profile_id': 456,
        'city_id': 789,
      };

      final address = Address.fromJson(json);

      expect(address.latitude, null);
      expect(address.longitude, null);
      expect(address.cityName, null);
      expect(address.stateName, null);
      expect(address.countryName, null);
    });

    test('formattedLocation creates correct string', () {
      final address = Address(
        id: 1,
        addresses: 'Calle Test',
        status: 'verified',
        profileId: 456,
        cityId: 789,
        cityName: 'Valencia',
        stateName: 'Carabobo',
      );

      expect(address.formattedLocation, 'Valencia, Carabobo');
    });

    test('formattedLocation handles missing parts', () {
      final address1 = Address(
        id: 1,
        addresses: 'Calle Test',
        status: 'verified',
        profileId: 456,
        cityId: 789,
        cityName: 'Valencia',
        stateName: 'Carabobo',
      );

      expect(address1.formattedLocation, 'Valencia, Carabobo');

      final address2 = Address(
        id: 1,
        addresses: 'Calle Test',
        status: 'verified',
        profileId: 456,
        cityId: 789,
        cityName: 'Valencia',
      );

      expect(address2.formattedLocation, 'Valencia');
    });

    test('formattedLocation returns default when no location data', () {
      final address = Address(
        id: 1,
        addresses: 'Calle Test',
        status: 'verified',
        profileId: 456,
        cityId: 789,
      );

      expect(address.formattedLocation, 'Ubicación no disponible');
    });

    test('fromJson parses numeric values correctly', () {
      // Test con doubles
      final json1 = {
        'id': 1,
        'adressses': 'Test',
        'latitude': 10.5,
        'longitude': -68.5,
        'status': 'verified',
        'profile_id': 456,
        'city_id': 789,
      };

      final address1 = Address.fromJson(json1);
      expect(address1.latitude, 10.5);
      expect(address1.longitude, -68.5);

      // Test con strings
      final json2 = {
        ...json1,
        'latitude': '10.5',
        'longitude': '-68.5',
      };

      final address2 = Address.fromJson(json2);
      expect(address2.latitude, 10.5);
      expect(address2.longitude, -68.5);

      // Test con integers
      final json3 = {
        ...json1,
        'latitude': 10,
        'longitude': -68,
      };

      final address3 = Address.fromJson(json3);
      expect(address3.latitude, 10.0);
      expect(address3.longitude, -68.0);
    });

    test('toJson creates correct map', () {
      final address = Address(
        id: 1,
        addresses: 'Av. Principal 123',
        latitude: 10.1234,
        longitude: -68.5678,
        status: 'verified',
        profileId: 456,
        cityId: 789,
        cityName: 'Valencia',
        stateName: 'Carabobo',
        countryName: 'Venezuela',
      );

      final json = address.toJson();

      expect(json['id'], 1);
      expect(json['adressses'], 'Av. Principal 123');
      expect(json['latitude'], 10.1234);
      expect(json['longitude'], -68.5678);
      expect(json['status'], 'verified');
      expect(json['profile_id'], 456);
      expect(json['city_id'], 789);
      // Los nombres SÍ se incluyen en toJson cuando no son null
      expect(json['city_name'], 'Valencia');
      expect(json['state_name'], 'Carabobo');
      expect(json['country_name'], 'Venezuela');
    });
  });
}

