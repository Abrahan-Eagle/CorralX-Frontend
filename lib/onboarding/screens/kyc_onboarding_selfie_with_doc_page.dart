import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:corralx/kyc/providers/kyc_provider.dart';

/// Página para capturar selfie sosteniendo el documento de identidad.
class KycOnboardingSelfieWithDocPage extends StatefulWidget {
  const KycOnboardingSelfieWithDocPage({super.key});

  @override
  State<KycOnboardingSelfieWithDocPage> createState() =>
      _KycOnboardingSelfieWithDocPageState();
}

class _KycOnboardingSelfieWithDocPageState
    extends State<KycOnboardingSelfieWithDocPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selfieWithDoc;
  bool _isCapturing = false;

  Future<void> _takeSelfieWithDoc() async {
    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        setState(() {
          _selfieWithDoc = image;
        });
      }
    } catch (e) {
      debugPrint('Error capturando selfie con documento: $e');
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

  Future<bool> submitSelfieWithDocIfNeeded() async {
    if (_selfieWithDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes tomar una selfie sosteniendo tu CI para continuar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    final kycProvider = Provider.of<KycProvider>(context, listen: false);
    final success = await kycProvider.submitSelfieWithDoc(_selfieWithDoc!);

    if (!success && mounted) {
      final error = kycProvider.errorMessage ??
          'No se pudo enviar la selfie con documento. Intenta nuevamente.';
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Selfie con documento',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sostén tu Cédula de Identidad junto a tu rostro y toma una foto. '
                'Asegúrate de que tanto tu cara como el documento sean claramente visibles.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),

              // Preview card - más compacta
              Center(
                child: Container(
                  width: isTablet ? 350 : 280, // Reducido de 400/∞ a 350/280
                  constraints: const BoxConstraints(maxWidth: 350),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16), // Reducido de 20 a 16
                    border: Border.all(
                      color: _selfieWithDoc != null
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.3),
                      width: _selfieWithDoc != null ? 2 : 1,
                    ),
                    boxShadow: _selfieWithDoc != null
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Agregado para hacer más compacto
                    children: [
                      // Preview area - más compacta
                      AspectRatio(
                        aspectRatio: 1.0, // Cambiado de 3/4 a 1:1 (más compacto)
                        child: _selfieWithDoc == null
                            ? InkWell(
                                onTap: _isCapturing ? null : _takeSelfieWithDoc,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant
                                        .withOpacity(0.3),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: _isCapturing
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: colorScheme.primary,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.badge_outlined,
                                              size: isTablet ? 80 : 64,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Tocar para capturar',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    child: Image.file(
                                      File(_selfieWithDoc!.path),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Material(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selfieWithDoc = null;
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
                                  if (_selfieWithDoc != null)
                                    Positioned(
                                      bottom: 12,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green[300],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Foto capturada',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),

                      // Instructions - más compactas
                      Padding(
                        padding: const EdgeInsets.all(12), // Reducido de 20 a 12
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16, // Reducido de 20 a 16
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6), // Reducido de 8 a 6
                                Expanded(
                                  child: Text(
                                    'Sostén tu CI junto a tu rostro. Ambos deben ser visibles.',
                                    style: theme.textTheme.bodySmall?.copyWith( // Cambiado de bodyMedium a bodySmall
                                      color: colorScheme.onSurfaceVariant,
                                    ),
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

              const SizedBox(height: 24),

              // Upload indicator
              Consumer<KycProvider>(
                builder: (context, kyc, child) {
                  if (kyc.isUploading) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Subiendo foto...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}
