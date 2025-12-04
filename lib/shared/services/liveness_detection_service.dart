import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// Estados de movimiento de cabeza para liveness detection
enum HeadPose {
  front,   // Frente
  up,      // Arriba
  down,    // Abajo
  left,    // Izquierda
  right,   // Derecha
}

/// Resultado de la detección de movimiento
class LivenessResult {
  final bool isValid;
  final HeadPose? detectedPose;
  final String? errorMessage;
  final double? headEulerY; // Rotación vertical (-90 a 90)
  final double? headEulerZ; // Rotación horizontal (-90 a 90)
  final double progress; // Progreso hacia la pose correcta (0.0 a 1.0)

  LivenessResult({
    required this.isValid,
    this.detectedPose,
    this.errorMessage,
    this.headEulerY,
    this.headEulerZ,
    this.progress = 0.0,
  });
}

/// Servicio para detección de vida (liveness detection) usando ML Kit
class LivenessDetectionService {
  final FaceDetector _faceDetector;

  LivenessDetectionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableLandmarks: true,
            enableTracking: true,
            minFaceSize: 0.15,
          ),
        );

  /// Analizar CameraImage (YUV420) directamente para detectar pose de cabeza - OPTIMIZADO
  Future<LivenessResult> analyzeCameraImage({
    required CameraImage cameraImage,
    required HeadPose requiredPose,
    required InputImageRotation rotation,
  }) async {
    try {
      // Intentar con la rotación especificada primero
      List<InputImageRotation> rotationsToTry = [rotation];
      
      // Si no detecta, probar otras rotaciones comunes para cámara frontal
      if (rotation == InputImageRotation.rotation270deg) {
        rotationsToTry.addAll([
          InputImageRotation.rotation90deg,
          InputImageRotation.rotation0deg,
        ]);
      }
      
      for (final rot in rotationsToTry) {
        try {
          final inputImage = _inputImageFromCameraImage(cameraImage, rot);
          final faces = await _faceDetector.processImage(inputImage);

          if (faces.isNotEmpty) {
            if (faces.length > 1) {
              return LivenessResult(
                isValid: false,
                errorMessage: 'Se detectó más de un rostro. Por favor, asegúrate de estar solo.',
              );
            }

            final face = faces.first;
            final headEulerY = face.headEulerAngleY; // Rotación vertical
            final headEulerZ = face.headEulerAngleZ; // Rotación horizontal

            // Detectar pose actual basado en ángulos de Euler
            final detectedPose = _detectHeadPose(headEulerY, headEulerZ);

            // Validar si el pose detectado coincide con el requerido y obtener progreso
            final (isValid, progress) = _validatePose(detectedPose, requiredPose, headEulerY, headEulerZ);

            _logger.i('✅ Rostro detectado - Pose: $detectedPose, Requerido: $requiredPose, Válido: $isValid, Progreso: ${(progress * 100).toStringAsFixed(1)}%, eulerY: $headEulerY, eulerZ: $headEulerZ');
            
            return LivenessResult(
              isValid: isValid,
              detectedPose: detectedPose,
              headEulerY: headEulerY,
              headEulerZ: headEulerZ,
              progress: progress,
              errorMessage: isValid
                  ? null
                  : _getPoseInstruction(requiredPose),
            );
          }
        } catch (e) {
          _logger.w('Error con rotación $rot: $e');
          continue; // Intentar siguiente rotación
        }
      }
      
      // No se detectó rostro con ninguna rotación
      return LivenessResult(
        isValid: false,
        errorMessage: 'No se detectó ningún rostro. Coloca tu rostro dentro del óvalo.',
      );
    } catch (e) {
      _logger.e('Error analizando frame: $e');
      return LivenessResult(
        isValid: false,
        errorMessage: 'Error al procesar la imagen. Intenta nuevamente.',
      );
    }
  }

  /// Analizar imagen de archivo para detectar pose de cabeza (fallback)
  Future<LivenessResult> analyzeImageFile({
    required File imageFile,
    required HeadPose requiredPose,
  }) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return LivenessResult(
          isValid: false,
          errorMessage: 'No se detectó ningún rostro. Asegúrate de estar frente a la cámara.',
        );
      }

      if (faces.length > 1) {
        return LivenessResult(
          isValid: false,
          errorMessage: 'Se detectó más de un rostro. Por favor, asegúrate de estar solo.',
        );
      }

      final face = faces.first;
      final headEulerY = face.headEulerAngleY; // Rotación vertical
      final headEulerZ = face.headEulerAngleZ; // Rotación horizontal

      // Detectar pose actual basado en ángulos de Euler
      final detectedPose = _detectHeadPose(headEulerY, headEulerZ);

      // Validar si el pose detectado coincide con el requerido y obtener progreso
      final (isValid, progress) = _validatePose(detectedPose, requiredPose, headEulerY, headEulerZ);

      return LivenessResult(
        isValid: isValid,
        detectedPose: detectedPose,
        headEulerY: headEulerY,
        headEulerZ: headEulerZ,
        progress: progress,
        errorMessage: isValid
            ? null
            : _getPoseInstruction(requiredPose),
      );
    } catch (e) {
      _logger.e('Error analizando frame: $e');
      return LivenessResult(
        isValid: false,
        errorMessage: 'Error al procesar la imagen. Intenta nuevamente.',
      );
    }
  }

  /// Convertir CameraImage (YUV420) a InputImage usando formato NV21 (optimizado para Android)
  InputImage _inputImageFromCameraImage(CameraImage cameraImage, InputImageRotation rotation) {
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
  /// YUV420 tiene subsampling: U y V tienen 1/4 del tamaño de Y
  /// Considera strides (bytesPerRow) para manejar padding correctamente
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
    // Copiar fila por fila respetando strides
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


  /// Detectar pose de cabeza basado en ángulos de Euler
  HeadPose _detectHeadPose(double? eulerY, double? eulerZ) {
    if (eulerY == null || eulerZ == null) {
      return HeadPose.front;
    }

    // Umbrales para detectar movimientos (en grados) - más permisivos
    const threshold = 12.0;

    // Priorizar rotación horizontal sobre vertical si ambas están presentes
    // Rotación horizontal (eulerZ) - más importante para left/right
    if (eulerZ.abs() > threshold) {
      if (eulerZ > threshold) {
        return HeadPose.right; // Cabeza hacia la derecha
      } else if (eulerZ < -threshold) {
        return HeadPose.left; // Cabeza hacia la izquierda
      }
    }

    // Rotación vertical (eulerY) - solo si no hay rotación horizontal significativa
    if (eulerY > threshold) {
      return HeadPose.down; // Cabeza hacia abajo
    } else if (eulerY < -threshold) {
      return HeadPose.up; // Cabeza hacia arriba
    }

    return HeadPose.front; // Frente (ángulos cercanos a 0)
  }

  /// Validar si el pose detectado coincide con el requerido
  /// Retorna (isValid, progress) donde progress es 0.0 a 1.0
  (bool, double) _validatePose(
    HeadPose detected,
    HeadPose required,
    double? eulerY,
    double? eulerZ,
  ) {
    if (eulerY == null || eulerZ == null) {
      return (false, 0.0);
    }

    // Umbral unificado para todos los movimientos (5°)
    const unifiedThreshold = 5.0;
    // Umbral para la otra dimensión (más permisivo para evitar falsos negativos)
    const otherThreshold = 25.0;

    // Calcular progreso hacia la pose correcta (0.0 a 1.0)
    double calculateProgress() {
      switch (required) {
        case HeadPose.front:
          // Progreso basado en qué tan cerca está de 0° en ambas dimensiones
          final yProgress = (1.0 - (eulerY.abs() / unifiedThreshold)).clamp(0.0, 1.0);
          final zProgress = (1.0 - (eulerZ.abs() / unifiedThreshold)).clamp(0.0, 1.0);
          return (yProgress + zProgress) / 2.0;
        case HeadPose.up:
          // Progreso basado en qué tan negativo es eulerY
          if (eulerY >= 0) return 0.0; // No está mirando arriba
          final yProgress = (eulerY.abs() / unifiedThreshold).clamp(0.0, 1.0);
          final zProgress = (1.0 - (eulerZ.abs() / otherThreshold)).clamp(0.0, 1.0);
          return (yProgress * 0.7 + zProgress * 0.3);
        case HeadPose.down:
          // Progreso basado en qué tan positivo es eulerY
          if (eulerY <= 0) return 0.0; // No está mirando abajo
          final yProgress = (eulerY / unifiedThreshold).clamp(0.0, 1.0);
          final zProgress = (1.0 - (eulerZ.abs() / otherThreshold)).clamp(0.0, 1.0);
          return (yProgress * 0.7 + zProgress * 0.3);
        case HeadPose.left:
          // Progreso basado en qué tan negativo es eulerZ
          if (eulerZ >= 0) return 0.0; // No está girando a la izquierda
          final zProgress = (eulerZ.abs() / unifiedThreshold).clamp(0.0, 1.0);
          final yProgress = (1.0 - (eulerY.abs() / otherThreshold)).clamp(0.0, 1.0);
          return (zProgress * 0.7 + yProgress * 0.3);
        case HeadPose.right:
          // Progreso basado en qué tan positivo es eulerZ
          if (eulerZ <= 0) return 0.0; // No está girando a la derecha
          final zProgress = (eulerZ / unifiedThreshold).clamp(0.0, 1.0);
          final yProgress = (1.0 - (eulerY.abs() / otherThreshold)).clamp(0.0, 1.0);
          return (zProgress * 0.7 + yProgress * 0.3);
      }
    }

    final progress = calculateProgress();

    switch (required) {
      case HeadPose.front:
        final isValid = eulerY.abs() < unifiedThreshold && eulerZ.abs() < unifiedThreshold;
        return (isValid, progress);
      case HeadPose.up:
        final isValid = eulerY < -unifiedThreshold && eulerZ.abs() < otherThreshold;
        return (isValid, progress);
      case HeadPose.down:
        final isValid = eulerY > unifiedThreshold && eulerZ.abs() < otherThreshold;
        return (isValid, progress);
      case HeadPose.left:
        final isValid = eulerZ < -unifiedThreshold && eulerY.abs() < otherThreshold;
        if (!isValid) {
          _logger.d('❌ Left no válido - eulerZ: $eulerZ (necesita < -$unifiedThreshold), eulerY: $eulerY, progreso: ${(progress * 100).toStringAsFixed(1)}%');
        } else {
          _logger.d('✅ Left válido - eulerZ: $eulerZ, eulerY: $eulerY, progreso: ${(progress * 100).toStringAsFixed(1)}%');
        }
        return (isValid, progress);
      case HeadPose.right:
        final isValid = eulerZ > unifiedThreshold && eulerY.abs() < otherThreshold;
        if (!isValid) {
          _logger.d('❌ Right no válido - eulerZ: $eulerZ (necesita > $unifiedThreshold), eulerY: $eulerY, progreso: ${(progress * 100).toStringAsFixed(1)}%');
        } else {
          _logger.d('✅ Right válido - eulerZ: $eulerZ, eulerY: $eulerY, progreso: ${(progress * 100).toStringAsFixed(1)}%');
        }
        return (isValid, progress);
    }
  }

  /// Obtener instrucción para el pose requerido
  String _getPoseInstruction(HeadPose pose) {
    switch (pose) {
      case HeadPose.front:
        return 'Mira directamente a la cámara';
      case HeadPose.up:
        return 'Gira tu cabeza hacia arriba';
      case HeadPose.down:
        return 'Gira tu cabeza hacia abajo';
      case HeadPose.left:
        return 'Gira tu cabeza hacia tu izquierda';
      case HeadPose.right:
        return 'Gira tu cabeza hacia tu derecha';
    }
  }

  /// Liberar recursos
  Future<void> dispose() async {
    await _faceDetector.close();
  }
}

