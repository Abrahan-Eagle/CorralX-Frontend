import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// Resultado de la validación de selfie con documento
class SelfieWithDocValidationResult {
  final bool isValid;
  final bool hasFace;
  final bool hasDocument;
  final double faceConfidence; // Confianza de detección de rostro (0.0 a 1.0)
  final double documentConfidence; // Confianza de detección de documento (0.0 a 1.0)
  final String? errorMessage;

  SelfieWithDocValidationResult({
    required this.isValid,
    required this.hasFace,
    required this.hasDocument,
    this.faceConfidence = 0.0,
    this.documentConfidence = 0.0,
    this.errorMessage,
  });
}

/// Servicio para validar selfie con documento en tiempo real
class SelfieWithDocValidationService {
  final FaceDetector _faceDetector;
  final TextRecognizer _textRecognizer;
  static const double minFaceConfidence = 0.5; // 50% mínimo de confianza para rostro
  static const double minDocumentConfidence = 0.3; // 30% mínimo de confianza para documento (más tolerante)
  
  // Estado persistente para manejar detecciones intermitentes
  bool _lastFaceDetected = false;
  double _lastFaceConfidence = 0.0;
  int _faceDetectionCount = 0; // Contador de frames consecutivos con rostro
  
  bool _lastDocumentDetected = false;
  double _lastDocumentConfidence = 0.0;
  int _documentDetectionCount = 0; // Contador de frames consecutivos con documento
  
  static const int persistenceFrames = 3; // Mantener detección por 3 frames aunque falle

