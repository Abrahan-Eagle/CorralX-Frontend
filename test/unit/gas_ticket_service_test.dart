import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zonix/features/GasTicket/gas_button/api/gas_ticket_service.dart';
import 'package:zonix/features/GasTicket/gas_button/models/gas_ticket.dart';

import 'gas_ticket_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('GasTicketService Tests', () {
    late GasTicketService service;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      service = GasTicketService();
    });

    test('should fetch gas tickets successfully', () async {
      // Arrange
      final mockResponse = '''
      {
        "success": true,
        "data": [
          {
            "id": 1,
            "profile_id": 123,
            "gas_cylinders_id": 456,
            "station_id": 789,
            "queue_position": 5,
            "time_position": "09:30:00",
            "qr_code": "QR123456",
            "reserved_date": "2024-01-15",
            "appointment_date": "2024-01-16",
            "expiry_date": "2024-01-18",
            "status": "pending",
            "profile": {
              "id": 123,
              "firstName": "John",
              "middleName": "",
              "lastName": "Doe",
              "secondLastName": "",
              "photo_users": "",
              "date_of_birth": "1990-01-01",
              "maritalStatus": "single",
              "sex": "M",
              "status": "completeData",
              "station_id": 789,
              "station": {"code": "ST001"},
              "user": {
                "name": "John Doe",
                "email": "john@example.com",
                "profile_pic": ""
              },
              "phones": [],
              "emails": [],
              "documents": [],
              "addresses": []
            },
            "gas_cylinder": {
              "gas_cylinder_code": "GC001",
              "cylinder_quantity": "1",
              "cylinder_type": "small",
              "cylinder_weight": "10kg",
              "gas_cylinder_photo": "",
              "manufacturing_date": "2023-01-01"
            },
            "operator_name": []
          }
        ]
      }
      ''';

      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(mockResponse, 200));

      // Act
      final result = await service.getGasTickets('test_token');

      // Assert
      expect(result, isA<List<GasTicket>>());
      expect(result.length, equals(1));
      expect(result.first.id, equals(1));
      expect(result.first.status, equals('pending'));
    });

    test('should handle API error response', () async {
      // Arrange
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer(
          (_) async => http.Response('{"error": "Unauthorized"}', 401));

      // Act & Assert
      expect(
        () => service.getGasTickets('invalid_token'),
        throwsA(isA<Exception>()),
      );
    });

    test('should create gas ticket successfully', () async {
      // Arrange
      final mockResponse = '''
      {
        "success": true,
        "message": "Ticket creado exitosamente",
        "data": {
          "id": 1,
          "profile_id": 123,
          "gas_cylinders_id": 456,
          "status": "pending"
        }
      }
      ''';

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(mockResponse, 201));

      final ticketData = {
        'profile_id': 123,
        'gas_cylinders_id': 456,
        'is_external': false,
      };

      // Act
      final result = await service.createGasTicket(ticketData, 'test_token');

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['success'], isTrue);
      expect(result['message'], equals('Ticket creado exitosamente'));
    });

    test('should handle network error', () async {
      // Arrange
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => service.getGasTickets('test_token'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
