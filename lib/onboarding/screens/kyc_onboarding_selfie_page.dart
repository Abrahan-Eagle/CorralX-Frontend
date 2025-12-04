import 'dart:io';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:provider/provider.dart';

import 'package:corralx/kyc/providers/kyc_provider.dart';
import 'package:corralx/shared/services/liveness_detection_service.dart';

/// Página para capturar la selfie del usuario con liveness detection.
class KycOnboardingSelfiePage extends StatefulWidget {
  const KycOnboardingSelfiePage({super.key});

  @override
  State<KycOnboardingSelfiePage> createState() =>
      _KycOnboardingSelfiePageState();
}

class _KycOnboardingSelfiePageState extends State<KycOnboardingSelfiePage> {
  CameraController? _cameraController;
  bool _isInitializing = false;
  bool _isProcessing = false;
  bool _isLivenessActive = false;
  
  // Secuencia de poses para liveness detection
  final List<HeadPose> _livenessSequence = [
    HeadPose.front,
    HeadPose.up,
    HeadPose.down,
    HeadPose.left,
    HeadPose.right,
  ];
  
  int _currentStep = 0;
  Map<HeadPose, bool> _completedSteps = {};
  XFile? _capturedSelfie;
  LivenessDetectionService? _livenessService;
  Timer? _analysisTimer;
  String? _currentInstruction;
  bool _isFaceDetected = false;
  double _poseProgress = 0.0; // Progreso hacia la pose correcta (0.0 a 1.0)
  double _smoothedProgress = 0.0; // Progreso suavizado para evitar fluctuaciones
  int? _holdStillCountdown; // Contador para mantenerse quieto
  DateTime? _validPoseStartTime; // Tiempo cuando se detectó el pose correcto
  String? _directionHint; // Pista direccional para ayudar al usuario

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _livenessService = LivenessDetectionService();
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

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        // Iniciar liveness detection automáticamente después de inicializar
        _startLivenessDetection();
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

