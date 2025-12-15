import 'dart:io';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:corralx/shared/services/selfie_with_doc_validation_service.dart';

/// Página para capturar selfie sosteniendo el documento de identidad con validación en tiempo real.
class KycOnboardingSelfieWithDocPage extends StatefulWidget {
  const KycOnboardingSelfieWithDocPage({super.key});

  @override
  State<KycOnboardingSelfieWithDocPage> createState() =>
      _KycOnboardingSelfieWithDocPageState();
}

class _KycOnboardingSelfieWithDocPageState
    extends State<KycOnboardingSelfieWithDocPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  CameraController? _cameraController;
  bool _isInitializing = false;
  bool _isProcessing = false;
  
  XFile? _capturedSelfieWithDoc;
  SelfieWithDocValidationService? _validationService;
  
  // Estado de validación en tiempo real
  bool _isValid = false;
  bool _hasFace = false;
  bool _hasDocument = false;
  double _faceConfidence = 0.0;
  double _documentConfidence = 0.0;
  String? _validationMessage;
  
  Timer? _analysisTimer;
  Timer? _focusTimer;
  DateTime? _lastAnalysisTime;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _validationService = SelfieWithDocValidationService();
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _focusTimer?.cancel();
    _cameraController?.dispose();
    _validationService?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      // Configurar enfoque continuo para mantener tanto rostro como documento enfocados
      // Usar modo auto que ajusta el enfoque automáticamente
      try {
        // Solo configurar modo de enfoque, sin punto específico (la cámara frontal puede no soportarlo)
        await _cameraController!.setFocusMode(FocusMode.auto);
        // Ajustar exposición para mejor visibilidad de ambos elementos
        await _cameraController!.setExposureMode(ExposureMode.auto);
        debugPrint('✅ Enfoque automático configurado');
      } catch (e) {
        debugPrint('⚠️ No se pudo configurar enfoque: $e');
        // Continuar sin configuración de enfoque si falla
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        // Iniciar validación en tiempo real después de inicializar
        _startRealTimeValidation();
        // Iniciar ajuste periódico de enfoque
        _startPeriodicFocusAdjustment();
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al acceder a la cámara: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Iniciar validación en tiempo real del stream de cámara
  void _startRealTimeValidation() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) async {
      // Throttling: procesar solo cada 800ms
      final now = DateTime.now();
      if (_lastAnalysisTime != null &&
          now.difference(_lastAnalysisTime!).inMilliseconds < 800) {
        return;
      }

      if (_isAnalyzing || _isProcessing || _capturedSelfieWithDoc != null) {
        return;
      }

      _lastAnalysisTime = now;
      _isAnalyzing = true;

      try {
        final deviceOrientation = _cameraController!.value.deviceOrientation;
        final isPortrait = deviceOrientation == DeviceOrientation.portraitUp ||
            deviceOrientation == DeviceOrientation.portraitDown;
        
        InputImageRotation rotation;
        if (isPortrait) {
          rotation = InputImageRotation.rotation270deg;
        } else {
          rotation = InputImageRotation.rotation0deg;
        }

        final result = await _validationService!.validateCameraImage(
          cameraImage: image,
          rotation: rotation,
        );

        if (!mounted) {
          _isAnalyzing = false;
          return;
        }

        setState(() {
          _isValid = result.isValid;
          _hasFace = result.hasFace;
          _hasDocument = result.hasDocument;
          _faceConfidence = result.faceConfidence;
          _documentConfidence = result.documentConfidence;
          _validationMessage = result.errorMessage;
        });
      } catch (e) {
        debugPrint('Error analizando frame: $e');
      } finally {
        _isAnalyzing = false;
      }
    });
  }

  /// Ajustar enfoque periódicamente para mantener tanto rostro como documento enfocados
  void _startPeriodicFocusAdjustment() {
    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_cameraController == null || 
          !_cameraController!.value.isInitialized ||
          _capturedSelfieWithDoc != null) {
        timer.cancel();
        return;
      }

      try {
        // Solo reajustar modo de enfoque (sin punto específico, ya que puede no estar soportado)
        // El modo auto debería mantener ambos elementos enfocados automáticamente
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (e) {
        // Silenciar error si no se puede ajustar (algunas cámaras no lo soportan)
        // debugPrint('⚠️ Error ajustando enfoque: $e');
      }
    });
  }

  /// Capturar selfie con documento (solo si es válida)
  Future<void> _captureSelfieWithDoc() async {
    if (!_isValid) {
      // Mostrar mensaje de error si no es válida
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _validationMessage ?? 
            'Asegúrate de que tu rostro y el documento CI sean claramente visibles antes de capturar.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('❌ KYC: Cámara no inicializada para capturar selfie con documento.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Detener el stream si está activo
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      
      // Esperar un momento para que la cámara se estabilice
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Capturar la foto
      debugPrint('📸 KYC: Tomando selfie con documento...');
      final image = await _cameraController!.takePicture();
      
      // Validar la foto capturada
      debugPrint('🔍 KYC: Validando foto capturada...');
      final validationResult = await _validationService!.validateImageFile(image.path);

      // Si la foto capturada no es válida, rechazarla
      if (!validationResult.isValid) {
        debugPrint('❌ KYC: Foto capturada no es válida. Rostro: ${validationResult.hasFace} (${(validationResult.faceConfidence * 100).toStringAsFixed(1)}%), Documento: ${validationResult.hasDocument} (${(validationResult.documentConfidence * 100).toStringAsFixed(1)}%)');
        
        // Eliminar la foto inválida
        try {
          final file = File(image.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error eliminando foto inválida: $e');
        }

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          // Reiniciar stream de validación
          _startRealTimeValidation();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                validationResult.errorMessage ?? 
                'La foto no es válida. Asegúrate de que tu rostro y el documento CI sean claramente visibles.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      debugPrint('✅ KYC: Foto capturada es válida');
      
      if (mounted) {
        setState(() {
          _capturedSelfieWithDoc = image;
          _isProcessing = false;
        });
        
        // Guardar ruta de la imagen en storage para subirla después
        await _storage.write(key: 'kyc_selfie_with_doc_path', value: image.path);
        debugPrint('💾 KYC: Selfie con documento guardada en storage: ${image.path}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto capturada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ KYC: Error capturando selfie con documento: $e');
      debugPrint('❌ KYC: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar la foto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Reiniciar stream si falló
        _startRealTimeValidation();
      }
    }
  }


  Future<bool> submitSelfieWithDocIfNeeded() async {
    if (_capturedSelfieWithDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes tomar una selfie sosteniendo tu CI para continuar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // La validación ya se hizo antes de capturar, así que si llegamos aquí es válida
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    // Offset inferior del badge de validación adaptado a la altura de la pantalla
    final validationBottomOffset =
        (screenHeight * 0.16).clamp(80.0, 140.0); // responsive

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al inicializar la cámara',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vista previa de la cámara
          CameraPreview(_cameraController!),
          
          // Overlay con instrucciones y estado de validación
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Título
                    Text(
                      'Selfie con documento',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Instrucciones mejoradas
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.yellow[300], size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Sostén tu CI junto a tu rostro a la misma distancia',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.7),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wb_sunny_outlined, color: Colors.orange[300], size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Buena iluminación ayuda',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Guías visuales (marcos semitransparentes) para indicar posición
          if (_capturedSelfieWithDoc == null)
            Stack(
              children: [
                // Marco para el rostro (centro-superior)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.25,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _hasFace && _faceConfidence >= 0.5
                              ? Colors.green.withOpacity(0.6)
                              : Colors.white.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(90),
                      ),
                      child: _hasFace && _faceConfidence >= 0.5
                          ? Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green.withOpacity(0.7),
                                size: 30,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                // Marco para el documento (centro-inferior)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 160,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _hasDocument && _documentConfidence >= 0.3
                              ? Colors.green.withOpacity(0.6)
                              : Colors.white.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _hasDocument && _documentConfidence >= 0.3
                          ? Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green.withOpacity(0.7),
                                size: 25,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),

          // Indicador de validación en tiempo real (abajo, más visible)
          if (_capturedSelfieWithDoc == null)
            Positioned(
              bottom: validationBottomOffset,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: _isValid 
                        ? Colors.green.withOpacity(0.9)
                        : Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isValid ? Icons.check_circle : Icons.info_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _isValid 
                                  ? '✅ Listo para capturar'
                                  : (_validationMessage ?? 'Ajusta tu posición'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      if (!_isValid) ...[
                        const SizedBox(height: 8),
                        // Indicadores de estado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Indicador de rostro
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _hasFace && _faceConfidence >= 0.5
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _hasFace && _faceConfidence >= 0.5
                                        ? Icons.check
                                        : Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rostro ${(_faceConfidence * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Indicador de documento
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _hasDocument && _documentConfidence >= 0.3
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _hasDocument && _documentConfidence >= 0.3
                                        ? Icons.check
                                        : Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'CI ${(_documentConfidence * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Botón de captura (abajo)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview de foto capturada (si existe)
                    if (_capturedSelfieWithDoc != null) ...[
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(
                            File(_capturedSelfieWithDoc!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Foto válida capturada',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Botón para tomar otra foto
                      OutlinedButton.icon(
                        onPressed: _isProcessing ? null : () {
                          setState(() {
                            _capturedSelfieWithDoc = null;
                          });
                          _startRealTimeValidation();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tomar otra foto'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ] else ...[
                      // Botón de captura circular
                      GestureDetector(
                        onTap: _isProcessing ? null : _captureSelfieWithDoc,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isValid 
                                ? Colors.green
                                : Colors.grey.withOpacity(0.5),
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isProcessing
                              ? const Center(
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 40,
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
