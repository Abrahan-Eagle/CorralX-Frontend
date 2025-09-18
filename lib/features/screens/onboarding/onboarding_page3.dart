import 'package:flutter/material.dart';
import '../../../core/theme/corral_x_theme.dart';
import '../../../core/widgets/amazon_widgets.dart';

class OnboardingPage3 extends StatefulWidget {
  const OnboardingPage3({super.key});

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3>
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
                              Icons.add_business,
                              color: CorralXTheme.primarySolid,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Publica tu Ganado',
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
                          'Vende de forma profesional',
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
                          'Herramientas de Publicación',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea publicaciones detalladas y profesionales',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Crea publicaciones detalladas con fotos, información completa y precios competitivos. Alcanza miles de compradores potenciales.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Herramientas disponibles
                        Row(
                          children: [
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
                                      Icons.photo_camera,
                                      color: CorralXTheme.secondarySolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fotos HD',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.secondarySolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '10+ Imágenes',
                                      style: TextStyle(
                                        color: CorralXTheme.secondarySolid,
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
                                      Icons.description,
                                      color: CorralXTheme.successSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Detalles',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.successSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Completo',
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
                                      Icons.trending_up,
                                      color: CorralXTheme.accentSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Alcance',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.accentSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Máximo',
                                      style: TextStyle(
                                        color: CorralXTheme.accentSolid,
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

                // Herramientas de publicación
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
                                'Herramientas de publicación',
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
                          title: 'Fotos Profesionales',
                          subtitle:
                              'Hasta 15 fotos de alta calidad por publicación',
                          icon: Icons.camera_alt,
                          trailing: 'HD',
                        ),
                        AmazonListItem(
                          title: 'Información Detallada',
                          subtitle: 'Edad, peso, raza, salud, pedigrí y más',
                          icon: Icons.info_outline,
                          trailing: 'Completo',
                        ),
                        AmazonListItem(
                          title: 'Alcance Masivo',
                          subtitle:
                              'Tu publicación llega a miles de compradores',
                          icon: Icons.visibility,
                          trailing: '10K+',
                        ),
                        AmazonListItem(
                          title: 'Gestión Fácil',
                          subtitle:
                              'Edita, actualiza y gestiona tus publicaciones',
                          icon: Icons.edit,
                          trailing: 'Simple',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Vendedores exitosos
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
                          'Vendedores Exitosos',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Casos de éxito de nuestros vendedores',
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
                                title: 'Finca Los Pinos',
                                description: 'Vendió 50 cabezas en 30 días',
                                price: '\$125,000',
                                rating: '4.9',
                                reviews: 'Vendido',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.check_circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Rancho El Sol',
                                description: '50 toros reproductores vendidos',
                                price: '\$250,000',
                                rating: '4.8',
                                reviews: 'Vendido',
                                accentColor: CorralXTheme.secondarySolid,
                                icon: Icons.check_circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AmazonFeature(
                                title: 'Hacienda Verde',
                                description: '100 novillas vendidas este mes',
                                price: '\$180,000',
                                rating: '4.9',
                                reviews: 'Vendido',
                                accentColor: CorralXTheme.accentSolid,
                                icon: Icons.check_circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Granja San José',
                                description: 'Especialistas en Holstein',
                                price: '\$95,000',
                                rating: '4.7',
                                reviews: 'Vendido',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.check_circle,
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
                          ? CorralXTheme.accentSolid.withOpacity(0.1)
                          : CorralXTheme.accentSolid.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: CorralXTheme.accentSolid.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          size: 16,
                          color: CorralXTheme.accentSolid,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vendedores activos generan \$2.5M mensuales en ventas',
                            style: TextStyle(
                              color: CorralXTheme.accentSolid,
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