  void _startLivenessDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isLivenessActive = true;
      _currentStep = 0;
      _completedSteps = {};
      _currentInstruction = _getInstructionForPose(_livenessSequence[0]);
    });

    _startImageStream();
  }

  bool _isAnalyzing = false;
  DateTime? _lastAnalysisTime;
  Timer? _countdownTimer;

  /// Iniciar stream de imágenes y procesar frames con throttling
  void _startImageStream() {
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

      if (!_isLivenessActive ||
          _currentStep >= _livenessSequence.length ||
          _isAnalyzing) {
        return;
      }

      _lastAnalysisTime = now;
      _isAnalyzing = true;

      try {
        final requiredPose = _livenessSequence[_currentStep];
        // Determinar rotación basada en la orientación del dispositivo y la cámara
        // Para cámara frontal en modo portrait, la imagen viene rotada
        final deviceOrientation = _cameraController!.value.deviceOrientation;
        final isPortrait = deviceOrientation == DeviceOrientation.portraitUp ||
            deviceOrientation == DeviceOrientation.portraitDown;
        
        // Cámara frontal: en portrait la imagen viene rotada 270° (o 90° dependiendo del dispositivo)
        // Probar con diferentes rotaciones si no detecta
        InputImageRotation rotation;
        if (isPortrait) {
          // Para cámara frontal en portrait, probar primero con 270°
          rotation = InputImageRotation.rotation270deg;
        } else {
          rotation = InputImageRotation.rotation0deg;
        }

        final result = await _livenessService!.analyzeCameraImage(
          cameraImage: image,
          requiredPose: requiredPose,
          rotation: rotation,
        );

        if (!mounted) {
          _isAnalyzing = false;
          return;
        }

        setState(() {
          _isFaceDetected = result.detectedPose != null;
          _poseProgress = result.progress; // Actualizar progreso
          
          // Suavizar el progreso para evitar fluctuaciones (filtro exponencial)
          const smoothingFactor = 0.3; // 0.0 = sin suavizado, 1.0 = completamente suavizado
          _smoothedProgress = _smoothedProgress * (1 - smoothingFactor) + _poseProgress * smoothingFactor;
          
          // Calcular pista direccional basada en los ángulos de Euler
          _directionHint = _calculateDirectionHint(requiredPose, result.headEulerY, result.headEulerZ);
          
          _currentInstruction =
              result.errorMessage ?? _getInstructionForPose(requiredPose);
        });

        // Si el pose es válido, iniciar contador para mantenerse quieto
        // Tiempo adaptativo: menos tiempo si el progreso es muy alto
        if (result.isValid) {
          if (_validPoseStartTime == null) {
            // Primera vez que se detecta el pose correcto
            _validPoseStartTime = DateTime.now();
            // Tiempo adaptativo: 0.5s si progreso > 90%, 1s si > 70%, 1.5s si menor
            final adaptiveTime = result.progress >= 0.9 
                ? 0.5 
                : result.progress >= 0.7 
                    ? 1.0 
                    : 1.5;
            _holdStillCountdown = adaptiveTime.ceil();
            
            // Iniciar timer para actualizar el contador (cada 200ms para feedback más fluido)
            _countdownTimer?.cancel();
            final targetTimeMs = _holdStillCountdown! * 1000; // Convertir a milisegundos
            _countdownTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
              if (!mounted || _validPoseStartTime == null) {
                timer.cancel();
                return;
              }
              
              final elapsed = DateTime.now().difference(_validPoseStartTime!).inMilliseconds;
              final remainingMs = targetTimeMs - elapsed;
              final remaining = (remainingMs / 1000).ceil().clamp(0, _holdStillCountdown!); // Redondear hacia arriba
              
              if (remainingMs <= 0) {
                timer.cancel();
                if (mounted && !_completedSteps.containsKey(requiredPose)) {
                  // Tiempo suficiente, avanzar al siguiente paso
                  setState(() {
                    _completedSteps[requiredPose] = true;
                    _currentStep++;
                    _validPoseStartTime = null;
                    _holdStillCountdown = null;
                  });

                  if (_currentStep < _livenessSequence.length) {
                    // Esperar un momento antes del siguiente paso
                    Future.delayed(const Duration(milliseconds: 500)).then((_) {
                      if (mounted && _isLivenessActive) {
                        setState(() {
                          _currentInstruction =
                              _getInstructionForPose(_livenessSequence[_currentStep]);
                        });
                      }
                    });
                  } else {
                    // Secuencia completada, capturar selfie final
                    _captureFinalSelfie();
                  }
                }
              } else {
                setState(() {
                  _holdStillCountdown = remaining > 0 ? remaining : 1;
                });
              }
            });
          }
        } else {
          // Pose no válido, resetear contador solo si ha pasado suficiente tiempo
          // Esto permite pequeñas variaciones sin resetear completamente
          if (_validPoseStartTime != null) {
            final elapsed = DateTime.now().difference(_validPoseStartTime!).inMilliseconds;
            // Solo resetear si ha pasado más de 300ms sin pose válido
            if (elapsed > 300) {
              _countdownTimer?.cancel();
              _validPoseStartTime = null;
              _holdStillCountdown = null;
            }
          } else {
            _countdownTimer?.cancel();
            _validPoseStartTime = null;
            _holdStillCountdown = null;
          }
        }
      } catch (e) {
        debugPrint('Error analizando frame: $e');
        // Continuar procesando frames
      } finally {
        _isAnalyzing = false;
      }
    });
  }

  Future<void> _captureFinalSelfie() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _isLivenessActive = false;
    });

    try {
      // Detener el stream si está activo
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      
      // Esperar un momento para que la cámara se estabilice
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Capturar la foto final
      final image = await _cameraController!.takePicture();
      
      if (mounted) {
        setState(() {
          _capturedSelfie = image;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Error capturando selfie final: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isLivenessActive = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar la selfie: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Calcular pista direccional basada en los ángulos de Euler
  String? _calculateDirectionHint(HeadPose requiredPose, double? eulerY, double? eulerZ) {
    if (eulerY == null || eulerZ == null) return null;
    
    const threshold = 5.0;
    
    switch (requiredPose) {
      case HeadPose.right:
        if (eulerZ < 0) {
          return 'Gira más hacia la derecha →';
        } else if (eulerZ < threshold) {
          return 'Un poco más a la derecha →';
        }
        break;
      case HeadPose.left:
        if (eulerZ > 0) {
          return 'Gira más hacia la izquierda ←';
        } else if (eulerZ > -threshold) {
          return 'Un poco más a la izquierda ←';
        }
        break;
      case HeadPose.up:
        if (eulerY > 0) {
          return 'Mira más hacia arriba ↑';
        } else if (eulerY > -threshold) {
          return 'Un poco más arriba ↑';
        }
        break;
      case HeadPose.down:
        if (eulerY < 0) {
          return 'Mira más hacia abajo ↓';
        } else if (eulerY < threshold) {
          return 'Un poco más abajo ↓';
        }
        break;
      case HeadPose.front:
        if (eulerY.abs() > threshold || eulerZ.abs() > threshold) {
          if (eulerY.abs() > eulerZ.abs()) {
            return eulerY > 0 ? 'Mira más arriba ↑' : 'Mira más abajo ↓';
          } else {
            return eulerZ > 0 ? 'Gira más a la derecha →' : 'Gira más a la izquierda ←';
          }
        }
        break;
    }
    return null;
  }

  String _getInstructionForPose(HeadPose pose) {
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

  Future<bool> submitSelfieIfNeeded() async {
    if (_capturedSelfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes completar la verificación facial para continuar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    final kycProvider = Provider.of<KycProvider>(context, listen: false);
    final success = await kycProvider.submitSelfie(_capturedSelfie!);

    if (!success && mounted) {
      final error = kycProvider.errorMessage ??
          'No se pudo enviar la selfie. Intenta nuevamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    return success;
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _countdownTimer?.cancel();
    // Detener stream antes de dispose
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _cameraController?.dispose();
    _livenessService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            
            final cardWidth = isTablet 
                ? (screenWidth * 0.6).clamp(300.0, 400.0)
                : (screenWidth * 0.85).clamp(250.0, double.infinity);
            
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32.0 : 16.0,
                vertical: isTablet ? 20.0 : 12.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Header
                  Text(
                    'Verificación facial',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLivenessActive
                        ? 'Coloca tu rostro dentro del óvalo y sigue las instrucciones.'
                        : 'Sigue las instrucciones y mueve tu cabeza según se indique.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.8),
                    ),
                  ),
                    const SizedBox(height: 16),

                    // Cámara preview con guía
                    Center(
                      child: Container(
                        width: cardWidth,
                        constraints: BoxConstraints(maxWidth: cardWidth),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _capturedSelfie != null
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.3),
                            width: _capturedSelfie != null ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: _buildCameraPreview(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Indicador visual de proximidad a la pose correcta
                    if (_isLivenessActive && _capturedSelfie == null)
                      _buildPoseProgressIndicator(context),

                    // Indicador de progreso (sin botón aquí)
                    if (_isLivenessActive || (_capturedSelfie == null && !_isInitializing))
                      _buildProgressIndicators(context),
                    
                    if (_capturedSelfie != null)
                      _buildSuccessMessage(context),
                    
                    // Botón "Comenzar verificación" - solo cuando no está activo
                    if (!_isLivenessActive && _capturedSelfie == null && !_isInitializing)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isProcessing || _isInitializing) ? null : _startLivenessDetection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: (_isProcessing || _isInitializing)
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Comenzar verificación',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    
                    // Upload indicator
                    Consumer<KycProvider>(
                      builder: (context, kyc, child) {
                        if (kyc.isUploading) {
                          return Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Subiendo selfie...',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    // Espacio adicional al final para evitar que choque con el botón siguiente
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Inicializando cámara...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_capturedSelfie != null) {
      return Stack(
        children: [
          Image.file(
            File(_capturedSelfie!.path),
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () async {
                  // Detener stream si está activo
                  if (_cameraController != null && 
                      _cameraController!.value.isStreamingImages) {
                    await _cameraController!.stopImageStream();
                  }
                  _countdownTimer?.cancel();
                  setState(() {
                    _capturedSelfie = null;
                    _currentStep = 0;
                    _completedSteps = {};
                    _isLivenessActive = false;
                    _isFaceDetected = false;
                    _currentInstruction = null;
                    _validPoseStartTime = null;
                    _holdStillCountdown = null;
                  });
                  // Reiniciar liveness detection
                  if (_cameraController != null && _cameraController!.value.isInitialized) {
                    _startLivenessDetection();
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Cámara que ocupa todo el espacio
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        // Fondo oscuro fuera del óvalo (como Onfido)
        CustomPaint(
          size: Size.infinite,
          painter: FaceGuidePainter(
            isFaceDetected: _isFaceDetected,
            progress: _currentStep / _livenessSequence.length,
            showHoldStill: _holdStillCountdown != null && _holdStillCountdown! > 0,
            countdown: _holdStillCountdown,
          ),
        ),
        // Instrucción principal en la parte superior
        if (_isLivenessActive)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  _isFaceDetected && _holdStillCountdown != null && _holdStillCountdown! > 0
                      ? 'Mantén la posición... ${_holdStillCountdown}s'
                      : _isFaceDetected
                          ? 'Mantén tu rostro dentro del óvalo'
                          : 'Coloca tu rostro dentro del óvalo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        // Instrucción de movimiento en la parte inferior
        if (_isLivenessActive && _currentInstruction != null && _holdStillCountdown == null)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flecha direccional
                  if (_currentStep < _livenessSequence.length)
                    _buildDirectionArrow(_livenessSequence[_currentStep]),
                  const SizedBox(height: 8),
                  // Texto de instrucción
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentInstruction!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Indicador visual de proximidad a la pose correcta (MEJORADO)
  Widget _buildPoseProgressIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Usar progreso suavizado para mejor UX
    final displayProgress = _smoothedProgress;
    
    // Determinar color según el progreso (con animación suave)
    Color progressColor;
    IconData statusIcon;
    String statusText;
    
    if (displayProgress >= 0.8) {
      progressColor = Colors.green; // Casi listo
      statusIcon = Icons.check_circle;
      statusText = '¡Perfecto! Mantén la posición';
    } else if (displayProgress >= 0.5) {
      progressColor = Colors.orange; // Medio
      statusIcon = Icons.trending_up;
      statusText = '¡Bien! Continúa ajustando';
    } else {
      progressColor = Colors.red; // Lejos
      statusIcon = Icons.info_outline;
      statusText = 'Ajusta tu posición';
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: displayProgress >= 0.8 
              ? progressColor.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.3),
          width: displayProgress >= 0.8 ? 2 : 1,
        ),
        boxShadow: displayProgress >= 0.8
            ? [
                BoxShadow(
                  color: progressColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    statusIcon,
                    size: 18,
                    color: progressColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ajusta tu posición',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(displayProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barra de progreso mejorada
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Fondo
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Progreso con animación
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 8,
                  width: MediaQuery.of(context).size.width * 0.7 * displayProgress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        progressColor,
                        progressColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          // Pista direccional si está disponible
          if (_directionHint != null && displayProgress < 0.8)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    size: 14,
                    color: progressColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _directionHint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: progressColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (displayProgress >= 0.8)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: progressColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicators(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Indicador de progreso con números
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _livenessSequence.length,
            (index) => Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _currentStep
                        ? colorScheme.primary
                        : index == _currentStep
                            ? colorScheme.primary.withOpacity(0.5)
                            : colorScheme.outline.withOpacity(0.3),
                    border: Border.all(
                      color: index == _currentStep
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: index < _currentStep
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: colorScheme.onPrimary,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index == _currentStep
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < _livenessSequence.length - 1)
                  Container(
                    width: 20,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: index < _currentStep
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.3),
                  ),
              ],
            ),
          ),
        ),
        // Instrucción actual
        if (_isLivenessActive && _currentInstruction != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentInstruction!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDirectionArrow(HeadPose pose) {
    IconData icon;
    double rotation = 0;

    switch (pose) {
      case HeadPose.front:
        icon = Icons.arrow_upward;
        rotation = 0;
        break;
      case HeadPose.up:
        icon = Icons.arrow_upward;
        rotation = 0;
        break;
      case HeadPose.down:
        icon = Icons.arrow_downward;
        rotation = 0;
        break;
      case HeadPose.left:
        icon = Icons.arrow_back;
        rotation = 0;
        break;
      case HeadPose.right:
        icon = Icons.arrow_forward;
        rotation = 0;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: Transform.rotate(
        angle: rotation,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verificación facial completada',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter para dibujar la guía visual de la cara (estilo Onfido)
class FaceGuidePainter extends CustomPainter {
  final bool isFaceDetected;
  final double progress;
  final bool showHoldStill;
  final int? countdown;

  FaceGuidePainter({
    required this.isFaceDetected,
    required this.progress,
    this.showHoldStill = false,
    this.countdown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar fondo oscuro fuera del óvalo (estilo Onfido)
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Óvalo guía en el centro
    final center = Offset(size.width / 2, size.height / 2);
    final ovalWidth = size.width * 0.75;
    final ovalHeight = size.height * 0.65;
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );
    
    final ovalPath = Path()..addOval(ovalRect);
    
    // Recortar el fondo para mostrar solo el área del óvalo
    final clippedPath = Path.combine(PathOperation.difference, backgroundPath, ovalPath);
    canvas.drawPath(
      clippedPath,
      Paint()..color = Colors.black.withOpacity(0.6),
    );

    // Dibujar borde del óvalo (MUY visible - triple borde)
    // Borde exterior (más grueso para mejor visibilidad)
    final outerBorderPaint = Paint()
      ..color = isFaceDetected ? Colors.green.withOpacity(0.4) : Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;
    canvas.drawOval(ovalRect, outerBorderPaint);
    
    // Borde medio
    final middleBorderPaint = Paint()
      ..color = isFaceDetected ? Colors.green.withOpacity(0.7) : Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    canvas.drawOval(ovalRect, middleBorderPaint);
    
    // Borde interior (principal - muy visible)
    final borderPaint = Paint()
      ..color = isFaceDetected ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawOval(ovalRect, borderPaint);

    // Dibujar arco de progreso alrededor del óvalo
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.14159 * progress;
      canvas.drawArc(
        ovalRect,
        -3.14159 / 2, // Empezar desde arriba
        sweepAngle,
        false,
        progressPaint,
      );
    }
    
    // Dibujar contador si está activo
    if (showHoldStill && countdown != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$countdown',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(FaceGuidePainter oldDelegate) {
    return oldDelegate.isFaceDetected != isFaceDetected ||
        oldDelegate.progress != progress ||
        oldDelegate.showHoldStill != showHoldStill ||
        oldDelegate.countdown != countdown;
  }
}
