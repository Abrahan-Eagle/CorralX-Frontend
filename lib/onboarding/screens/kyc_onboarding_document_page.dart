import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:corralx/kyc/providers/kyc_provider.dart';
import 'package:corralx/kyc/services/kyc_service.dart';
import 'package:corralx/shared/utils/ocr_utils.dart';

/// Página de captura del documento de identidad (CI venezolana) y RIF.
class KycOnboardingDocumentPage extends StatefulWidget {
  const KycOnboardingDocumentPage({super.key});

  @override
  State<KycOnboardingDocumentPage> createState() =>
      _KycOnboardingDocumentPageState();
}

class _KycOnboardingDocumentPageState extends State<KycOnboardingDocumentPage> {
  XFile? _ciImage;
  XFile? _rifImage;
  bool _isCapturing = false;
  bool _isProcessingOCR = false;
  bool _isExtractingWithGemini = false;
  bool _geminiExtractionDone = false;
  bool? _ciMatchedByIa;
  bool? _rifMatchedByIa;
  bool? _isCiValid;
  bool? _isRifValid;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final KycService _kycService = KycService();

  // Almacenar datos del OCR para comparar con Gemini
  Map<String, dynamic>? _ocrCiData;
  Map<String, dynamic>? _ocrRifData;

  Future<void> _captureImage({
    required bool isCI,
  }) async {
    setState(() {
      _isCapturing = true;
    });

    try {
      XFile? image;

      if (isCI) {
        // Nueva pantalla dedicada para captura de CI con marco guía
        image = await Navigator.of(context).push<XFile?>(
          MaterialPageRoute(builder: (_) => const _CiCameraCapturePage()),
        );
      } else {
        // Nueva pantalla dedicada para captura de RIF con marco guía horizontal
        image = await Navigator.of(context).push<XFile?>(
          MaterialPageRoute(builder: (_) => const _RifCameraCapturePage()),
        );
      }

      if (image != null && mounted) {
        setState(() {
          if (isCI) {
            _ciImage = image;
          } else {
            _rifImage = image;
          }
        });

        // Guardar ruta de la imagen en storage para subirla después
        await _storage.write(
          key: isCI ? 'kyc_ci_path' : 'kyc_rif_path',
          value: image.path,
        );
        debugPrint(
            '💾 KYC: ${isCI ? "CI" : "RIF"} guardada en storage: ${image.path}');

        // Procesar OCR automáticamente después de capturar
        if (isCI) {
          await _processCIOCR(image);
        } else {
          await _processRIFOCR(image);
        }
      }
    } catch (e) {
      debugPrint('Error capturando imagen: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo tomar la foto: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _processCIOCR(XFile image) async {
    setState(() {
      _isProcessingOCR = true;
    });

    try {
      final ciFile = File(image.path);
      final ciData = await OCRUtils.extractCIData(ciFile);

      // Log detallado en consola con los datos extraídos de la CI
      debugPrint('📄 OCR CI - datos extraídos: ${ciData.toJson()}');

      // Guardar datos extraídos para pre-llenar formularios
      if (ciData.firstName != null ||
          ciData.lastName != null ||
          ciData.ciNumber != null ||
          ciData.dateOfBirth != null) {
        final ciDataJson = ciData.toJson();
        _ocrCiData = ciDataJson; // Guardar para comparar con Gemini
        await _storage.write(
          key: 'kyc_extracted_ci_data',
          value: jsonEncode(ciDataJson),
        );
        debugPrint('✅ Datos CI guardados para pre-llenar formularios');

        // Validación ligera local: verificar formato de número de CI venezolano
        final ciNumber = ciData.ciNumber?.toString().trim();
        if (ciNumber != null && ciNumber.isNotEmpty) {
          // Formato típico: V-12345678, E-12345678, con o sin guion
          final ciRegex = RegExp(r'^[VE]-?\d{5,9}$', caseSensitive: false);
          final isValid = ciRegex.hasMatch(ciNumber);
          debugPrint(
              '🔎 Validación local CI - número: $ciNumber, válido: $isValid');
          _isCiValid = isValid;
        } else {
          debugPrint('🔎 Validación local CI - número no encontrado');
          _isCiValid = false;
        }
      }

      // Si ya tenemos ambas imágenes, llamar a Gemini
      if (_ciImage != null && _rifImage != null && !_geminiExtractionDone) {
        await _extractDataWithGemini();
      }
    } catch (e) {
      debugPrint('Error procesando OCR de CI: $e');
      // No mostrar error al usuario, solo log
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOCR = false;
        });
      }
    }
  }

  Future<void> _processRIFOCR(XFile image) async {
    setState(() {
      _isProcessingOCR = true;
    });

    try {
      final rifFile = File(image.path);
      final rifData = await OCRUtils.extractRIFData(rifFile);

      // Log detallado en consola con los datos extraídos del RIF
      debugPrint('📄 OCR RIF - datos extraídos: ${rifData.toJson()}');

      // Guardar datos extraídos para pre-llenar formularios
      if (rifData.businessName != null || rifData.rifNumber != null) {
        final rifDataJson = rifData.toJson();
        _ocrRifData = rifDataJson; // Guardar para comparar con Gemini
        await _storage.write(
          key: 'kyc_extracted_rif_data',
          value: jsonEncode(rifDataJson),
        );
        debugPrint('✅ Datos RIF guardados para pre-llenar formularios');

        // Validación ligera local: verificar formato de RIF venezolano
        final rifNumber = rifData.rifNumber?.toString().trim();
        if (rifNumber != null && rifNumber.isNotEmpty) {
          // Formato típico: J-12345678-9, V-12345678-9, etc.
          final rifRegex = RegExp(r'^[JGVEP]-\d{8}-\d$', caseSensitive: false);
          final isValid = rifRegex.hasMatch(rifNumber);
          debugPrint(
              '🔎 Validación local RIF - número: $rifNumber, válido: $isValid');
          _isRifValid = isValid;
        } else {
          debugPrint('🔎 Validación local RIF - número no encontrado');
          _isRifValid = false;
        }
      }

      // Si ya tenemos ambas imágenes, llamar a Gemini
      if (_ciImage != null && _rifImage != null && !_geminiExtractionDone) {
        await _extractDataWithGemini();
      }
    } catch (e) {
      debugPrint('Error procesando OCR de RIF: $e');
      // No mostrar error al usuario, solo log
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOCR = false;
        });
      }
    }
  }

  /// Extraer datos con Gemini AI y comparar con OCR
  Future<void> _extractDataWithGemini() async {
    if (_geminiExtractionDone || _isExtractingWithGemini) {
      return;
    }

    if (_ciImage == null || _rifImage == null) {
      debugPrint('⚠️ KYC: No se puede extraer con Gemini: faltan imágenes');
      return;
    }

    setState(() {
      _isExtractingWithGemini = true;
    });

    try {
      debugPrint('🤖 KYC: Extrayendo datos con Gemini AI...');

      final result = await _kycService.extractDocumentDataWithGemini(
        ciImage: _ciImage!,
        rifImage: _rifImage!,
        ocrCiData: _ocrCiData,
        ocrRifData: _ocrRifData,
      );

      debugPrint('✅ KYC: Datos extraídos con Gemini: ${result['data']}');
      debugPrint(
          '📊 KYC: Comparación - CI coincide: ${result['comparison']?['ci_matched']}, RIF coincide: ${result['comparison']?['rif_matched']}');

      // Guardar datos finales (priorizando Gemini si no coinciden)
      final finalData = result['data'] as Map<String, dynamic>;
      final ciData = finalData['ci'] as Map<String, dynamic>?;
      final rifData = finalData['rif'] as Map<String, dynamic>?;

      if (ciData != null) {
        await _storage.write(
          key: 'kyc_extracted_ci_data',
          value: jsonEncode(ciData),
        );
        debugPrint(
            '✅ KYC: Datos finales de CI guardados (fuente: ${result['source']})');
      }

      if (rifData != null) {
        await _storage.write(
          key: 'kyc_extracted_rif_data',
          value: jsonEncode(rifData),
        );
        debugPrint(
            '✅ KYC: Datos finales de RIF guardados (fuente: ${result['source']})');
      }

      // Guardar resultado de comparación IA vs OCR para usarlo en la validación de avance
      if (result['comparison'] != null) {
        _ciMatchedByIa = result['comparison']['ci_matched'] as bool?;
        _rifMatchedByIa = result['comparison']['rif_matched'] as bool?;

        // Mostrar mensaje si la IA detecta inconsistencias
        if (mounted &&
            ((_ciMatchedByIa == false) || (_rifMatchedByIa == false))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tus datos de CI o RIF no coinciden con lo detectado por la IA. '
                'Revisa que las fotos sean claras y correspondan a tus documentos.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      _geminiExtractionDone = true;
    } catch (e) {
      debugPrint('⚠️ KYC: Error extrayendo datos con Gemini: $e');
      // No mostrar error al usuario, usar datos del OCR como fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se pudo extraer datos con IA. Se usarán los datos del OCR.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingWithGemini = false;
        });
      }
    }
  }

  Future<bool> submitDocumentIfNeeded() async {
    if (_ciImage == null || _rifImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes tomar la foto de tu CI y tu RIF.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // Si aún se está procesando OCR o IA, pedir al usuario que espere
    if (_isProcessingOCR || _isExtractingWithGemini) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Estamos analizando tus documentos, espera unos segundos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // Validación ligera local: número de CI / RIF con formato venezolano
    if (_isCiValid == false || _isRifValid == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tus documentos no parecen una CI o RIF venezolanos válidos. '
            'Asegúrate de que se vean completos y legibles y vuelve a tomar las fotos.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // Si la extracción con IA (Gemini) se completó y detecta que CI/RIF no coinciden,
    // no permitir avanzar a la siguiente vista.
    if (_geminiExtractionDone &&
        ((_ciMatchedByIa == false) || (_rifMatchedByIa == false))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tus fotos de CI y RIF no pudieron ser validadas por la IA. '
            'Vuelve a tomar las fotos asegurándote de que sean claras y del documento correcto.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // En el flujo de onboarding solo validamos que existan y pasen la validación básica.
    // La subida real al backend se hará más adelante cuando el perfil exista.
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = isTablet ? 20.0 : 12.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - padding * 2,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header compacto
                        Text(
                          'Verificación de documentos',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fotografía tu CI y RIF',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solo aceptamos Cédula de Identidad venezolana y RIF emitidos en Venezuela.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Card única con CI y RIF (altura adaptada)
                        SizedBox(
                          height: isTablet ? 280 : 240,
                          child: _buildUnifiedDocumentCard(
                            context,
                            cardHeight: isTablet ? 280 : 240,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Indicador de procesamiento OCR (compacto)
                        if (_isProcessingOCR)
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
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
                                Expanded(
                                  child: Text(
                                    'Extrayendo datos...',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Indicador de subida (compacto)
                        Consumer<KycProvider>(
                          builder: (context, kyc, child) {
                            if (kyc.isUploading) {
                              return Container(
                                height: 36,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
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
                                    Expanded(
                                      child: Text(
                                        'Subiendo...',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        const SizedBox(height: 8),

                        // Instrucciones compactas
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Consejos:',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildTipItem(
                                context,
                                'Superficie plana y buena iluminación',
                                compact: true,
                              ),
                              _buildTipItem(
                                context,
                                'Sin sombras y datos legibles',
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnifiedDocumentCard(BuildContext context,
      {required double cardHeight}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card (ultra compacto)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Documentos requeridos',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Fotografía tu CI y RIF',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onBackground.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botones de captura CI y RIF lado a lado (sin cards internas)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: isTablet
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildCaptureButton(
                            context,
                            label: 'Cédula de Identidad',
                            image: _ciImage,
                            isCapturing: _isCapturing && _ciImage == null,
                            onCapture: () => _captureImage(isCI: true),
                            color: colorScheme.primary,
                            isCI: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCaptureButton(
                            context,
                            label: 'RIF',
                            image: _rifImage,
                            isCapturing: _isCapturing && _rifImage == null,
                            onCapture: () => _captureImage(isCI: false),
                            color: colorScheme.secondary,
                            isCI: false,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildCaptureButton(
                            context,
                            label: 'CI',
                            image: _ciImage,
                            isCapturing: _isCapturing && _ciImage == null,
                            onCapture: () => _captureImage(isCI: true),
                            color: colorScheme.primary,
                            isCI: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCaptureButton(
                            context,
                            label: 'RIF',
                            image: _rifImage,
                            isCapturing: _isCapturing && _rifImage == null,
                            onCapture: () => _captureImage(isCI: false),
                            color: colorScheme.secondary,
                            isCI: false,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton(
    BuildContext context, {
    required String label,
    required XFile? image,
    required bool isCapturing,
    required VoidCallback onCapture,
    required Color color,
    required bool isCI,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AspectRatio(
      aspectRatio: 1.0,
      child: image == null
          ? InkWell(
              onTap: isCapturing ? null : onCapture,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: isCapturing
                    ? Center(
                        child: CircularProgressIndicator(
                          color: color,
                          strokeWidth: 2,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 32,
                            color: color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onBackground,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tocar para capturar',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isCI) {
                            _ciImage = null;
                          } else {
                            _rifImage = null;
                          }
                        });
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
                // Badge de completado (diseñado para reflejar validación básica del documento)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (() {
                        final isValidDoc =
                            isCI ? (_isCiValid ?? true) : (_isRifValid ?? true);
                        if (isValidDoc) {
                          return colorScheme.primaryContainer;
                        }
                        return colorScheme.error.withOpacity(0.9);
                      })(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.onPrimaryContainer,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (() {
                                final isValidDoc = isCI
                                    ? (_isCiValid ?? true)
                                    : (_isRifValid ?? true);
                                return isValidDoc
                                    ? 'Foto capturada'
                                    : 'Documento no reconocido';
                              })(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              (() {
                                final isValidDoc = isCI
                                    ? (_isCiValid ?? true)
                                    : (_isRifValid ?? true);
                                if (isValidDoc) {
                                  return isCI
                                      ? 'CI venezolana (formato válido)'
                                      : 'RIF venezolano (formato válido)';
                                }
                                return isCI
                                    ? 'Revisa que sea una Cédula venezolana legible'
                                    : 'Revisa que sea un RIF venezolano legible';
                              })(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withOpacity(0.9),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text,
      {bool compact = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: compact ? 4 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: compact ? 12 : 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: compact ? 11 : 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja solo las esquinas del marco de la CI para que se vea más limpio sobre la cámara
class _CiFramePainter extends CustomPainter {
  final Color color;

  _CiFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 34.0;
    const strokeWidth = 4.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth,
      strokeWidth,
      size.width - strokeWidth * 2,
      size.height - strokeWidth * 2,
    );

    // Esquinas
    // Superior izquierda
    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(cornerLength, 0), paint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(0, cornerLength), paint);

    // Superior derecha
    canvas.drawLine(
        rect.topRight, rect.topRight + const Offset(-cornerLength, 0), paint);
    canvas.drawLine(
        rect.topRight, rect.topRight + const Offset(0, cornerLength), paint);

    // Inferior izquierda
    canvas.drawLine(rect.bottomLeft,
        rect.bottomLeft + const Offset(cornerLength, 0), paint);
    canvas.drawLine(rect.bottomLeft,
        rect.bottomLeft + const Offset(0, -cornerLength), paint);

    // Inferior derecha
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight + const Offset(-cornerLength, 0), paint);
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight + const Offset(0, -cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant _CiFramePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Pantalla dedicada para captura de la Cédula de Identidad con marco guía
class _CiCameraCapturePage extends StatefulWidget {
  const _CiCameraCapturePage();

  @override
  State<_CiCameraCapturePage> createState() => _CiCameraCapturePageState();
}

class _CiCameraCapturePageState extends State<_CiCameraCapturePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted || cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = controller.initialize();
      setState(() {
        _controller = controller;
      });
    } catch (e) {
      debugPrint('Error inicializando cámara CI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo acceder a la cámara.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    final initFuture = _initializeControllerFuture;
    if (controller == null || initFuture == null) return;

    try {
      await initFuture;
      final image = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop<XFile>(image);
    } catch (e) {
      debugPrint('Error tomando foto CI: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo tomar la foto de la CI.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Capturar Cédula de Identidad',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _controller == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                return Stack(
                  children: [
                    // Preview de la cámara ocupando la pantalla sin distorsión
                    Positioned.fill(
                      child: Center(
                        child: _CameraPreviewFitted(controller: _controller!),
                      ),
                    ),
                    // Rectángulo guía (horizontal) con overlay fuera del recuadro
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final height = constraints.maxHeight;

                          // Relación vertical similar a la cédula (un poco más ancha para dar margen)
                          final rectWidth = width * 0.68;
                          final rectHeight = rectWidth * 1.55;
                          final top = (height - rectHeight) / 2 - 4;
                          final left = (width - rectWidth) / 2;

                          return Stack(
                            children: [
                              Positioned(
                                left: left,
                                top: top,
                                width: rectWidth,
                                height: rectHeight,
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _CiFramePainter(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              // Texto de ayuda
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 140,
                                child: Text(
                                  'Coloca tu Cédula dentro del recuadro',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Botón de captura
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 32,
                      child: Center(
                        child: GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Pantalla dedicada para captura del RIF con marco guía horizontal
class _RifCameraCapturePage extends StatefulWidget {
  const _RifCameraCapturePage();

  @override
  State<_RifCameraCapturePage> createState() => _RifCameraCapturePageState();
}

class _RifCameraCapturePageState extends State<_RifCameraCapturePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted || cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = controller.initialize();
      setState(() {
        _controller = controller;
      });
    } catch (e) {
      debugPrint('Error inicializando cámara RIF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo acceder a la cámara.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    final initFuture = _initializeControllerFuture;
    if (controller == null || initFuture == null) return;

    try {
      await initFuture;
      final image = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop<XFile>(image);
    } catch (e) {
      debugPrint('Error tomando foto RIF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo tomar la foto del RIF.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Capturar RIF',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _controller == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                return Stack(
                  children: [
                    // Preview de la cámara ocupando la pantalla sin distorsión
                    Positioned.fill(
                      child: Center(
                        child: _CameraPreviewFitted(controller: _controller!),
                      ),
                    ),
                    // Rectángulo guía horizontal para el RIF
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final height = constraints.maxHeight;

                          // Marco vertical para el RIF (más alto que ancho, similar a la CI)
                          final rectWidth = width * 0.68;
                          final rectHeight = rectWidth * 1.55;
                          final top = (height - rectHeight) / 2 - 4;
                          final left = (width - rectWidth) / 2;

                          return Stack(
                            children: [
                              Positioned(
                                left: left,
                                top: top,
                                width: rectWidth,
                                height: rectHeight,
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _CiFramePainter(
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 140,
                                child: Text(
                                  'Coloca tu RIF dentro del recuadro',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Botón de captura
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 32,
                      child: Center(
                        child: GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Envuelve el CameraPreview en un FittedBox para evitar distorsión
class _CameraPreviewFitted extends StatelessWidget {
  final CameraController controller;

  const _CameraPreviewFitted({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;

    if (size == null) {
      return CameraPreview(controller);
    }

    // previewSize viene en orientación landscape (width > height),
    // por eso se invierten para portrait.
    final previewWidth = size.height;
    final previewHeight = size.width;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewWidth,
        height: previewHeight,
        child: CameraPreview(controller),
      ),
    );
  }
}
