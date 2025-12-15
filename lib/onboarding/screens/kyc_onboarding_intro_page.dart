import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:corralx/kyc/providers/kyc_provider.dart';

/// Página introductoria al flujo KYC dentro del onboarding.
class KycOnboardingIntroPage extends StatefulWidget {
  const KycOnboardingIntroPage({super.key});

  @override
  State<KycOnboardingIntroPage> createState() => _KycOnboardingIntroPageState();
}

class _KycOnboardingIntroPageState extends State<KycOnboardingIntroPage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Cargar estado KYC después del primer frame para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialized) {
        _initialized = true;
        final kycProvider = Provider.of<KycProvider>(context, listen: false);
        kycProvider.loadStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verificación de identidad',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Para publicar productos en CorralX necesitamos confirmar tu identidad '
                'con tu cédula venezolana y una selfie. Es un proceso rápido y 100% automático.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              _buildStep(
                context,
                index: 2,
                title: 'Selfie',
                description:
                    'Luego haremos una foto de tu rostro para confirmar que eres tú.',
              ),
              const SizedBox(height: 16),
              _buildStep(
                context,
                index: 1,
                title: 'Documento de identidad',
                description:
                    'Tomaremos una foto frontal de tu cédula venezolana (CI). Opcionalmente podrás añadir el dorso.',
              ),
              const SizedBox(height: 16),
              _buildStep(
                context,
                index: 3,
                title: 'Selfie con documento',
                description:
                    'Por último, una selfie sosteniendo tu cédula para vincular persona y documento.',
              ),
              const SizedBox(height: 32),
              Consumer<KycProvider>(
                builder: (context, kyc, child) {
                  if (kyc.isLoading) {
                    return Row(
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
                            'Comprobando tu estado de verificación...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  String statusText;
                  Color statusColor;

                  switch (kyc.kycStatus) {
                    case 'verified':
                      statusText = 'Tu identidad ya está verificada.';
                      statusColor = Colors.green;
                      break;
                    case 'pending':
                      statusText =
                          'Tu verificación está en revisión automática. Puedes continuar.';
                      statusColor = Colors.orange;
                      break;
                    case 'rejected':
                      statusText =
                          'Tu verificación anterior fue rechazada. Volveremos a intentar el proceso.';
                      statusColor = colorScheme.error;
                      break;
                    default:
                      statusText =
                          'Aún no has completado la verificación de identidad.';
                      statusColor = colorScheme.onBackground.withOpacity(0.8);
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 22,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Tus datos se usan solo para seguridad y cumplimiento legal en CorralX. '
                'No compartimos tu información con terceros sin tu consentimiento.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int index,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


