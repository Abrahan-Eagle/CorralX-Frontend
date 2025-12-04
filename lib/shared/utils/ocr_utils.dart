import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// Datos extraídos de la CI venezolana
class CIData {
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? secondLastName;
  final String? ciNumber; // V-12345678
  final String? dateOfBirth; // DD/MM/YYYY
  final String? sex; // M o F

  CIData({
    this.firstName,
    this.middleName,
    this.lastName,
    this.secondLastName,
    this.ciNumber,
    this.dateOfBirth,
    this.sex,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'secondLastName': secondLastName,
      'ciNumber': ciNumber,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
    };
  }
}

/// Datos extraídos del RIF
class RIFData {
  final String? businessName; // Razón social
  final String? rifNumber; // V-12345678-9 o J-12345678-9
  final String? address;

  RIFData({
    this.businessName,
    this.rifNumber,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'rifNumber': rifNumber,
      'address': address,
    };
  }
}

class OCRUtils {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Procesar imagen de CI venezolana y extraer datos
  static Future<CIData> extractCIData(File imageFile) async {
    try {
      _logger.i('🔍 Iniciando OCR en CI...');
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      _logger.i('📄 Texto reconocido (${fullText.length} caracteres)');
      _logger.d('📄 Texto completo CI:\n$fullText');

      // Extraer datos usando patrones comunes de CI venezolana
      String? ciNumber;
      String? dateOfBirth;
      String? firstName;
      String? middleName;
      String? lastName;
      String? secondLastName;
      String? sex;

      // Buscar CI number (V-19.217.553, V 19217553, etc.) - más flexible
      // Acepta puntos, espacios y guiones, luego normaliza
      final ciPatterns = [
        RegExp(r'\b[VE]\s*[- ]?\s*\d{1,2}\.?\d{3}\.?\d{3}\b'), // V 19.217.553
        RegExp(r'\b[VE]\s*[- ]?\s*\d{7,8}\b'), // V 19217553
        RegExp(r'C[\.I]\.?\s*[VE]\s*[- ]?\s*\d{1,2}\.?\d{3}\.?\d{3}\b', caseSensitive: false), // con "C.I."
      ];
      
      for (final pattern in ciPatterns) {
        final matches = pattern.allMatches(fullText);
        if (matches.isNotEmpty) {
          // Tomar el primer match y normalizarlo
          String raw = matches.first.group(0) ?? '';
          raw = raw.toUpperCase();
          // Conservar solo V/E y dígitos
          raw = raw.replaceAll(RegExp(r'[^VE0-9]'), '');

          if (raw.isNotEmpty && RegExp(r'^[VE][0-9]+$').hasMatch(raw)) {
            final letter = raw[0];
            String digits = raw.substring(1);
            // Si tiene más de 8 dígitos, quedarnos con los últimos 8
            if (digits.length > 8) {
              digits = digits.substring(digits.length - 8);
            }
            ciNumber = '$letter-$digits';
            _logger.i('✅ CI encontrada: $ciNumber');
            break;
          }
        }
      }

      // Buscar fechas (DD/MM/YYYY) y elegir la más antigua como fecha de nacimiento
      final datePattern = RegExp(r'\d{2}/\d{2}/\d{4}');
      final dateMatches = datePattern.allMatches(fullText).toList();
      if (dateMatches.isNotEmpty) {
        String? selectedDate;
        int? minYear;

        for (final match in dateMatches) {
          final value = match.group(0);
          if (value == null || value.length < 10) continue;

          final year = int.tryParse(value.substring(6, 10));
          if (year == null) continue;

          if (minYear == null || year < minYear) {
            minYear = year;
            selectedDate = value;
          }
        }

        if (selectedDate != null) {
          dateOfBirth = selectedDate;
          _logger.i('✅ Fecha de nacimiento encontrada (más antigua): $dateOfBirth');
        }
      }

      // Buscar nombres y apellidos usando las etiquetas "NOMBRES" y "APELLIDOS"
      final lines = fullText.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final rawLine = lines[i];
        final lineUpper = rawLine.toUpperCase().trim();
        // Normalizar eliminando espacios y caracteres no alfabéticos para tolerar errores de OCR
        final normalized = lineUpper.replaceAll(RegExp(r'[^A-ZÑ]'), '');

        // Línea de NOMBRES
        if (normalized.contains('NOMBRES')) {
          String? namesPart;

          // Si en la misma línea vienen los nombres después de la palabra NOMBRES
          final idx = lineUpper.indexOf('NOMBRES');
          final after = idx >= 0
              ? rawLine.substring(idx + 'NOMBRES'.length).trim()
              : '';
          if (after.isNotEmpty) {
            namesPart = after;
          } else if (i + 1 < lines.length) {
            // Si la siguiente línea contiene los nombres
            namesPart = lines[i + 1].trim();
          }

          if (namesPart != null && namesPart.isNotEmpty) {
            final parts = namesPart.split(RegExp(r'\s+'));
            if (parts.isNotEmpty) {
              firstName = parts[0];
              if (parts.length > 1) {
                middleName = parts.sublist(1).join(' ');
              }
            }
          }
        }

        // Línea de APELLIDOS
        if (normalized.contains('APELLIDOS')) {
          String? lastNamesPart;

          final idx = lineUpper.indexOf('APELLIDOS');
          final after = idx >= 0
              ? rawLine.substring(idx + 'APELLIDOS'.length).trim()
              : '';
          if (after.isNotEmpty) {
            lastNamesPart = after;
          } else if (i + 1 < lines.length) {
            lastNamesPart = lines[i + 1].trim();
          }

          if (lastNamesPart != null && lastNamesPart.isNotEmpty) {
            final parts = lastNamesPart.split(RegExp(r'\s+'));
            if (parts.isNotEmpty) {
              lastName = parts[0];
              if (parts.length > 1) {
                secondLastName = parts.sublist(1).join(' ');
              }
            }
          }
        }
      }

      // Fallback: si no se encontraron nombres/apellidos con etiquetas,
      // intentar deducirlos de líneas con dos o más palabras sin números.
      if (firstName == null && lastName == null) {
        _logger.d('🔍 Fallback de nombres/apellidos sin etiquetas explícitas...');

        bool _isLabelWord(String word) {
          final w = word.toUpperCase();
          if (w.isEmpty) return false;
          // Palabras que típicamente son etiquetas o ruidos
          const blacklist = [
            'VENEZOLANO',
            'REPUBLICA',
            'BOLIVARIANA',
            'CEDULA',
            'IDENTIDAD',
            'CEDULADEIDENTIDAD',
            'DIRECTOR',
            'DR',
            'CED',
            'ULA',
            'DEDENTDAD',
          ];
          if (blacklist.contains(w)) return true;

          // Considerar como posible etiqueta si casi no tiene vocales
          final vowels = RegExp(r'[AEIOUÁÉÍÓÚ]');
          final vowelCount = vowels.allMatches(w).length;
          return vowelCount <= 1 && w.length >= 3;
        }

        bool _isCandidateLine(String line) {
          final t = line.trim();
          if (t.isEmpty) return false;
          if (RegExp(r'[0-9/]').hasMatch(t)) return false;
          if (t.length < 5) return false;
          final upper = t.toUpperCase();
          if (upper.contains('VENEZOLANO') ||
              upper.contains('REPUBLICA') ||
              upper.contains('CEDULA')) {
            return false;
          }
          // Debe tener al menos dos palabras
          final words = t.split(RegExp(r'\s+'));
          return words.length >= 2;
        }

        final candidateLines =
            lines.where((l) => _isCandidateLine(l)).toList(growable: false);

        if (candidateLines.isNotEmpty) {
          String cleanNames(String line) {
            final words = line
                .trim()
                .split(RegExp(r'\s+'))
                .where((w) => !_isLabelWord(w))
                .toList();
            return words.join(' ');
          }

          // Primera línea candidata: nombres
          final namesLine = cleanNames(candidateLines.first);
          if (namesLine.isNotEmpty) {
            final parts = namesLine.split(RegExp(r'\s+'));
            if (parts.isNotEmpty) {
              firstName = parts[0];
              if (parts.length > 1) {
                middleName = parts.sublist(1).join(' ');
              }
            }
          }

          // Segunda línea candidata: apellidos
          if (candidateLines.length > 1) {
            final lastNamesLine = cleanNames(candidateLines[1]);
            if (lastNamesLine.isNotEmpty) {
              final parts = lastNamesLine.split(RegExp(r'\s+'));
              if (parts.isNotEmpty) {
                lastName = parts[0];
                if (parts.length > 1) {
                  secondLastName = parts.sublist(1).join(' ');
                }
              }
            }
          }
        }
      }

      // Buscar sexo (M o F)
      final sexPattern = RegExp(r'\b([MF])\b');
      final sexMatch = sexPattern.firstMatch(fullText);
      if (sexMatch != null) {
        sex = sexMatch.group(1);
        _logger.i('✅ Sexo encontrado: $sex');
      }

      final ciData = CIData(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        secondLastName: secondLastName,
        ciNumber: ciNumber,
        dateOfBirth: dateOfBirth,
        sex: sex,
      );

      _logger.i('✅ Datos CI extraídos: ${ciData.toJson()}');
      return ciData;
    } catch (e) {
      _logger.e('❌ Error al procesar CI con OCR: $e');
      return CIData();
    }
  }

  /// Procesar imagen de RIF y extraer datos
  static Future<RIFData> extractRIFData(File imageFile) async {
    try {
      _logger.i('🔍 Iniciando OCR en RIF...');
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      _logger.i('📄 Texto reconocido (${fullText.length} caracteres)');
      _logger.d('📄 Texto completo RIF:\n$fullText');

      String? rifNumber;
      String? businessName;
      String? address;

      // Buscar RIF number (V-12345678-9 o J-12345678-9) - más flexible
      final rifPatterns = [
        RegExp(r'([VJ])-(\d{8})-(\d)'), // V-12345678-9 o J-12345678-9 con grupos
        RegExp(r'([VJ])\s*-\s*(\d{8})\s*-\s*(\d)'), // Con espacios
        RegExp(r'R[\.I]\.?F\.?\s*([VJ])-(\d{8})-(\d)', caseSensitive: false), // Con "R.I.F." antes
        RegExp(r'([VJ])\s*(\d{8})\s*(\d)'), // Sin guiones
      ];
      
      for (final pattern in rifPatterns) {
        final matches = pattern.allMatches(fullText);
        if (matches.isNotEmpty) {
          final match = matches.first;
          // Reconstruir el RIF desde los grupos capturados
          if (match.groupCount >= 3) {
            final prefix = match.group(1) ?? '';
            final numbers = match.group(2) ?? '';
            final digit = match.group(3) ?? '';
            if (prefix.isNotEmpty && numbers.length == 8 && digit.isNotEmpty) {
              rifNumber = '${prefix.toUpperCase()}-$numbers-$digit';
              _logger.i('✅ RIF encontrado: $rifNumber');
              break;
            }
          } else if (match.groupCount == 0) {
            // Fallback: usar el match completo si no hay grupos
            rifNumber = match.group(0)?.replaceAll(RegExp(r'\s+'), '').toUpperCase();
            if (rifNumber != null && !rifNumber.contains('-')) {
              // Intentar agregar guiones si no los tiene
              final cleanMatch = RegExp(r'([VJ])(\d{8})(\d)').firstMatch(rifNumber);
              if (cleanMatch != null) {
                rifNumber = '${cleanMatch.group(1)}-${cleanMatch.group(2)}-${cleanMatch.group(3)}';
              }
            }
            if (rifNumber != null) {
              _logger.i('✅ RIF encontrado: $rifNumber');
              break;
            }
          }
        }
      }

      // Normalizar saltos de línea
      final lines = fullText.split('\n');

      // Buscar razón social (generalmente en las primeras líneas, texto en mayúsculas)
      final businessNameLines = lines.where((line) {
        final trimmed = line.trim();
        return trimmed.isNotEmpty &&
            trimmed.length > 5 &&
            trimmed == trimmed.toUpperCase() &&
            !RegExp(r'^[VJ]-\d').hasMatch(trimmed);
      }).toList();

      if (businessNameLines.isNotEmpty) {
        businessName = businessNameLines[0].trim();
        _logger.i('✅ Razón social encontrada: $businessName');
      }

      // Buscar dirección a partir de "DOMICILIO FISCAL"
      // Ejemplo deseado:
      //  (línea con DOMICILIO FISCAL)
      //  CALLE LAS TORRES CASA NRO 44-60 URB EL SOCORRO
      //  VALENCIA CARABOBO ZONA POSTAL 2001
      int? domicilioIndex;
      for (int i = 0; i < lines.length; i++) {
        final upper = lines[i].toUpperCase();
        final normalized = upper.replaceAll(RegExp(r'[^A-ZÑ ]'), ' ');
        if (normalized.contains('DOMICILIO') && normalized.contains('FISCAL')) {
          domicilioIndex = i;
          break;
        }
        // Tolerar OCRs tipo "cILIO FISCAL"
        if (!normalized.contains('DOMICILIO') &&
            normalized.contains('FISCAL') &&
            normalized.contains('CILIO')) {
          domicilioIndex = i;
          break;
        }
      }

      // Palabras que indican fin del bloque de dirección
      final stopKeywords = [
        'FECHA',
        'VENCIMIENTO',
        'EMISION',
        'RIF',
        'NOMBRE',
      ];

      if (domicilioIndex != null) {
        final collected = <String>[];

        // Helper para limpiar ruido típico de OCR en líneas de dirección
        String _normalizeAddressLine(String line) {
          var upper = line.toUpperCase();
          // Unificar espacios
          upper = upper.replaceAll(RegExp(r'\s+'), ' ').trim();

          final allowedKeywords = <String>{
            'CALLE',
            'CASA',
            'NRO',
            'URB',
            'URBANIZACION',
            'SECTOR',
            'ZONA',
            'POSTAL',
            'VALENCIA',
            'CARABOBO',
            'MUNICIPIO',
            'EDO',
            'ESTADO',
          };

          final words = upper.split(' ');
          final cleanedWords = <String>[];

          for (final w in words) {
            final word = w.trim();
            if (word.isEmpty) continue;

            // Conservar números puros (ej: 44-60, 2001)
            if (RegExp(r'^[0-9\-\/]+$').hasMatch(word)) {
              cleanedWords.add(word);
              continue;
            }

            // Conservar palabras clave conocidas
            if (allowedKeywords.contains(word)) {
              cleanedWords.add(word);
              continue;
            }

            // Conservar palabras con al menos 2 vocales (parecen "normales")
            final vowelCount =
                RegExp(r'[AEIOUÁÉÍÓÚ]').allMatches(word).length;
            if (vowelCount >= 2 && word.length <= 12) {
              cleanedWords.add(word);
              continue;
            }
          }

          return cleanedWords.join(' ');
        }

        // 1) Extraer la parte de dirección que viene en la MISMA línea de DOMICILIO FISCAL
        final domicilioLine = lines[domicilioIndex];
        final upperDom = domicilioLine.toUpperCase();
        final idxFiscal = upperDom.indexOf('FISCAL');
        if (idxFiscal != -1) {
          var afterFiscal =
              domicilioLine.substring(idxFiscal + 'FISCAL'.length).trim();

          // Cortar si en esa misma línea aparecen palabras de stop o una fecha
          for (final kw in stopKeywords) {
            final idxKw = afterFiscal.toUpperCase().indexOf(kw);
            if (idxKw != -1) {
              afterFiscal = afterFiscal.substring(0, idxKw).trim();
            }
          }
          final dateMatch =
              RegExp(r'\d{2}/\d{2}/\d{4}').firstMatch(afterFiscal.toUpperCase());
          if (dateMatch != null) {
            afterFiscal =
                afterFiscal.substring(0, dateMatch.start).trim();
          }

          if (afterFiscal.isNotEmpty) {
            final normalized = _normalizeAddressLine(afterFiscal);
            if (normalized.isNotEmpty) {
              collected.add(normalized);
            }
          }
        }

        // 2) Tomar 1–2 líneas siguientes como complemento (ej: VALENCIA CARABOBO ZONA POSTAL 2001)
        for (int i = domicilioIndex + 1; i < lines.length; i++) {
          final rawLine = lines[i];
          final line = rawLine.trim();
          if (line.isEmpty) continue;

          final upper = line.toUpperCase();

          // Cortar si llegamos a una línea que ya no es dirección sino metadatos
          if (stopKeywords.any((kw) => upper.contains(kw)) ||
              RegExp(r'\d{2}/\d{2}/\d{4}').hasMatch(upper)) {
            break;
          }

          final normalized = _normalizeAddressLine(line);
          if (normalized.isNotEmpty) {
            collected.add(normalized);
          }

          // Normalmente serán 1 o 2 líneas adicionales
          if (collected.length >= 3) break;
        }

        if (collected.isNotEmpty) {
          address = collected.join('\n');
          _logger.i('✅ Dirección encontrada (desde DOMICILIO FISCAL): $address');
        }
      }

      // Fallback: si no se encontró DOMICILIO FISCAL, usar búsqueda por palabras clave
      if (address == null) {
        final addressKeywords = [
          'calle',
          'avenida',
          'av.',
          'av ',
          'urb',
          'urbanizacion',
          'sector',
          'municipio',
          'estado',
          'zona postal',
        ];

        int? firstAddressIndex;
        int? lastAddressIndex;

        for (int i = 0; i < lines.length; i++) {
          final lower = lines[i].toLowerCase();
          final hasKeyword =
              addressKeywords.any((keyword) => lower.contains(keyword));

          if (hasKeyword) {
            firstAddressIndex ??= i;
            lastAddressIndex = i;
          }
        }

        if (firstAddressIndex != null) {
          final collected = <String>[];

          for (int i = firstAddressIndex; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;

            final lower = line.toLowerCase();
            final looksLikeAddress = addressKeywords
                    .any((keyword) => lower.contains(keyword)) ||
                RegExp(r'\b\d{4}\b')
                    .hasMatch(lower); // zona postal u otros números

            if (!looksLikeAddress &&
                i > (lastAddressIndex ?? firstAddressIndex)) {
              break;
            }

            collected.add(line);
          }

          if (collected.isNotEmpty) {
            address = collected.join('\n');
            _logger.i('✅ Dirección encontrada (fallback): $address');
          }
        }
      }

      final rifData = RIFData(
        businessName: businessName,
        rifNumber: rifNumber,
        address: address,
      );

      _logger.i('✅ Datos RIF extraídos: ${rifData.toJson()}');
      return rifData;
    } catch (e) {
      _logger.e('❌ Error al procesar RIF con OCR: $e');
      return RIFData();
    }
  }

  /// Liberar recursos del reconocedor de texto
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

