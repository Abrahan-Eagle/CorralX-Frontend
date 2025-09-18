import 'package:flutter/material.dart';
import '../../../core/theme/corral_x_theme.dart';
import '../../../core/widgets/amazon_widgets.dart';

class OnboardingPage6 extends StatefulWidget {
  const OnboardingPage6({super.key});

  @override
  State<OnboardingPage6> createState() => _OnboardingPage6State();
}

class _OnboardingPage6State extends State<OnboardingPage6>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _mainController.forward();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header con título
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: CorralXTheme.primarySolid,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tu Perfil',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: CorralXTheme.primarySolid,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Construye tu reputación',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Información principal
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfil Profesional',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea confianza con tu perfil completo',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Crea un perfil profesional que genere confianza. Completa tu información, verifica tu identidad y construye tu reputación en la plataforma.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Características del perfil
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: CorralXTheme.successSolid
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: CorralXTheme.successSolid
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: CorralXTheme.successSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Verificación',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.successSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'ID Verificada',
                                      style: TextStyle(
                                        color: CorralXTheme.successSolid,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      CorralXTheme.accentSolid.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: CorralXTheme.accentSolid
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: CorralXTheme.accentSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Reputación',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.accentSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '5 Estrellas',
                                      style: TextStyle(
                                        color: CorralXTheme.accentSolid,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: CorralXTheme.secondarySolid
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: CorralXTheme.secondarySolid
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      color: CorralXTheme.secondarySolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Empresa',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.secondarySolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Profesional',
                                      style: TextStyle(
                                        color: CorralXTheme.secondarySolid,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Características del perfil
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.02)
                                : Colors.grey.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Características del perfil',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AmazonListItem(
                          title: 'Verificación de Identidad',
                          subtitle:
                              'Verifica tu identidad con documentos oficiales',
                          icon: Icons.verified_user,
                          trailing: 'Certificado',
                        ),
                        AmazonListItem(
                          title: 'Sistema de Calificaciones',
                          subtitle:
                              'Construye reputación con calificaciones confiables',
                          icon: Icons.star_rate,
                          trailing: '5★',
                        ),
                        AmazonListItem(
                          title: 'Perfil de Empresa',
                          subtitle: 'Muestra tu empresa de forma profesional',
                          icon: Icons.business_center,
                          trailing: 'Pro',
                        ),
                        AmazonListItem(
                          title: 'Historial de Transacciones',
                          subtitle: 'Muestra tu historial exitoso de ventas',
                          icon: Icons.history,
                          trailing: 'Completo',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Perfiles destacados
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfiles Destacados',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ejemplos de perfiles exitosos',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AmazonFeature(
                                title: 'Finca San José',
                                description: 'Vendedor verificado 5★',
                                price: '500+ Ventas',
                                rating: '4.9',
                                reviews: 'Verificado',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.verified,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Rancho El Toro',
                                description: 'Empresa certificada',
                                price: '300+ Ventas',
                                rating: '4.8',
                                reviews: 'Empresa',
                                accentColor: CorralXTheme.secondarySolid,
                                icon: Icons.business,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AmazonFeature(
                                title: 'Granja Los Andes',
                                description: 'Perfil completo 100%',
                                price: '250+ Ventas',
                                rating: '4.7',
                                reviews: 'Completo',
                                accentColor: CorralXTheme.accentSolid,
                                icon: Icons.check_circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Hacienda Verde',
                                description: 'Especialista en orgánicos',
                                price: '180+ Ventas',
                                rating: '4.9',
                                reviews: 'Especialista',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.eco,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Información adicional
                AmazonFadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CorralXTheme.successSolid.withOpacity(0.1)
                          : CorralXTheme.successSolid.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: CorralXTheme.successSolid.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 16,
                          color: CorralXTheme.successSolid,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Perfiles verificados tienen 3x más probabilidades de cerrar ventas',
                            style: TextStyle(
                              color: CorralXTheme.successSolid,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