  SelfieWithDocValidationService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableLandmarks: true,
            enableTracking: true,
            minFaceSize: 0.15,
          ),
        ),
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Analizar CameraImage para validar que tiene rostro y documento CI
  Future<SelfieWithDocValidationResult> validateCameraImage({
    required CameraImage cameraImage,
    required InputImageRotation rotation,
  }) async {
    try {
      final inputImage = _inputImageFromCameraImage(cameraImage, rotation);
      return await _validateInputImage(inputImage);
    } catch (e) {
      _logger.e('Error validando selfie con documento: $e');
      return SelfieWithDocValidationResult(
        isValid: false,
        hasFace: false,
        hasDocument: false,
        errorMessage: 'Error al validar la imagen: $e',
      );
    }
  }

  /// Validar archivo de imagen capturada
  Future<SelfieWithDocValidationResult> validateImageFile(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      return await _validateInputImage(inputImage);
    } catch (e) {
      _logger.e('Error validando archivo de imagen: $e');
      return SelfieWithDocValidationResult(
        isValid: false,
        hasFace: false,
        hasDocument: false,
        errorMessage: 'Error al validar la imagen: $e',
      );
    }
  }

  /// Validar InputImage (método interno compartido)
  Future<SelfieWithDocValidationResult> _validateInputImage(InputImage inputImage) async {
    try {
      // Procesar AMBOS en PARALELO para evitar interferencias
      // Esto permite que ambos detectores trabajen simultáneamente sin bloquearse
      final results = await Future.wait([
        _detectFace(inputImage).catchError((e) {
          _logger.w('Error detectando rostro: $e');
          return {'detected': false, 'confidence': 0.0};
        }),
        _detectDocument(inputImage).catchError((e) {
          _logger.w('Error detectando documento: $e');
          return {'detected': false, 'confidence': 0.0};
        }),
      ]);

      final faceResult = results[0];
      final documentResult = results[1];
      
      bool hasFace = faceResult['detected'] as bool;
      double faceConfidence = faceResult['confidence'] as double;
      bool hasDocument = documentResult['detected'] as bool;
      double documentConfidence = documentResult['confidence'] as double;
      
      // Sistema de persistencia: mantener detecciones recientes
      // Si detectó rostro en este frame, actualizar estado
      if (hasFace && faceConfidence >= minFaceConfidence) {
        _lastFaceDetected = true;
        _lastFaceConfidence = faceConfidence;
        _faceDetectionCount = persistenceFrames; // Resetear contador
      } else if (_faceDetectionCount > 0) {
        // Usar detección anterior si aún está en el período de persistencia
        hasFace = _lastFaceDetected;
        faceConfidence = _lastFaceConfidence;
        _faceDetectionCount--;
      } else {
        // No hay detección y se agotó la persistencia
        _lastFaceDetected = false;
        _lastFaceConfidence = 0.0;
        hasFace = false;
        faceConfidence = 0.0;
      }
      
      // Mismo sistema para documento
      if (hasDocument && documentConfidence >= minDocumentConfidence) {
        _lastDocumentDetected = true;
        _lastDocumentConfidence = documentConfidence;
        _documentDetectionCount = persistenceFrames;
      } else if (_documentDetectionCount > 0) {
        // Usar detección anterior si aún está en el período de persistencia
        hasDocument = _lastDocumentDetected;
        documentConfidence = _lastDocumentConfidence;
        _documentDetectionCount--;
      } else {
        // No hay detección y se agotó la persistencia
        _lastDocumentDetected = false;
        _lastDocumentConfidence = 0.0;
        hasDocument = false;
        documentConfidence = 0.0;
      }

      // Validar que ambos estén presentes (usando estado persistente)
      // Rostro: 50% mínimo, Documento: 30% mínimo
      final isValid = hasFace && 
                      hasDocument && 
                      faceConfidence >= minFaceConfidence && 
                      documentConfidence >= minDocumentConfidence;

      String? errorMessage;
      if (!hasFace) {
        errorMessage = 'Rostro no detectado';
      } else if (faceConfidence < minFaceConfidence) {
        errorMessage = 'Rostro poco claro';
      } else if (!hasDocument) {
        errorMessage = 'CI no detectada';
      } else if (documentConfidence < minDocumentConfidence) {
        errorMessage = 'CI poco visible';
      }

      // Logging mejorado con información de persistencia
      final faceStatus = hasFace ? '✅' : '❌';
      final docStatus = hasDocument ? '✅' : '❌';
      final persistInfo = 'Face:$_faceDetectionCount Doc:$_documentDetectionCount';
      _logger.i('🔍 Validación selfie con doc - $faceStatus Rostro: ${(faceConfidence * 100).toStringAsFixed(1)}%, $docStatus Documento: ${(documentConfidence * 100).toStringAsFixed(1)}%, Válido: $isValid [$persistInfo]');

      return SelfieWithDocValidationResult(
        isValid: isValid,
        hasFace: hasFace,
        hasDocument: hasDocument,
        faceConfidence: faceConfidence,
        documentConfidence: documentConfidence,
        errorMessage: errorMessage,
      );
    } catch (e) {
      _logger.e('Error validando InputImage: $e');
      return SelfieWithDocValidationResult(
        isValid: false,
        hasFace: false,
        hasDocument: false,
        errorMessage: 'Error al validar la imagen: $e',
      );
    }
  }

  /// Detectar rostro en la imagen
  Future<Map<String, dynamic>> _detectFace(InputImage inputImage) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        return {'detected': false, 'confidence': 0.0};
      }

      // Si hay más de un rostro, considerar como inválido
      if (faces.length > 1) {
        return {'detected': false, 'confidence': 0.0};
      }

      final face = faces.first;
      final boundingBox = face.boundingBox;
      
      // Calcular confianza basada en:
      // - Tamaño del rostro (más grande = más confianza)
      // - Tracking ID (si tiene tracking, es más confiable)
      // - Landmarks detectados
      double confidence = 0.5; // Base
      
      // Aumentar confianza si tiene tracking
      if (face.trackingId != null) {
        confidence += 0.2;
      }
      
      // Aumentar confianza si tiene landmarks
      if (face.landmarks.isNotEmpty) {
        confidence += 0.2;
      }
      
      // Aumentar confianza si el rostro es grande (más del 20% del frame)
      final faceArea = boundingBox.width * boundingBox.height;
      // Obtener tamaño real del frame desde el InputImage
      final frameArea = inputImage.metadata?.size.width ?? 720 * 
                       (inputImage.metadata?.size.height ?? 1280);
      final faceRatio = faceArea / frameArea;
      
      if (faceRatio > 0.2) {
        confidence += 0.1;
      } else if (faceRatio > 0.1) {
        confidence += 0.05;
      }
      
      // Limitar a máximo 1.0
      confidence = confidence.clamp(0.0, 1.0);

      return {
        'detected': true,
        'confidence': confidence,
        'boundingBox': boundingBox,
      };
    } catch (e) {
      _logger.e('Error detectando rostro: $e');
      return {'detected': false, 'confidence': 0.0};
    }
  }

  /// Detectar documento CI en la imagen (buscar texto que parezca CI venezolana)
  Future<Map<String, dynamic>> _detectDocument(InputImage inputImage) async {
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final text = recognizedText.text.toUpperCase().trim();
      final textLength = text.length;
      final blocksCount = recognizedText.blocks.length;
      final linesCount = recognizedText.blocks.fold<int>(0, (sum, block) => sum + block.lines.length);
      
      // Si hay rostro presente, ser MUY tolerante: incluso sin texto legible,
      // si hay estructura de bloques/líneas, puede ser un documento
      final hasFaceContext = _lastFaceDetected && _faceDetectionCount > 0;
      
      // Si no hay texto Y no hay rostro, no hay documento
      if (text.isEmpty && !hasFaceContext) {
        return {'detected': false, 'confidence': 0.0};
      }
      
      // Si hay rostro pero no texto, pero hay estructura de bloques, considerar documento
      if (text.isEmpty && hasFaceContext && blocksCount >= 1) {
        // Estructura de documento presente aunque texto no legible
        return {
          'detected': true,
          'confidence': 0.35, // Confianza moderada basada en estructura
        };
      }

      bool hasCIPattern = false;
      bool hasKeywords = false;
      bool hasPartialKeywords = false;
      double confidence = 0.15; // Base más baja

      // Buscar patrón de CI venezolana (más flexible: acepta V-123456, V-1234567, V-12345678)
      final ciPatternStrict = RegExp(r'[VE]-\d{7,8}'); // V-12345678 o E-12345678
      final ciPatternFlexible = RegExp(r'[VE]-\d{5,9}'); // Más flexible: 5-9 dígitos
      
      if (ciPatternStrict.hasMatch(text)) {
        hasCIPattern = true;
        confidence += 0.5; // Alto peso si es patrón estricto
      } else if (ciPatternFlexible.hasMatch(text)) {
        hasCIPattern = true;
        confidence += 0.3; // Peso medio si es patrón flexible
      }

      // Buscar palabras clave completas
      final keywords = ['REPUBLICA', 'VENEZUELA', 'CEDULA', 'IDENTIDAD', 'REPUBLIC', 'IDENTITY'];
      int keywordCount = 0;
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          hasKeywords = true;
          keywordCount++;
        }
      }
      
      // Buscar palabras clave parciales (más tolerante cuando el texto está borroso)
      final partialKeywords = ['REPUB', 'VENE', 'CEDU', 'IDENT', 'VEN', 'REP'];
      int partialCount = 0;
      for (final partial in partialKeywords) {
        if (text.contains(partial)) {
          hasPartialKeywords = true;
          partialCount++;
        }
      }
      
      if (hasKeywords) {
        confidence += 0.25 * keywordCount.clamp(1, 2); // Hasta 0.5 por keywords completas
      } else if (hasPartialKeywords) {
        confidence += 0.15 * partialCount.clamp(1, 2); // Hasta 0.3 por keywords parciales
      }

      // Si hay rostro presente (usando estado persistente), ser MUY tolerante
      // porque sabemos que el documento debería estar ahí
      if (hasFaceContext) {
        // Si hay CUALQUIER texto Y hay rostro, es MUY probable que sea el documento
        if (textLength >= 1) {
          confidence += 0.3; // Bonus MUY significativo si hay rostro + cualquier texto
        }
        // Si hay bloques de texto estructurados (como un documento), más confianza
        if (blocksCount >= 1) {
          confidence += 0.2; // Bonus por estructura de documento (incluso 1 bloque)
        }
        if (blocksCount >= 2) {
          confidence += 0.1; // Bonus adicional por múltiples bloques
        }
        // Si hay líneas de texto (estructura de documento), más confianza
        if (linesCount >= 2) {
          confidence += 0.15; // Bonus por múltiples líneas
        }
      }

      // Aumentar confianza basada en cantidad de texto detectado
      if (textLength > 50) {
        confidence += 0.15;
      } else if (textLength > 20) {
        confidence += 0.1;
      } else if (textLength > 5) {
        confidence += 0.05; // Incluso con poco texto, puede ser documento
      }

      // Si tiene patrón de CI, keywords (completas o parciales), o estructura de documento
      // considerar que hay documento
      // CON ROSTRO PRESENTE: ser MUY tolerante
      final hasDocument = hasCIPattern || 
                         hasKeywords || 
                         (hasPartialKeywords && textLength >= 2) || // Reducido de 3 a 2
                         (textLength >= 5 && blocksCount >= 1) || // Reducido de 10 a 5, de 2 a 1 bloque
                         (hasFaceContext && textLength >= 1 && blocksCount >= 1) || // Con rostro: cualquier texto + estructura
                         (hasFaceContext && blocksCount >= 2); // Con rostro: múltiples bloques sin texto legible
      
      // Aumentar confianza si tiene múltiples indicios
      if (hasCIPattern && (hasKeywords || hasPartialKeywords)) {
        confidence += 0.2; // Bonus adicional si tiene múltiples indicios
      }

      // Limitar a máximo 1.0
      confidence = confidence.clamp(0.0, 1.0);

      final textPreview = textLength > 0 ? text.substring(0, textLength > 30 ? 30 : textLength) : '(sin texto)';
      _logger.d('📄 Detección documento - Texto: $textLength chars ($textPreview), CI Pattern: $hasCIPattern, Keywords: $hasKeywords, Parciales: $hasPartialKeywords, Bloques: $blocksCount, Líneas: $linesCount, Con Rostro: $hasFaceContext, Confianza: ${(confidence * 100).toStringAsFixed(1)}%');

      return {
        'detected': hasDocument,
        'confidence': confidence,
      };
    } catch (e) {
      _logger.e('Error detectando documento: $e');
      return {'detected': false, 'confidence': 0.0};
    }
  }

  /// Convertir CameraImage (YUV420) a InputImage usando formato NV21 (optimizado para Android)
  InputImage _inputImageFromCameraImage(
    CameraImage cameraImage,
    InputImageRotation rotation,
  ) {
    // Convertir YUV420 a NV21
    final nv21 = _yuv420ToNv21(cameraImage);
    
    final inputImageData = InputImageMetadata(
      size: ui.Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: cameraImage.width, // NV21: bytesPerRow = width para plano Y (sin padding)
    );

    return InputImage.fromBytes(
      bytes: nv21,
      metadata: inputImageData,
    );
  }

  /// Convertir YUV420 a NV21 (formato compatible con ML Kit en Android)
  Uint8List _yuv420ToNv21(CameraImage cameraImage) {
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final width = cameraImage.width;
    final height = cameraImage.height;
    
    // Tamaños correctos para YUV420
    final ySize = width * height;
    final uvSize = (width * height) ~/ 4; // U y V son 1/4 del tamaño cada uno
    
    // NV21: Y plano completo + intercalado VU
    final nv21Size = ySize + (uvSize * 2);
    final nv21 = Uint8List(nv21Size);

    // Copiar plano Y fila por fila respetando el stride
    final yStride = yPlane.bytesPerRow;
    final yBytes = yPlane.bytes;
    int yOffset = 0;
    for (int y = 0; y < height; y++) {
      final yRowStart = y * yStride;
      final yRowEnd = yRowStart + width;
      if (yRowEnd <= yBytes.length) {
        nv21.setRange(yOffset, yOffset + width, yBytes, yRowStart);
      }
      yOffset += width;
    }

    // Intercalar U y V en formato NV21 (VU intercalado)
    final uStride = uPlane.bytesPerRow;
    final vStride = vPlane.bytesPerRow;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    
    int uvOffset = ySize;
    for (int y = 0; y < uvHeight; y++) {
      final uRowStart = y * uStride;
      final vRowStart = y * vStride;
      
      for (int x = 0; x < uvWidth; x++) {
        if (uRowStart + x < uBytes.length && vRowStart + x < vBytes.length) {
          nv21[uvOffset] = vBytes[vRowStart + x]; // V primero
          nv21[uvOffset + 1] = uBytes[uRowStart + x]; // U después
          uvOffset += 2;
        }
      }
    }

    return nv21;
  }

  /// Liberar recursos
  void dispose() {
    _faceDetector.close();
    _textRecognizer.close();
  }
}

