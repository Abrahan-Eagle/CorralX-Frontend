import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/profiles/models/profile.dart';
import 'package:zonix/profiles/models/ranch.dart';
import 'package:zonix/profiles/models/address.dart';

void main() {
  group('Profile Model', () {
    test('fromJson creates correct Profile instance', () {
      final json = {
        'id': 1,
        'user_id': 123,
        'firstName': 'Juan',
        'middleName': 'Carlos',
        'lastName': 'Pérez',
        'secondLastName': 'García',
        'photo_users': 'https://example.com/photo.jpg',
        'bio': 'Soy ganadero con 20 años de experiencia',
        'date_of_birth': '1990-01-15T00:00:00.000000Z',
        'maritalStatus': 'married',
        'sex': 'M',
        'status': 'verified',
        'is_verified': true,
        'rating': '4.5',
        'ratings_count': 10,
        'user_type': 'seller',
        'accepts_calls': true,
        'accepts_whatsapp': true,
        'accepts_emails': false,
        'whatsapp_number': '+58412123456',
        'ci_number': 'V-12345678',
        'created_at': '2024-01-01T00:00:00.000000Z',
        'updated_at': '2024-01-02T00:00:00.000000Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 1);
      expect(profile.userId, 123);
      expect(profile.firstName, 'Juan');
      expect(profile.middleName, 'Carlos');
      expect(profile.lastName, 'Pérez');
      expect(profile.secondLastName, 'García');
      expect(profile.photoUsers, 'https://example.com/photo.jpg');
      expect(profile.bio, 'Soy ganadero con 20 años de experiencia');
      expect(profile.dateOfBirth, isNotNull);
      expect(profile.maritalStatus, 'married');
      expect(profile.sex, 'M');
      expect(profile.status, 'verified');
      expect(profile.isVerified, true);
      expect(profile.rating, 4.5);
      expect(profile.ratingsCount, 10);
      expect(profile.userType, 'seller');
      expect(profile.acceptsCalls, true);
      expect(profile.acceptsWhatsapp, true);
      expect(profile.acceptsEmails, false);
      expect(profile.whatsappNumber, '+58412123456');
      expect(profile.ciNumber, 'V-12345678');
    });

    test('fromJson handles null values correctly', () {
      final json = {
        'id': 1,
        'user_id': 123,
        'firstName': 'Juan',
        'lastName': 'Pérez',
        'rating': '0.0',
        'ratings_count': 0,
        'user_type': 'buyer',
        'status': 'notverified',
        'is_verified': false,
        'created_at': '2024-01-01T00:00:00.000000Z',
        'updated_at': '2024-01-02T00:00:00.000000Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 1);
      expect(profile.middleName, null);
      expect(profile.secondLastName, null);
      expect(profile.photoUsers, null);
      expect(profile.bio, null);
      expect(profile.dateOfBirth, null);
      expect(profile.maritalStatus, null);
      expect(profile.sex, null);
      expect(profile.whatsappNumber, null);
    });

    test('fromJson parses ranches list correctly', () {
      final json = {
        'id': 1,
        'user_id': 123,
        'firstName': 'Juan',
        'lastName': 'Pérez',
        'rating': '0.0',
        'ratings_count': 0,
        'user_type': 'seller',
        'status': 'verified',
        'is_verified': true,
        'created_at': '2024-01-01T00:00:00.000000Z',
        'updated_at': '2024-01-02T00:00:00.000000Z',
        'ranches': [
          {
            'id': 1,
            'profile_id': 1,
            'name': 'Hacienda Test',
            'legal_name': 'Test Legal',
            'tax_id': 'J-123456',
            'is_primary': true,
            'avg_rating': '4.5',
            'total_sales': 10,
            'created_at': '2024-01-01T00:00:00.000000Z',
            'updated_at': '2024-01-02T00:00:00.000000Z',
          },
        ],
      };

      final profile = Profile.fromJson(json);

      expect(profile.ranches, isNotNull);
      expect(profile.ranches!.length, 1);
      expect(profile.ranches![0].name, 'Hacienda Test');
      expect(profile.ranches![0].isPrimary, true);
    });

    test('toJson creates correct map', () {
      final profile = Profile(
        id: 1,
        userId: 123,
        firstName: 'Juan',
        middleName: 'Carlos',
        lastName: 'Pérez',
        secondLastName: 'García',
        photoUsers: 'https://example.com/photo.jpg',
        bio: 'Mi biografía',
        rating: 4.5,
        ratingsCount: 10,
        userType: 'seller',
        status: 'verified',
        isVerified: true,
        hasUnreadMessages: false,
        isBothVerified: false,
        isPremiumSeller: false,
        acceptsCalls: true,
        acceptsWhatsapp: false,
        acceptsEmails: true,
        ciNumber: 'V-123456',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = profile.toJson();

      expect(json['id'], 1);
      expect(json['user_id'], 123);
      expect(json['firstName'], 'Juan');
      expect(json['middleName'], 'Carlos');
      expect(json['lastName'], 'Pérez');
      expect(json['bio'], 'Mi biografía');
      expect(json['rating'], 4.5);
      expect(json['user_type'], 'seller');
    });

    test('copyWith updates specified fields only', () {
      final original = Profile(
        id: 1,
        userId: 123,
        firstName: 'Juan',
        lastName: 'Pérez',
        bio: 'Bio original',
        rating: 4.0,
        ratingsCount: 5,
        userType: 'seller',
        status: 'verified',
        isVerified: true,
        hasUnreadMessages: false,
        isBothVerified: false,
        isPremiumSeller: false,
        acceptsCalls: true,
        acceptsWhatsapp: true,
        acceptsEmails: true,
        ciNumber: 'V-123456',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final updated = original.copyWith(
        firstName: 'Pedro',
        bio: 'Bio actualizada',
      );

      expect(updated.id, 1); // Sin cambios
      expect(updated.userId, 123); // Sin cambios
      expect(updated.firstName, 'Pedro'); // Actualizado
      expect(updated.lastName, 'Pérez'); // Sin cambios
      expect(updated.bio, 'Bio actualizada'); // Actualizado
      expect(updated.rating, 4.0); // Sin cambios
    });

    test('fullName returns correct concatenation', () {
      final profile = Profile(
        id: 1,
        userId: 123,
        firstName: 'Juan',
        middleName: 'Carlos',
        lastName: 'Pérez',
        secondLastName: 'García',
        rating: 0.0,
        ratingsCount: 0,
        userType: 'buyer',
        status: 'notverified',
        isVerified: false,
        hasUnreadMessages: false,
        isBothVerified: false,
        isPremiumSeller: false,
        acceptsCalls: true,
        acceptsWhatsapp: true,
        acceptsEmails: true,
        ciNumber: 'V-123456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.fullName, 'Juan Carlos Pérez García');
    });

    test('fullName handles missing middle and second last names', () {
      final profile = Profile(
        id: 1,
        userId: 123,
        firstName: 'Juan',
        lastName: 'Pérez',
        rating: 0.0,
        ratingsCount: 0,
        userType: 'buyer',
        status: 'notverified',
        isVerified: false,
        hasUnreadMessages: false,
        isBothVerified: false,
        isPremiumSeller: false,
        acceptsCalls: true,
        acceptsWhatsapp: true,
        acceptsEmails: true,
        ciNumber: 'V-123456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.fullName, 'Juan Pérez');
    });
  });
}

