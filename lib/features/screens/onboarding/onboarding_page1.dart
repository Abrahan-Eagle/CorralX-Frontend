import 'package:flutter/material.dart';
import '../../../core/theme/corral_x_theme.dart';
import '../../../core/widgets/amazon_widgets.dart';

class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({super.key});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1>
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

                // Header con título y estadísticas
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
                              Icons.store,
                              color: CorralXTheme.primarySolid,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'El Mercado Ganadero',
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
                          'Descubre el mejor ganado disponible',
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
                          'Explora miles de publicaciones',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Todo tipo de ganado en un solo lugar',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Desde novillas hasta toros reproductores, encuentra exactamente lo que necesitas',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tipos de ganado disponibles
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
                                      Icons.pets,
                                      color: CorralXTheme.successSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bovinos',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.successSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '1,200+',
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
                                      Icons.agriculture,
                                      color: CorralXTheme.secondarySolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Porcinos',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.secondarySolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '800+',
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
                                      Icons.grass,
                                      color: CorralXTheme.accentSolid,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Caprinos',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CorralXTheme.accentSolid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '600+',
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

                // Características del mercado
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
                                'Características del mercado',
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
                          title: 'Amplia Variedad',
                          subtitle:
                              'Más de 15 razas diferentes de ganado disponible',
                          icon: Icons.category,
                          trailing: '15+ Razas',
                        ),
                        AmazonListItem(
                          title: 'Fácil Navegación',
                          subtitle: 'Interfaz intuitiva con filtros avanzados',
                          icon: Icons.search,
                          trailing: 'Filtros',
                        ),
                        AmazonListItem(
                          title: 'Información Detallada',
                          subtitle:
                              'Datos completos de cada animal: edad, peso, salud',
                          icon: Icons.info,
                          trailing: 'Completo',
                        ),
                        AmazonListItem(
                          title: 'Precios Competitivos',
                          subtitle:
                              'Compara precios entre diferentes vendedores',
                          icon: Icons.attach_money,
                          trailing: 'Competitivo',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Vendedores destacados
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
                          'Vendedores Destacados',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los más confiables del mercado',
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
                                description: 'Especialistas en ganado Holstein',
                                price: 'Desde \$2,500',
                                rating: '4.9',
                                reviews: '156',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.star,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Rancho El Toro',
                                description: 'Toros reproductores de calidad',
                                price: 'Desde \$5,000',
                                rating: '4.8',
                                reviews: '89',
                                accentColor: CorralXTheme.secondarySolid,
                                icon: Icons.star,
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
                                description: 'Novillas jóvenes certificadas',
                                price: 'Desde \$1,800',
                                rating: '4.7',
                                reviews: '203',
                                accentColor: CorralXTheme.accentSolid,
                                icon: Icons.star,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AmazonFeature(
                                title: 'Hacienda Verde',
                                description: 'Ganado orgánico certificado',
                                price: 'Desde \$3,200',
                                rating: '4.9',
                                reviews: '124',
                                accentColor: CorralXTheme.successSolid,
                                icon: Icons.star,
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
                          ? CorralXTheme.neutralSolid.withOpacity(0.1)
                          : CorralXTheme.neutralSolid.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: CorralXTheme.neutralSolid.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: CorralXTheme.neutralSolid,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Más de 5,000 transacciones exitosas este mes',
                            style: TextStyle(
                              color: CorralXTheme.neutralSolid,
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
