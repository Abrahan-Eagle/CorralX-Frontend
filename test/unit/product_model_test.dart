import 'package:flutter_test/flutter_test.dart';
import 'package:corralx/products/models/product.dart';

void main() {
  group('Product Model Tests', () {
    late Map<String, dynamic> sampleProductJson;
    late Map<String, dynamic> sampleRanchJson;
    late Map<String, dynamic> sampleImageJson;

    setUp(() {
      sampleRanchJson = {
        'id': 1,
        'name': 'Rancho El Futuro',
        'legal_name': 'Agropecuaria El Futuro C.A.',
        'description': 'Especialistas en ganado lechero',
        'specialization': 'lechero',
        'avg_rating': 4.5,
        'total_sales': 150,
        'last_sale_at': '2024-01-15T10:30:00Z',
      };

      sampleImageJson = {
        'id': 1,
        'file_url': 'https://example.com/image1.jpg',
        'file_type': 'image',
        'is_primary': true,
        'sort_order': 1,
        'duration': null,
        'resolution': '1920x1080',
        'format': 'JPEG',
        'file_size': 2048576,
      };

      sampleProductJson = {
        'id': 1,
        'title': 'Vacas Holstein de Alta Producción',
        'description': 'Excelente ganado lechero con certificados de salud',
        'type': 'lechero',
        'breed': 'Holstein',
        'age': 24,
        'quantity': 5,
        'price': 1500.0,
        'currency': 'USD',
        'weight_avg': 650.0,
        'weight_min': 600.0,
        'weight_max': 700.0,
        'sex': 'female',
        'purpose': 'dairy',
        'health_certificate_url': 'https://example.com/cert.pdf',
        'vaccines_applied': 'Fiebre aftosa, Brucelosis',
        'documentation_included': true,
        'genetic_test_results': 'Excelente línea genética',
        'is_vaccinated': true,
        'delivery_method': 'pickup',
        'delivery_cost': 0.0,
        'delivery_radius_km': 50.0,
        'negotiable': true,
        'status': 'active',
        'views_count': 125,
        'created_at': '2024-01-10T08:00:00Z',
        'updated_at': '2024-01-15T14:30:00Z',
        'ranch_id': 1,
        'ranch': sampleRanchJson,
        'images': [sampleImageJson],
      };
    });

    group('Product.fromJson', () {
      test('should create Product from valid JSON', () {
        final product = Product.fromJson(sampleProductJson);

        expect(product.id, equals(1));
        expect(product.title, equals('Vacas Holstein de Alta Producción'));
        expect(product.description,
            equals('Excelente ganado lechero con certificados de salud'));
        expect(product.type, equals('lechero'));
        expect(product.breed, equals('Holstein'));
        expect(product.age, equals(24));
        expect(product.quantity, equals(5));
        expect(product.price, equals(1500.0));
        expect(product.currency, equals('USD'));
        expect(product.weightAvg, equals(650.0));
        expect(product.weightMin, equals(600.0));
        expect(product.weightMax, equals(700.0));
        expect(product.sex, equals('female'));
        expect(product.purpose, equals('dairy'));
        expect(product.healthCertificateUrl,
            equals('https://example.com/cert.pdf'));
        expect(product.vaccinesApplied, equals('Fiebre aftosa, Brucelosis'));
        expect(product.documentationIncluded, equals(true));
        expect(product.geneticTestResults, equals('Excelente línea genética'));
        expect(product.isVaccinated, equals(true));
        expect(product.deliveryMethod, equals('pickup'));
        expect(product.deliveryCost, equals(0.0));
        expect(product.deliveryRadiusKm, equals(50.0));
        expect(product.negotiable, equals(true));
        expect(product.status, equals('active'));
        expect(product.viewsCount, equals(125));
        expect(product.ranchId, equals(1));
        expect(product.ranch, isNotNull);
        expect(product.images, hasLength(1));
      });

      test('should handle null values in JSON', () {
        final jsonWithNulls = {
          'id': 1,
          'title': 'Test Product',
          'description': 'Test Description',
          'type': 'engorde',
          'breed': 'Brahman',
          'age': 12,
          'quantity': 1,
          'price': 800.0,
          'currency': 'USD',
          'weight_avg': null,
          'weight_min': null,
          'weight_max': null,
          'sex': null,
          'purpose': null,
          'health_certificate_url': null,
          'vaccines_applied': null,
          'documentation_included': null,
          'genetic_test_results': null,
          'is_vaccinated': null,
          'delivery_method': 'pickup',
          'delivery_cost': null,
          'delivery_radius_km': null,
          'negotiable': false,
          'status': 'active',
          'views_count': 0,
          'created_at': '2024-01-10T08:00:00Z',
          'updated_at': '2024-01-10T08:00:00Z',
          'ranch_id': 1,
          'ranch': null,
          'images': [],
        };

        final product = Product.fromJson(jsonWithNulls);

        expect(product.weightAvg, isNull);
        expect(product.weightMin, isNull);
        expect(product.weightMax, isNull);
        expect(product.sex, isNull);
        expect(product.purpose, isNull);
        expect(product.healthCertificateUrl, isNull);
        expect(product.vaccinesApplied, isNull);
        expect(product.documentationIncluded, isNull);
        expect(product.geneticTestResults, isNull);
        expect(product.isVaccinated, isNull);
        expect(product.deliveryCost, isNull);
        expect(product.deliveryRadiusKm, isNull);
        expect(product.ranch, isNull);
        expect(product.images, isEmpty);
      });

      test('should handle string numbers in JSON', () {
        final jsonWithStringNumbers = {
          'id': '1',
          'title': 'Test Product',
          'description': 'Test Description',
          'type': 'engorde',
          'breed': 'Brahman',
          'age': '12',
          'quantity': '3',
          'price': '800.50',
          'currency': 'USD',
          'weight_avg': '650.25',
          'views_count': '50',
          'ranch_id': '1',
          'delivery_method': 'pickup',
          'negotiable': 'true',
          'status': 'active',
          'created_at': '2024-01-10T08:00:00Z',
          'updated_at': '2024-01-10T08:00:00Z',
          'ranch': null,
          'images': [],
        };

        final product = Product.fromJson(jsonWithStringNumbers);

        expect(product.id, equals(1));
        expect(product.age, equals(12));
        expect(product.quantity, equals(3));
        expect(product.price, equals(800.50));
        expect(product.weightAvg, equals(650.25));
        expect(product.viewsCount, equals(50));
        expect(product.ranchId, equals(1));
        expect(product.negotiable, equals(true));
      });
    });

    group('Product.toJson', () {
      test('should convert Product to JSON', () {
        final product = Product.fromJson(sampleProductJson);
        final json = product.toJson();

        expect(json['id'], equals(1));
        expect(json['title'], equals('Vacas Holstein de Alta Producción'));
        expect(json['type'], equals('lechero'));
        expect(json['price'], equals(1500.0));
        expect(json['ranch_id'], equals(1));
        expect(json['ranch'], isNotNull);
        expect(json['images'], hasLength(1));
      });
    });

    group('Product Helper Methods', () {
      late Product product;

      setUp(() {
        product = Product.fromJson(sampleProductJson);
      });

      test('formattedPrice should format USD correctly', () {
        expect(product.formattedPrice, equals('\$ 1500'));
      });

      test('formattedPrice should format VES correctly', () {
        final vesProduct = Product.fromJson({
          ...sampleProductJson,
          'currency': 'VES',
          'price': 2500.0,
        });
        expect(vesProduct.formattedPrice, equals('Bs 2500'));
      });

      test('formattedWeight should format weight correctly', () {
        expect(product.formattedWeight, equals('650 kg promedio'));
      });

      test('formattedWeight should handle null weight', () {
        final productWithoutWeight = Product.fromJson({
          ...sampleProductJson,
          'weight_avg': null,
        });
        expect(productWithoutWeight.formattedWeight,
            equals('Peso no especificado'));
      });

      test('isAvailable should return true for active status', () {
        expect(product.isAvailable, isTrue);
      });

      test('isAvailable should return false for non-active status', () {
        final soldProduct = Product.fromJson({
          ...sampleProductJson,
          'status': 'sold',
        });
        expect(soldProduct.isAvailable, isFalse);
      });

      test('typeDisplayName should return correct display names', () {
        final testCases = [
          {'type': 'engorde', 'expected': 'Engorde'},
          {'type': 'lechero', 'expected': 'Lechero'},
          {'type': 'padrote', 'expected': 'Padrote'},
          {'type': 'equipment', 'expected': 'Equipos'},
          {'type': 'feed', 'expected': 'Alimentos'},
          {'type': 'unknown', 'expected': 'Otros'},
        ];

        for (final testCase in testCases) {
          final testProduct = Product.fromJson({
            ...sampleProductJson,
            'type': testCase['type'],
          });
          expect(testProduct.typeDisplayName, equals(testCase['expected']));
        }
      });

      test('sexDisplayName should return correct display names', () {
        final testCases = [
          {'sex': 'male', 'expected': 'Macho'},
          {'sex': 'female', 'expected': 'Hembra'},
          {'sex': 'mixed', 'expected': 'Mixto'},
          {'sex': null, 'expected': 'No especificado'},
          {'sex': 'unknown', 'expected': 'No especificado'},
        ];

        for (final testCase in testCases) {
          final testProduct = Product.fromJson({
            ...sampleProductJson,
            'sex': testCase['sex'],
          });
          expect(testProduct.sexDisplayName, equals(testCase['expected']));
        }
      });
    });

    group('ProductImage Model', () {
      test('should create ProductImage from JSON', () {
        final image = ProductImage.fromJson(sampleImageJson);

        expect(image.id, equals(1));
        expect(image.fileUrl, equals('https://example.com/image1.jpg'));
        expect(image.fileType, equals('image'));
        expect(image.isPrimary, isTrue);
        expect(image.sortOrder, equals(1));
        expect(image.duration, isNull);
        expect(image.resolution, equals('1920x1080'));
        expect(image.format, equals('JPEG'));
        expect(image.fileSize, equals(2048576));
      });

      test('should convert ProductImage to JSON', () {
        final image = ProductImage.fromJson(sampleImageJson);
        final json = image.toJson();

        expect(json['id'], equals(1));
        expect(json['file_url'], equals('https://example.com/image1.jpg'));
        expect(json['is_primary'], isTrue);
        expect(json['sort_order'], equals(1));
      });

      test('should handle string numbers in ProductImage JSON', () {
        final jsonWithStringNumbers = {
          'id': '2',
          'file_url': 'https://example.com/image2.jpg',
          'file_type': 'image',
          'is_primary': 'false',
          'sort_order': '2',
          'file_size': '1048576',
        };

        final image = ProductImage.fromJson(jsonWithStringNumbers);

        expect(image.id, equals(2));
        expect(image.isPrimary, isFalse);
        expect(image.sortOrder, equals(2));
        expect(image.fileSize, equals(1048576));
      });
    });

    group('Ranch Model', () {
      test('should create Ranch from JSON', () {
        final ranch = Ranch.fromJson(sampleRanchJson);

        expect(ranch.id, equals(1));
        expect(ranch.name, equals('Rancho El Futuro'));
        expect(ranch.legalName, equals('Agropecuaria El Futuro C.A.'));
        expect(ranch.description, equals('Especialistas en ganado lechero'));
        expect(ranch.specialization, equals('lechero'));
        expect(ranch.avgRating, equals(4.5));
        expect(ranch.totalSales, equals(150));
        expect(ranch.lastSaleAt, isNotNull);
      });

      test('should convert Ranch to JSON', () {
        final ranch = Ranch.fromJson(sampleRanchJson);
        final json = ranch.toJson();

        expect(json['id'], equals(1));
        expect(json['name'], equals('Rancho El Futuro'));
        expect(json['legal_name'], equals('Agropecuaria El Futuro C.A.'));
        expect(json['avg_rating'], equals(4.5));
      });

      test('displayName should return legalName when available', () {
        final ranch = Ranch.fromJson(sampleRanchJson);
        expect(ranch.displayName, equals('Agropecuaria El Futuro C.A.'));
      });

      test('displayName should return name when legalName is null', () {
        final ranchWithoutLegalName = Ranch.fromJson({
          ...sampleRanchJson,
          'legal_name': null,
        });
        expect(ranchWithoutLegalName.displayName, equals('Rancho El Futuro'));
      });

      test('should handle string numbers in Ranch JSON', () {
        final jsonWithStringNumbers = {
          'id': '5',
          'name': 'Test Ranch',
          'legal_name': null,
          'description': null,
          'specialization': null,
          'avg_rating': '4.2',
          'total_sales': '100',
          'last_sale_at': null,
        };

        final ranch = Ranch.fromJson(jsonWithStringNumbers);

        expect(ranch.id, equals(5));
        expect(ranch.avgRating, equals(4.2));
        expect(ranch.totalSales, equals(100));
      });
    });
  });
}
