import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/GasTicket/gas_button/models/gas_ticket.dart';

void main() {
  group('GasTicket Model Tests', () {
    test('should create GasTicket from JSON', () {
      final json = {
        'id': 1,
        'profile_id': 123,
        'gas_cylinders_id': 456,
        'station_id': 789,
        'queue_position': 5,
        'time_position': '09:30:00',
        'qr_code': 'QR123456',
        'reserved_date': '2024-01-15',
        'appointment_date': '2024-01-16',
        'expiry_date': '2024-01-18',
        'status': 'pending',
        'profile': {
          'id': 123,
          'firstName': 'John',
          'middleName': 'Michael',
          'lastName': 'Doe',
          'secondLastName': 'Smith',
          'photo_users': 'photo.jpg',
          'date_of_birth': '1990-01-01',
          'maritalStatus': 'single',
          'sex': 'M',
          'status': 'completeData',
          'station_id': 789,
          'station': {'code': 'ST001'},
          'user': {
            'name': 'John Doe',
            'email': 'john@example.com',
            'profile_pic': 'profile.jpg'
          },
          'phones': [
            {'phone_number': '123456789'}
          ],
          'emails': [
            {'email': 'john@example.com'}
          ],
          'documents': [
            {
              'type': 'ci',
              'front_image': 'ci_front.jpg',
              'document_number': '12345678'
            }
          ],
          'addresses': [
            {'address': '123 Main St'}
          ]
        },
        'gas_cylinder': {
          'gas_cylinder_code': 'GC001',
          'cylinder_quantity': '1',
          'cylinder_type': 'small',
          'cylinder_weight': '10kg',
          'gas_cylinder_photo': 'cylinder.jpg',
          'manufacturing_date': '2023-01-01'
        },
        'operator_name': ['Operator 1', 'Operator 2']
      };

      final gasTicket = GasTicket.fromJson(json);

      expect(gasTicket.id, equals(1));
      expect(gasTicket.profileId, equals(123));
      expect(gasTicket.gasCylindersId, equals(456));
      expect(gasTicket.stationId, equals(789));
      expect(gasTicket.queuePosition, equals('5'));
      expect(gasTicket.timePosition, equals('09:30:00'));
      expect(gasTicket.qrCode, equals('QR123456'));
      expect(gasTicket.reservedDate, equals('2024-01-15'));
      expect(gasTicket.appointmentDate, equals('2024-01-16'));
      expect(gasTicket.expiryDate, equals('2024-01-18'));
      expect(gasTicket.status, equals('pending'));
      expect(gasTicket.firstName, equals('John'));
      expect(gasTicket.lastName, equals('Doe'));
    });

    test('should handle null values in JSON', () {
      final json = {
        'id': 1,
        'profile_id': null,
        'gas_cylinders_id': null,
        'station_id': null,
        'queue_position': null,
        'time_position': null,
        'qr_code': null,
        'reserved_date': null,
        'appointment_date': null,
        'expiry_date': null,
        'status': 'pending',
        'profile': {
          'id': 123,
          'firstName': 'John',
          'middleName': '',
          'lastName': 'Doe',
          'secondLastName': '',
          'photo_users': '',
          'date_of_birth': '1990-01-01',
          'maritalStatus': 'single',
          'sex': 'M',
          'status': 'completeData',
          'station_id': null,
          'station': {'code': ''},
          'user': {
            'name': 'John Doe',
            'email': 'john@example.com',
            'profile_pic': ''
          },
          'phones': [],
          'emails': [],
          'documents': [],
          'addresses': []
        },
        'gas_cylinder': {
          'gas_cylinder_code': '',
          'cylinder_quantity': '',
          'cylinder_type': '',
          'cylinder_weight': '',
          'gas_cylinder_photo': '',
          'manufacturing_date': ''
        },
        'operator_name': []
      };

      final gasTicket = GasTicket.fromJson(json);

      expect(gasTicket.id, equals(1));
      expect(gasTicket.profileId, equals(0));
      expect(gasTicket.gasCylindersId, equals(0));
      expect(gasTicket.stationId, equals(0));
      expect(gasTicket.queuePosition, equals(''));
      expect(gasTicket.timePosition, equals(''));
      expect(gasTicket.qrCode, equals(''));
      expect(gasTicket.reservedDate, equals(''));
      expect(gasTicket.appointmentDate, equals(''));
      expect(gasTicket.expiryDate, equals(''));
      expect(gasTicket.status, equals('pending'));
    });

    test('should check ticket status correctly', () {
      final pendingTicket = GasTicket(
        id: 1,
        profileId: 123,
        gasCylindersId: 456,
        status: 'pending',
        reservedDate: '2024-01-15',
        appointmentDate: '2024-01-16',
        expiryDate: '2024-01-18',
        queuePosition: '5',
        timePosition: '09:30:00',
        qrCode: 'QR123456',
        firstName: 'John',
        middleName: '',
        lastName: 'Doe',
        secondLastName: '',
        photoUser: '',
        dateOfBirth: '1990-01-01',
        maritalStatus: 'single',
        sex: 'M',
        profileStatus: 'completeData',
        userName: 'John Doe',
        userEmail: 'john@example.com',
        userProfilePic: '',
        phoneNumbers: [],
        emailAddresses: [],
        documentImages: [],
        documentType: [],
        documentNumberCi: [],
        addresses: [],
        gasCylinderCode: '',
        cylinderQuantity: '',
        cylinderType: '',
        cylinderWeight: '',
        gasCylinderPhoto: '',
        manufacturingDate: '',
        stationId: 789,
        operatorName: [],
        stationCode: '',
      );

      final dispatchedTicket = GasTicket(
        id: 2,
        profileId: 123,
        gasCylindersId: 456,
        status: 'dispatched',
        reservedDate: '2024-01-15',
        appointmentDate: '2024-01-16',
        expiryDate: '2024-01-18',
        queuePosition: '5',
        timePosition: '09:30:00',
        qrCode: 'QR123456',
        firstName: 'John',
        middleName: '',
        lastName: 'Doe',
        secondLastName: '',
        photoUser: '',
        dateOfBirth: '1990-01-01',
        maritalStatus: 'single',
        sex: 'M',
        profileStatus: 'completeData',
        userName: 'John Doe',
        userEmail: 'john@example.com',
        userProfilePic: '',
        phoneNumbers: [],
        emailAddresses: [],
        documentImages: [],
        documentType: [],
        documentNumberCi: [],
        addresses: [],
        gasCylinderCode: '',
        cylinderQuantity: '',
        cylinderType: '',
        cylinderWeight: '',
        gasCylinderPhoto: '',
        manufacturingDate: '',
        stationId: 789,
        operatorName: [],
        stationCode: '',
      );

      expect(pendingTicket.status, equals('pending'));
      expect(dispatchedTicket.status, equals('dispatched'));
    });
  });
}
